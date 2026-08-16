import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
import {
	isModeChangedEvent,
	type ModeChangedEvent,
	subscribeToModeChanges,
} from "./lib/mode-events.ts";
import { borderModeFor, paintBorder } from "./lib/mode-border.ts";

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
	let activeTui: ActiveTui | undefined;
	let editorComponentInstalled = false;
	let installTimer: ReturnType<typeof setTimeout> | undefined;

	const stopInstallTimer = () => {
		if (installTimer) clearTimeout(installTimer);
		installTimer = undefined;
	};

	const requestRender = () => activeTui?.requestRender();
	const stopWatchingModes = subscribeToModeChanges(pi, (event) => {
		if (!isModeChangedEvent(event)) return;
		modes.set(event.mode, event);
		requestRender();
	});

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
					return render(width);
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
		activeTui = undefined;
		editorComponentInstalled = false;
		scheduleModeBorder(ctx);
	});

	pi.on("session_shutdown", () => {
		stopInstallTimer();
		activeTui = undefined;
		editorComponentInstalled = false;
		modes.clear();
		stopWatchingModes();
	});
}
