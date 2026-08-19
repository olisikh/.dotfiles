import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
/* @ts-expect-error Pi provides this module to extensions at runtime. */
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import {
	isModeChangedEvent,
	type ModeChangedEvent,
	subscribeToModeChanges,
} from "./lib/mode-events.ts";
import {
	borderModeFor,
	mcpServerNameForTool,
	paintBorder,
} from "./lib/mode-border.ts";

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function getMcpServerName(event: unknown): string | undefined {
	if (!isRecord(event) || typeof event.toolName !== "string") return undefined;

	const directServer = mcpServerNameForTool(event.toolName.trim());
	if (directServer) return directServer;
	if (event.toolName !== "mcp") return undefined;

	if (isRecord(event.args) && typeof event.args.tool === "string") {
		if (typeof event.args.server === "string") return event.args.server.trim();
		const server = mcpServerNameForTool(event.args.tool.trim());
		if (server) return server;
	}

	return isRecord(event.result) &&
		isRecord(event.result.details) &&
		typeof event.result.details.server === "string"
		? event.result.details.server.trim()
		: undefined;
}

function fitBorder(
	left: string,
	right: string,
	width: number,
	border: (text: string) => string,
	fill: (text: string) => string = border,
): string {
	if (width <= 0) return "";
	if (width === 1) return border("─");

	let leftText = left;
	let rightText = right;
	const fixedWidth = 2;
	const minimumGap = 3;

	while (
		fixedWidth + visibleWidth(leftText) + visibleWidth(rightText) + minimumGap >
			width &&
		visibleWidth(rightText) > 0
	) {
		rightText = truncateToWidth(
			rightText,
			Math.max(0, visibleWidth(rightText) - 1),
			"",
		);
	}
	while (
		fixedWidth + visibleWidth(leftText) + visibleWidth(rightText) + minimumGap >
			width &&
		visibleWidth(leftText) > 0
	) {
		leftText = truncateToWidth(
			leftText,
			Math.max(0, visibleWidth(leftText) - 1),
			"",
		);
	}

	const gapWidth = Math.max(
		0,
		width - fixedWidth - visibleWidth(leftText) - visibleWidth(rightText),
	);
	return `${border("─")}${leftText}${fill("─".repeat(gapWidth))}${rightText}${border("─")}`;
}

type ActiveTui = {
	requestRender: () => void;
};

export {
	borderModeFor,
	paintBorder,
	type BorderMode,
} from "./lib/mode-border.ts";

export default function (pi: ExtensionAPI) {
	const modes = new Map<string, ModeChangedEvent>();
	const usedMcpServers = new Set<string>();
	let activeTui: ActiveTui | undefined;
	let editorComponentInstalled = false;
	let installTimer: ReturnType<typeof setTimeout> | undefined;

	const stopInstallTimer = () => {
		if (installTimer) clearTimeout(installTimer);
		installTimer = undefined;
	};

	const requestRender = () => activeTui?.requestRender();
	const rememberMcpServer = (event: unknown) => {
		const serverName = getMcpServerName(event);
		if (!serverName || usedMcpServers.has(serverName)) return;
		usedMcpServers.add(serverName);
		requestRender();
	};
	const stopWatchingModes = subscribeToModeChanges(pi, (event) => {
		if (!isModeChangedEvent(event)) return;
		modes.set(event.mode, event);
		requestRender();
	});

	pi.on("tool_execution_start", rememberMcpServer);
	pi.on("tool_execution_end", rememberMcpServer);

	const installModeBorder = (ctx: ExtensionContext) => {
		if (editorComponentInstalled || ctx.mode !== "tui" || !ctx.hasUI) return;
		const previousEditor = ctx.ui.getEditorComponent() as
			| ((tui: ActiveTui, theme: unknown, keybindings: unknown) => CustomEditor)
			| undefined;
		ctx.ui.setEditorComponent(
			(tui: ActiveTui, theme: unknown, keybindings: unknown) => {
				const editor = (previousEditor?.(tui, theme, keybindings) ??
					new CustomEditor(tui, theme, keybindings)) as CustomEditor;
				activeTui = tui;
				const applyBorderColor = () => {
					editor.borderColor = (text: string) =>
						paintBorder(borderModeFor(modes), text);
				};
				applyBorderColor();
				const render = editor.render.bind(editor);
				editor.render = (width: number) => {
					applyBorderColor();
					const lines = render(width);
					if (lines.length < 2 || usedMcpServers.size === 0) return lines;

					const label = editor.borderColor(` ${[...usedMcpServers].join(" · ")} `);
					lines.splice(0, 1, fitBorder("", label, width, editor.borderColor));
					return lines;
				};
				return editor;
			},
		);
		editorComponentInstalled = true;
	};

	const scheduleModeBorder = (ctx: ExtensionContext) => {
		stopInstallTimer();
		// ponytail: defer one tick so later-loaded editor extensions finish first; use explicit extension ordering if Pi adds it.
		installTimer = setTimeout(() => {
			installTimer = undefined;
			installModeBorder(ctx);
		}, 0);
	};

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		modes.clear();
		usedMcpServers.clear();
		activeTui = undefined;
		editorComponentInstalled = false;
		scheduleModeBorder(ctx);
	});

	pi.on("session_shutdown", () => {
		stopInstallTimer();
		activeTui = undefined;
		editorComponentInstalled = false;
		modes.clear();
		usedMcpServers.clear();
		stopWatchingModes();
	});
}
