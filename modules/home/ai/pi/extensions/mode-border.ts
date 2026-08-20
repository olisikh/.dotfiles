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
import { isYoloModeEnabled } from "./yolo-mode.ts";

const YOLO_RENDER_KEY = Symbol.for("olisikh.pi.yolo-render");
const BORDER_OFFSET = 2;

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
	const edgeWidth = Math.min(BORDER_OFFSET, Math.floor(width / 2));
	const fixedWidth = edgeWidth * 2;
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
	const edge = border("─".repeat(edgeWidth));
	return `${edge}${leftText}${fill("─".repeat(gapWidth))}${rightText}${edge}`;
}

function colorizeLabel(
	theme: { fg?: (color: string, text: string) => string } | null,
	token: string,
	fallback: (text: string) => string,
	text: string,
): string {
	if (theme && typeof theme.fg === "function") {
		try {
			return theme.fg(token, text);
		} catch {
			return fallback(text);
		}
	}
	return fallback(text);
}

type ActiveTui = {
	requestRender: () => void;
};

type EditorFactory = (
	tui: ActiveTui,
	theme: unknown,
	keybindings: unknown,
) => CustomEditor;

type BorderUiState = {
	originalSetEditorComponent: (factory: EditorFactory) => void;
	wrapFactory: (factory: EditorFactory | undefined) => EditorFactory;
	proxySetEditorComponent: (factory: EditorFactory) => void;
};

const MODE_BORDER_UI_KEY = Symbol.for("olisikh.pi.mode-border-ui");

export {
	borderModeFor,
	paintBorder,
	type BorderMode,
} from "./lib/mode-border.ts";

export default function (pi: ExtensionAPI) {
	const modes = new Map<string, ModeChangedEvent>();
	const usedMcpServers = new Set<string>();
	let activeTui: ActiveTui | undefined;
	let activeContext: ExtensionContext | undefined;
	const wrappedFactories = new WeakSet<object>();
	let installTimer: ReturnType<typeof setTimeout> | undefined;

	const stopInstallTimer = () => {
		if (installTimer) clearTimeout(installTimer);
		installTimer = undefined;
	};

	const requestRender = () => activeTui?.requestRender();
	const runtime = globalThis as typeof globalThis & Record<symbol, unknown>;
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
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		const appTheme = ctx.ui.theme as {
			fg?: (color: string, text: string) => string;
		} | null;
		const previousEditor = ctx.ui.getEditorComponent() as
			| EditorFactory
			| undefined;
		if (previousEditor && wrappedFactories.has(previousEditor)) return;

		const createModeBorderFactory = (
			baseEditor: EditorFactory | undefined,
		): EditorFactory => {
			const modeBorderFactory = (
				tui: ActiveTui,
				theme: unknown,
				keybindings: unknown,
			) => {
				const editor = (baseEditor?.(tui, theme, keybindings) ??
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
					if (lines.length < 2) return lines;

					const yoloLabel = isYoloModeEnabled()
						? `\x1b[1m${colorizeLabel(appTheme, "error", editor.borderColor, "\x1b[7m yolo \x1b[27m")}\x1b[22m`
						: "";
					const mcpLabel =
						usedMcpServers.size > 0
							? `\x1b[1m${colorizeLabel(appTheme, "mdLink", editor.borderColor, `\x1b[7m ${[...usedMcpServers].join(" · ")} \x1b[27m`)}\x1b[22m`
							: "";
					lines.splice(
						0,
						1,
						fitBorder(yoloLabel, mcpLabel, width, editor.borderColor),
					);
					return lines;
				};
				return editor;
			};

			wrappedFactories.add(modeBorderFactory);
			return modeBorderFactory;
		};

		const ui = ctx.ui as typeof ctx.ui & Record<symbol, unknown>;
		const wrapFactory = (factory: EditorFactory | undefined) =>
			factory && wrappedFactories.has(factory)
				? factory
				: createModeBorderFactory(factory);
		const existingUiState = ui[MODE_BORDER_UI_KEY] as BorderUiState | undefined;

		if (existingUiState) {
			existingUiState.wrapFactory = wrapFactory;
			existingUiState.originalSetEditorComponent(wrapFactory(previousEditor));
			return;
		}

		const originalSetEditorComponent = ctx.ui.setEditorComponent.bind(ctx.ui) as (
			factory: EditorFactory,
		) => void;
		const borderUiState: BorderUiState = {
			originalSetEditorComponent,
			wrapFactory,
			proxySetEditorComponent: (factory) => {
				const currentState = ui[MODE_BORDER_UI_KEY] as BorderUiState;
				currentState.originalSetEditorComponent(currentState.wrapFactory(factory));
			},
		};
		ui[MODE_BORDER_UI_KEY] = borderUiState;
		// SAFETY: Pi exposes this setter as a mutable callable UI method; the cast only narrows its factory signature for the proxy.
		(
			ctx.ui as unknown as {
				setEditorComponent: (factory: EditorFactory) => void;
			}
		).setEditorComponent = borderUiState.proxySetEditorComponent;
		originalSetEditorComponent(wrapFactory(previousEditor));
	};

	const refreshModeBorder = () => {
		// Re-wrap the editor if another extension replaced the factory after startup.
		if (activeContext) installModeBorder(activeContext);
		requestRender();
	};
	runtime[YOLO_RENDER_KEY] = refreshModeBorder;

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
		activeContext = ctx;
		activeTui = undefined;
		scheduleModeBorder(ctx);
	});

	pi.on("session_shutdown", () => {
		stopInstallTimer();
		activeContext = undefined;
		activeTui = undefined;
		modes.clear();
		usedMcpServers.clear();
		stopWatchingModes();
		if (runtime[YOLO_RENDER_KEY] === refreshModeBorder) {
			runtime[YOLO_RENDER_KEY] = undefined;
		}
	});
}
