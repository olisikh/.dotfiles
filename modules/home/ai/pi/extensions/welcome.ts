/* @ts-expect-error Pi provides this module at runtime. */
import { truncateToWidth } from "@mariozechner/pi-tui";

type Theme = {
	fg: (color: string, text: string) => string;
	bold: (text: string) => string;
};

type Context = {
	mode: string;
	cwd: string;
	ui: {
		setHeader: (factory: (_tui: unknown, theme: Theme) => Header) => void;
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

		ctx.ui.setHeader((_tui, theme) => ({
			render(width: number) {
				return [
					truncateToWidth(
						`${theme.fg("accent", "π")} ${theme.bold(project)}`,
						width,
					),
					truncateToWidth(
						theme.fg("dim", " /hotkeys · /settings · /resume · /reload\n"),
						width,
					),
				];
			},
			invalidate() {},
		}));
	});
}
