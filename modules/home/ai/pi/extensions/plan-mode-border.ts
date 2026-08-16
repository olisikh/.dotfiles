import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";

const PLAN_MODE_STATE_ENTRY = "plan-mode-state";
const PLAN_MODE_WIDGET_KEY = "plan-mode-plan";
const PLAN_MODE_PLANNING_WIDGET_TITLE = "Plan mode: planning";
const PLAN_MODE_BORDER_COLOR = "#a6e3a1";
const NORMAL_BORDER_COLOR = "#f38ba8";
const PLAN_MODE_POLL_INTERVAL_MS = 250;

type ActiveTui = {
	requestRender: () => void;
};

type UiWithWidget = {
	setWidget: (key: string, widget: unknown, ...args: unknown[]) => void;
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function isPlanModeEnabled(ctx: ExtensionContext): boolean {
	const entries = ctx.sessionManager.getBranch();
	for (let index = entries.length - 1; index >= 0; index -= 1) {
		const entry = entries[index];
		if (
			!isRecord(entry) ||
			entry.type !== "custom" ||
			entry.customType !== PLAN_MODE_STATE_ENTRY ||
			!isRecord(entry.data)
		) {
			continue;
		}
		return entry.data.enabled === true;
	}
	return false;
}

export default function (pi: ExtensionAPI) {
	let planModeActive = false;
	let planModeTimer: ReturnType<typeof setInterval> | undefined;
	let installTimer: ReturnType<typeof setTimeout> | undefined;
	let activeTui: ActiveTui | undefined;
	let editorComponentInstalled = false;

	const stopInstallTimer = () => {
		if (installTimer) clearTimeout(installTimer);
		installTimer = undefined;
	};

	const stopPlanModeTimer = () => {
		if (planModeTimer) clearInterval(planModeTimer);
		planModeTimer = undefined;
	};

	const refreshPlanModeBorder = (ctx: ExtensionContext) => {
		const nextPlanModeActive = isPlanModeEnabled(ctx);
		if (nextPlanModeActive === planModeActive) return;
		planModeActive = nextPlanModeActive;
		activeTui?.requestRender();
	};

	const hidePlanModePlanningWidget = (ctx: ExtensionContext) => {
		const ui = ctx.ui as unknown as UiWithWidget;
		const setWidget = ui.setWidget.bind(ui);
		ui.setWidget = (key, widget, ...args) => {
			if (
				key === PLAN_MODE_WIDGET_KEY &&
				Array.isArray(widget) &&
				widget[0] === PLAN_MODE_PLANNING_WIDGET_TITLE
			) {
				setWidget(key, undefined, ...args);
				return;
			}
			setWidget(key, widget, ...args);
		};
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
					editor.borderColor = (text: string) =>
						paint(
							planModeActive ? PLAN_MODE_BORDER_COLOR : NORMAL_BORDER_COLOR,
							text,
						);
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

	const startPlanModeTimer = (ctx: ExtensionContext) => {
		stopPlanModeTimer();
		planModeActive = isPlanModeEnabled(ctx);
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		// ponytail: poll because pi-plan-mode exposes no transition event; use pi.events if it adds one.
		planModeTimer = setInterval(
			() => refreshPlanModeBorder(ctx),
			PLAN_MODE_POLL_INTERVAL_MS,
		);
	};

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		activeTui = undefined;
		editorComponentInstalled = false;
		hidePlanModePlanningWidget(ctx);
		schedulePlanModeBorder(ctx);
		startPlanModeTimer(ctx);
	});

	pi.on("session_shutdown", () => {
		stopInstallTimer();
		stopPlanModeTimer();
		activeTui = undefined;
		planModeActive = false;
		editorComponentInstalled = false;
	});
}

function paint(hex: string, text: string): string {
	const [red, green, blue] = rgb(hex);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}

function rgb(hex: string): [number, number, number] {
	return [
		Number.parseInt(hex.slice(1, 3), 16),
		Number.parseInt(hex.slice(3, 5), 16),
		Number.parseInt(hex.slice(5, 7), 16),
	];
}
