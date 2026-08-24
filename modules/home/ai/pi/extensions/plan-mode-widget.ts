// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
} from "@mariozechner/pi-coding-agent";
import { PI_WIDGET_KEYS } from "./lib/pi-constants.ts";
import type { PiWidgetUi } from "./lib/pi-widgets.ts";

const PLAN_MODE_WIDGET_KEY = PI_WIDGET_KEYS.planModePlan;
const PLAN_MODE_PLANNING_WIDGET_TITLE = "Plan mode: planning";

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		const ui = ctx.ui as PiWidgetUi;
		const setWidget = ui.setWidget.bind(ui);
		ui.setWidget = (key, widget, options) => {
			if (
				key === PLAN_MODE_WIDGET_KEY &&
				Array.isArray(widget) &&
				widget[0] === PLAN_MODE_PLANNING_WIDGET_TITLE
			) {
				setWidget(key, undefined, options);
				return;
			}
			setWidget(key, widget, options);
		};
	});
}
