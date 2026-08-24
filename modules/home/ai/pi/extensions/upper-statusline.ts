import type {
	ExtensionAPI,
	ExtensionContext,
	// @ts-expect-error Pi provides this module to extensions at runtime.
} from "@mariozechner/pi-coding-agent";
/* @ts-expect-error Pi provides this module to extensions at runtime. */
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
const WIDGET_KEY = "zz-olisikh-upper-statusline";
const UPPER_STATUS_EVENT = "olisikh:upper-status-changed";
const YOLO_STATE_KEY = Symbol.for("olisikh.pi.yolo-state");
const GAP_WIDTH = 2;
const MAX_RECENT_MCPS = 3;
const MCP_HISTORY_ENTRY = "olisikh:upper-status-mcps";

type WidgetTui = { requestRender(): void };
type WidgetTheme = { fg(color: string, text: string): string };
type WidgetFactory = (tui: WidgetTui, theme: WidgetTheme) => unknown;
type WidgetUi = {
	setWidget: (key: string, widget: unknown, ...options: unknown[]) => void;
};
type ToolEvent = {
	toolCallId?: string;
	toolName?: string;
	args?: unknown;
	result?: unknown;
};

type StatusState = {
	vimMode: string;
	yoloEnabled: boolean;
	recentMcps: string[];
};

type UpperStatusEvent =
	| { version: 1; source: "vim"; mode: string }
	| { version: 1; source: "yolo"; enabled: boolean };

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function isBelowEditor(options: unknown): boolean {
	return isRecord(options) && options.placement === "belowEditor";
}

function isYoloModeEnabled(): boolean {
	const runtime = globalThis as typeof globalThis & Record<symbol, unknown>;
	const state = runtime[YOLO_STATE_KEY] as { enabled?: unknown } | undefined;
	return state?.enabled === true;
}

function isUpperStatusEvent(value: unknown): value is UpperStatusEvent {
	if (!isRecord(value) || value.version !== 1) return false;
	if (value.source === "yolo") return typeof value.enabled === "boolean";
	return (
		value.source === "vim" &&
		typeof value.mode === "string" &&
		value.mode.length > 0 &&
		value.mode.length <= 32
	);
}

function mcpServerName(event: ToolEvent): string | undefined {
	if (typeof event.toolName !== "string") return undefined;
	const toolName = event.toolName.trim();
	const direct = serverFromQualifiedTool(toolName);
	if (direct) return direct;
	if (toolName !== "mcp" || !isRecord(event.args)) return undefined;

	if (typeof event.args.server === "string" && event.args.server.trim()) {
		return event.args.server.trim();
	}
	if (typeof event.args.tool === "string") {
		return serverFromQualifiedTool(event.args.tool.trim());
	}
	return undefined;
}

function serverFromQualifiedTool(toolName: string): string | undefined {
	if (!toolName.startsWith("mcp__")) return undefined;
	const qualified = toolName.slice("mcp__".length);
	const separator = qualified.indexOf("_");
	return (
		(separator > 0 ? qualified.slice(0, separator) : qualified) || undefined
	);
}

function normalizedMcpHistory(value: unknown): string[] {
	if (!Array.isArray(value)) return [];

	return value
		.filter((name): name is string => typeof name === "string" && name.length > 0)
		.filter((name, index, names) => names.lastIndexOf(name) === index)
		.slice(-MAX_RECENT_MCPS);
}

function restoreMcpHistory(ctx: ExtensionContext): string[] {
	const entries = ctx.sessionManager.getEntries();
	for (let index = entries.length - 1; index >= 0; index -= 1) {
		const entry = entries[index];
		if (
			entry.type === "custom" &&
			entry.customType === MCP_HISTORY_ENTRY &&
			isRecord(entry.data)
		) {
			return normalizedMcpHistory(entry.data.recentMcps);
		}
	}
	return [];
}

function rememberMcp(state: StatusState, server: string): void {
	state.recentMcps = normalizedMcpHistory([
		...state.recentMcps.filter((name) => name !== server),
		server,
	]);
}

