/* @ts-expect-error Pi provides this module at runtime. */
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { PiTextTheme } from "./lib/pi-theme.ts";

type Context = {
  mode: string;
  cwd: string;
  ui: {
    setHeader: (factory: (_tui: unknown, theme: PiTextTheme) => Header) => void;
  };
};

type Header = {
  render: (width: number) => string[];
  invalidate: () => void;
};

type Pi = {
  on: (
    event: "session_start",
    handler: (_event: unknown, ctx: Context) => void,
  ) => void;
};

export default function (pi: Pi) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    const project = ctx.cwd.split("/").pop() ?? ctx.cwd;

    ctx.ui.setHeader((_tui, theme) => {
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
