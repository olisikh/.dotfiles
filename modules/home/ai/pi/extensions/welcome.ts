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

type TuiRoot = {
	render: (width: number) => string[];
};

type Tui = {
	children: TuiRoot[];
};

type Pi = {
	on: (
		event: "session_start",
		handler: (_event: unknown, ctx: Context) => void,
	) => void;
};

// Pi only exposes padding for individual components; inset every mounted root at the shared TUI seam.
const CONTENT_INSET = 1;
const patchedRoots = new WeakSet<object>();

function installContentInset(tui: Tui): void {
	for (const root of tui.children) {
		if (patchedRoots.has(root)) continue;

		const render = root.render.bind(root);
		root.render = (width) => {
			const availableWidth = Math.max(1, Math.floor(width));
			const inset = Math.min(CONTENT_INSET, availableWidth - 1);
			const prefix = " ".repeat(inset);

			return render(availableWidth - inset).map((line) => `${prefix}${line}`);
		};
		patchedRoots.add(root);
	}
}

export default function (pi: Pi) {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		const project = ctx.cwd.split("/").pop() ?? ctx.cwd;

		ctx.ui.setHeader((_tui, theme) => {
			installContentInset(_tui as Tui);

			return {
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
			};
		});
	});
}
