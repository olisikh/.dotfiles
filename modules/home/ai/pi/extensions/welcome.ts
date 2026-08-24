// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
} from "@mariozechner/pi-coding-agent";
// @ts-ignore Pi provides this module at runtime.
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { PiTextTheme } from "./lib/pi-theme.ts";
import { PI_THEME_COLORS } from "./lib/pi-theme.ts";
import type { PiRenderTui } from "./lib/pi-tui.ts";

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;

		const project = ctx.cwd.split("/").pop() ?? ctx.cwd;

		ctx.ui.setHeader((_tui: PiRenderTui, theme: PiTextTheme) => {
			return {
				render(width: number) {
					return [
						`${theme.fg(PI_THEME_COLORS.accent, "Pi")} ${theme.bold(project)}\n\n`,
						"",
						theme.fg(PI_THEME_COLORS.dim, "Useful commands:\n"),
						theme.fg(PI_THEME_COLORS.dim, "  /hotkeys  - display hotkeys\n"),
						theme.fg(PI_THEME_COLORS.dim, "  /settings - display settings\n"),
						theme.fg(PI_THEME_COLORS.dim, "  /resume   - resume session\n"),
						theme.fg(PI_THEME_COLORS.dim, "  /reload   - reload harness\n"),
						theme.fg(PI_THEME_COLORS.dim, "  /new      - start a new session\n"),
						"",
					].map((line) => truncateToWidth(line, width));
				},
				invalidate() {},
			};
		});
	});
}