function renderLine(
	state: StatusState,
	theme: WidgetTheme,
	width: number,
): string {
	const left = [
		badge(theme, vimColor(state.vimMode), state.vimMode.toUpperCase()),
		...(state.yoloEnabled ? [badge(theme, "error", "YOLO")] : []),
	].join(theme.fg("dim", " · "));
	const servers = state.recentMcps;
	if (servers.length === 0) return truncateToWidth(left, width);

	const fullRight = badge(theme, "mdLink", `MCP: ${servers.join(" · ")}`);
	const compactRight = badge(theme, "mdLink", `MCP: ${servers.length}`);
	for (const right of [fullRight, compactRight]) {
		const remaining = width - visibleWidth(left) - GAP_WIDTH;
		if (remaining >= visibleWidth(right)) {
			return `${left}${" ".repeat(remaining + GAP_WIDTH - visibleWidth(right))}${right}`;
		}
	}
	return truncateToWidth(left, width);
}

function badge(theme: WidgetTheme, color: string, text: string): string {
	return `\x1b[7m${theme.fg(color, ` ${text} `)}\x1b[27m`;
}

function vimColor(mode: string): string {
	switch (mode) {
		case "insert":
			return "success";
		case "normal":
			return "accent";
		case "visual":
		case "visual-line":
			return "mdLink";
		case "ex":
			return "warning";
		default:
			return "muted";
	}
}

export default function (pi: ExtensionAPI): void {
	const state: StatusState = {
		vimMode: "insert",
		yoloEnabled: isYoloModeEnabled(),
		recentMcps: [],
	};
	let requestRender: (() => void) | undefined;
	let activeContext: ExtensionContext | undefined;
	let restoreWidgetSetter: (() => void) | undefined;

	const widgetFactory: WidgetFactory = (tui, theme) => {
		requestRender = () => tui.requestRender();
		return {
			invalidate() {},
			render: (width: number) => [renderLine(state, theme, width)],
		};
	};
	const refresh = () => requestRender?.();
	const stopWatchingStatus = pi.events.on(
		UPPER_STATUS_EVENT,
		(value: unknown) => {
			if (!isUpperStatusEvent(value)) return;
			applyStatusEvent(state, value);
			refresh();
		},
	);

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		restoreWidgetSetter?.();
		restoreWidgetSetter = undefined;
		activeContext = ctx;
		state.vimMode = "insert";
		state.yoloEnabled = isYoloModeEnabled();
		state.recentMcps = restoreMcpHistory(ctx);

		// SAFETY: Pi exposes setWidget as a mutable UI method; this narrower shape
		// only models the callback and placement arguments used by this wrapper.
		const ui = ctx.ui as unknown as WidgetUi;
		const previousSetWidget = ui.setWidget;
		const setWidget = previousSetWidget.bind(ui);
		let reordering = false;
		const installLast = () => setWidget(WIDGET_KEY, widgetFactory);
		const proxySetWidget: WidgetUi["setWidget"] = (key, widget, ...options) => {
			setWidget(key, widget, ...options);
			if (reordering || key === WIDGET_KEY || isBelowEditor(options[0])) return;

			// Pi renders above-editor widgets in registration order. Reinsert this
			// widget after every other above-editor update so it remains adjacent to
			// the editor even when the plan widget refreshes its todos.
			reordering = true;
			try {
				setWidget(WIDGET_KEY, undefined);
				installLast();
			} finally {
				reordering = false;
			}
		};
		ui.setWidget = proxySetWidget;
		restoreWidgetSetter = () => {
			if (ui.setWidget === proxySetWidget) ui.setWidget = previousSetWidget;
		};
		installLast();
	});

	pi.on("tool_execution_start", (event: ToolEvent) => {
		const server = mcpServerName(event);
		if (!server) return;
		rememberMcp(state, server);
		pi.appendEntry(MCP_HISTORY_ENTRY, { recentMcps: [...state.recentMcps] });
		refresh();
	});

	pi.on("session_shutdown", () => {
		activeContext?.ui.setWidget(WIDGET_KEY, undefined);
		restoreWidgetSetter?.();
		restoreWidgetSetter = undefined;
		activeContext = undefined;
		requestRender = undefined;
		stopWatchingStatus();
	});
}

function applyStatusEvent(state: StatusState, event: UpperStatusEvent): void {
	if (event.source === "vim") {
		state.vimMode = event.mode;
	} else {
		state.yoloEnabled = event.enabled;
	}
}
