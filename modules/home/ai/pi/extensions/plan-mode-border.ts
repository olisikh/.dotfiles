import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
import { paintPlanMode, watchPlanMode } from "./lib/plan-mode.ts";

type ActiveTui = {
	requestRender: () => void;
};

export default function (pi: ExtensionAPI) {
	let planModeActive = false;
	let stopWatchingPlanMode: (() => void) | undefined;
	let installTimer: ReturnType<typeof setTimeout> | undefined;
	let activeTui: ActiveTui | undefined;
	let editorComponentInstalled = false;

	const stopInstallTimer = () => {
		if (installTimer) clearTimeout(installTimer);
		installTimer = undefined;
	};

	const installPlanModeBorder = (ctx: ExtensionContext) => {
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
					editor.borderColor = (text: string) => paintPlanMode(planModeActive, text);
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

	const schedulePlanModeBorder = (ctx: ExtensionContext) => {
		stopInstallTimer();
		// ponytail: defer one tick so later-loaded editor extensions finish first; use explicit extension ordering if Pi adds it.
		installTimer = setTimeout(() => {
			installTimer = undefined;
			installPlanModeBorder(ctx);
		}, 0);
	};

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		activeTui = undefined;
		editorComponentInstalled = false;
		stopWatchingPlanMode?.();
		stopWatchingPlanMode = watchPlanMode(ctx, (enabled) => {
			planModeActive = enabled;
			activeTui?.requestRender();
		});
		schedulePlanModeBorder(ctx);
	});

	pi.on("session_shutdown", () => {
		stopInstallTimer();
		stopWatchingPlanMode?.();
		stopWatchingPlanMode = undefined;
		activeTui = undefined;
		planModeActive = false;
		editorComponentInstalled = false;
	});
}
