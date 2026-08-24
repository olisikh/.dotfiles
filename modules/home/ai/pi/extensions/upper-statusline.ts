// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
	ToolExecutionStartEvent,
} from "@mariozechner/pi-coding-agent";
// @ts-ignore Pi provides this module at runtime.
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import {
	PI_EXTENSION_ENTRIES,
	PI_EXTENSION_EVENTS,
	PI_RUNTIME_SYMBOLS,
	PI_STATUS_KEYS,
	PI_VIM_MODES,
	PI_WIDGET_KEYS,
	PI_WIDGET_PLACEMENTS,
} from "./lib/pi-constants.ts";
import type {
	PiInverseTheme,
	PiItalicTheme,
	PiTextTheme,
	PiTheme,
	PiThemeColor,
} from "./lib/pi-theme.ts";
import { PI_THEME_COLORS } from "./lib/pi-theme.ts";
import type {
	PiWidgetFactory,
	PiWidgetOptions,
	PiWidgetUi,
} from "./lib/pi-widgets.ts";

const WIDGET_KEY = PI_WIDGET_KEYS.upperStatusline;
const UPPER_STATUS_EVENT = PI_EXTENSION_EVENTS.upperStatusChanged;
const YOLO_STATE_KEY = PI_RUNTIME_SYMBOLS.yoloState;
const GAP_WIDTH = 2;
const MAX_RECENT_MCPS = 3;
const MCP_HISTORY_ENTRY = PI_EXTENSION_ENTRIES.upperStatusMcpHistory;

type StatusState = {
	vimMode: string;
	yoloEnabled: boolean;
	recentMcps: string[];
};

type UpperStatusEvent =
	| { version: 1; source: "vim"; mode: string }
	| { version: 1; source: typeof PI_STATUS_KEYS.yolo; enabled: boolean };

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function isBelowEditor(options: PiWidgetOptions): boolean {
	return options?.placement === PI_WIDGET_PLACEMENTS.belowEditor;
}

function isYoloModeEnabled(): boolean {
	const runtime = globalThis as typeof globalThis & Record<symbol, unknown>;
	const state = runtime[YOLO_STATE_KEY] as { enabled?: unknown } | undefined;
	return state?.enabled === true;
}

function isUpperStatusEvent(value: unknown): value is UpperStatusEvent {
	if (!isRecord(value) || value.version !== 1) return false;
	if (value.source === PI_STATUS_KEYS.yolo) {
		return typeof value.enabled === "boolean";
	}
	return (
		value.source === "vim" &&
		typeof value.mode === "string" &&
		value.mode.length > 0 &&
		value.mode.length <= 32
	);
}

function mcpServerName(
	event: Pick<ToolExecutionStartEvent, "toolName" | "args">,
): string | undefined {
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

function renderLine(state: StatusState, theme: PiTheme, width: number): string {
	const left = [
		badge(theme, vimColor(state.vimMode), state.vimMode.toUpperCase(), true),
		...(state.yoloEnabled
			? [badge(theme, PI_THEME_COLORS.error, "YOLO", true)]
			: []),
	].join(theme.fg(PI_THEME_COLORS.dim, " · "));
	const servers = state.recentMcps;
	if (servers.length === 0) return truncateToWidth(left, width);

	const fullRight = badge(theme, PI_THEME_COLORS.mdLink, servers.join(" · "));
	const compactRight = badge(
		theme,
		PI_THEME_COLORS.mdLink,
		servers.length.toString(),
	);
	for (const right of [fullRight, compactRight]) {
		const remaining = width - visibleWidth(left) - GAP_WIDTH;
		if (remaining >= visibleWidth(right)) {
			return `${left}${" ".repeat(remaining + GAP_WIDTH - visibleWidth(right))}${right}`;
		}
	}
	return truncateToWidth(left, width);
}

function badge(
	theme: PiInverseTheme & PiItalicTheme & PiTextTheme,
	color: PiThemeColor,
	text: string,
	bold: boolean = false,
	italic: boolean = false,
): string {
	if (bold) text = theme.bold(text);
	if (italic) text = theme.italic(text);

	return theme.inverse(theme.fg(color, ` ${text} `));
}

function vimColor(mode: string): PiThemeColor {
	switch (mode) {
		case PI_VIM_MODES.insert:
			return PI_THEME_COLORS.success;
		case PI_VIM_MODES.normal:
			return PI_THEME_COLORS.mdLink;
		case PI_VIM_MODES.visual:
		case PI_VIM_MODES.visualLine:
			return PI_THEME_COLORS.accent;
		case PI_VIM_MODES.ex:
			return PI_THEME_COLORS.warning;
		default:
			return PI_THEME_COLORS.muted;
	}
}

export default function (pi: ExtensionAPI): void {
	const state: StatusState = {
		vimMode: PI_VIM_MODES.insert,
		yoloEnabled: isYoloModeEnabled(),
		recentMcps: [],
	};
	let requestRender: (() => void) | undefined;
	let activeContext: ExtensionContext | undefined;
	let restoreWidgetSetter: (() => void) | undefined;

	const widgetFactory: PiWidgetFactory = (tui, theme) => {
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

	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		restoreWidgetSetter?.();
		restoreWidgetSetter = undefined;
		activeContext = ctx;
		state.vimMode = PI_VIM_MODES.insert;
		state.yoloEnabled = isYoloModeEnabled();
		state.recentMcps = restoreMcpHistory(ctx);

		// SAFETY: Pi exposes setWidget as a mutable UI method; this narrower shape
		// only models the callback and placement arguments used by this wrapper.
		const ui = ctx.ui as PiWidgetUi;
		const previousSetWidget = ui.setWidget;
		const setWidget = previousSetWidget.bind(ui);
		let reordering = false;
		const installLast = () => setWidget(WIDGET_KEY, widgetFactory);
		const proxySetWidget: PiWidgetUi["setWidget"] = (key, widget, options) => {
			setWidget(key, widget, options);
			if (reordering || key === WIDGET_KEY || isBelowEditor(options)) return;

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

	pi.on("tool_execution_start", (event: ToolExecutionStartEvent) => {
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
