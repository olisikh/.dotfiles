// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
	// @ts-ignore Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
/* @ts-ignore Pi provides this module at runtime. */
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { PiTextTheme } from "./lib/pi-theme.ts";
import type { PiRenderTui } from "./lib/pi-tui.ts";

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;

		const project = ctx.cwd.split("/").pop() ?? ctx.cwd;

		ctx.ui.setHeader((_tui: PiRenderTui, theme: PiTextTheme) => {
			return {
				render(width: number) {
					return [
						`${theme.fg("accent", "Pi")} ${theme.bold(project)}\n\n`,
						"",
						theme.fg("dim", "Useful commands:\n"),
						theme.fg("dim", "  /hotkeys  - display hotkeys\n"),
						theme.fg("dim", "  /settings - display settings\n"),
						theme.fg("dim", "  /resume   - resume session\n"),
						theme.fg("dim", "  /reload   - reload harness\n"),
						theme.fg("dim", "  /new      - start a new session\n"),
						"",
					].map((line) => truncateToWidth(line, width));
				},
				invalidate() {},
			};
		});
	});
}
