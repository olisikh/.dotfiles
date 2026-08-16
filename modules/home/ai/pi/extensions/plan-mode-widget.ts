import type {
	ExtensionAPI,
	ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";

const PLAN_MODE_WIDGET_KEY = "plan-mode-plan";
const PLAN_MODE_PLANNING_WIDGET_TITLE = "Plan mode: planning";

type UiWithWidget = {
	setWidget: (key: string, widget: unknown, ...args: unknown[]) => void;
};

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
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
	});
}
