/* @ts-expect-error Pi provides this module to extensions at runtime. */
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
	SessionTreeEvent,
	TurnEndEvent,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
// @ts-expect-error Pi provides this module at runtime.
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { PiForegroundTheme, PiThemeColor } from "./lib/pi-theme.ts";
import type { PiRenderTui } from "./lib/pi-tui.ts";
import {
	subscribeToModeChanges,
	type ModeChangedEvent,
} from "./lib/mode-events.ts";

type BranchEntries = ReturnType<
	ExtensionContext["sessionManager"]["getBranch"]
>;

interface CostTotals {
	value: number;
	available: boolean;
}

type FooterData = {
	onBranchChange(listener: () => void): () => void;
	getExtensionStatuses(): ReadonlyMap<string, string>;
	getGitBranch(): string | null;
};
const MODE_COLORS = {
	build: "error",
	plan: "success",
	goal: "warning",
	unknown: "accent",
} as const;

function compact(value: number | undefined): string {
	if (value === undefined || !Number.isFinite(value)) {
		return "?";
	}
	if (value < 1_000) {
		return `${Math.round(value)}`;
	}
	if (value < 1_000_000) {
		return `${(value / 1_000).toFixed(1)}k`;
	}
	return `${(value / 1_000_000).toFixed(1)}M`;
}

function contextUsageColor(
	percent: number | null | undefined,
): "success" | "warning" | "error" | "muted" {
	if (percent === undefined || percent === null) return "muted";
	if (percent >= 80) return "error";
	if (percent >= 50) return "warning";
	return "success";
}

function collectCostTotals(entries: BranchEntries): CostTotals {
	let value = 0;
	let available = false;

	for (const entry of entries) {
		if (entry.type !== "message" || entry.message.role !== "assistant") {
			continue;
		}

		const cost = Number(entry.message.usage.cost.total);
		if (Number.isFinite(cost) && cost > 0) {
			value += cost;
			available = true;
		}
	}

	return { value, available };
}

export default function (pi: ExtensionAPI) {
	let costTotals: CostTotals = { value: 0, available: false };
	const modes = new Map<string, ModeChangedEvent>();
	let requestRender: (() => void) | null = null;
	let stopWatchingModes: (() => void) | undefined = subscribeToModeChanges(
		pi,
		(event) => {
			modes.set(event.mode, event);
			requestRender?.();
		},
	);

	const syncCostTotals = (ctx: ExtensionContext) => {
		costTotals = collectCostTotals(ctx.sessionManager.getBranch());
		requestRender?.();
	};

	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		modes.clear();
		syncCostTotals(ctx);

		ctx.ui.setFooter(
			(tui: PiRenderTui, theme: PiForegroundTheme, footerData: FooterData) => {
				requestRender = () => tui.requestRender();
				const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

				return {
					dispose() {
						requestRender = null;
						unsubscribe();
					},
					invalidate() {},
					render(width: number): string[] {
						const usage = ctx.getContextUsage();
						const provider =
							(ctx.model as { provider?: string } | undefined)?.provider ?? "unknown";
						const model = ctx.model?.id ?? "no-model";
						const reasoning = pi.getThinkingLevel();
						const branch = footerData.getGitBranch();
						const folder = path.basename(ctx.cwd ?? ".");
						const usageColor = contextUsageColor(usage?.percent);
						const usageText = `${compact(usage?.tokens ?? undefined)} / ${compact(usage?.contextWindow)} (${usage?.percent?.toFixed(0) ?? "?"}%)`;

						const parts = [
							renderModeStatus(modes, footerData.getExtensionStatuses(), theme),
							theme.fg("accent", `${provider}/${model}:${reasoning}`),
							theme.fg(usageColor, usageText),
						];

						if (costTotals.available) {
							parts.push(theme.fg("warning", `$${costTotals.value.toFixed(2)}`));
						}

						parts.push(theme.fg("muted", `${folder}:${branch ?? "-"}`));

						return [truncateToWidth(parts.join(theme.fg("dim", " · ")), width)];
					},
				};
			},
		);
	});

	pi.on("session_tree", (_event: SessionTreeEvent, ctx: ExtensionContext) =>
		syncCostTotals(ctx),
	);

	pi.on("session_shutdown", () => {
		modes.clear();
		stopWatchingModes?.();
		stopWatchingModes = undefined;
		requestRender = null;
	});

	pi.on("turn_end", (event: TurnEndEvent) => {
		if (event.message.role !== "assistant") {
			return;
		}

		const cost = Number(event.message.usage.cost.total);
		if (Number.isFinite(cost) && cost > 0) {
			costTotals.value += cost;
			costTotals.available = true;
		}
	});
}

function renderModeStatus(
	modes: ReadonlyMap<string, ModeChangedEvent>,
	statuses: ReadonlyMap<string, string>,
	theme: PiForegroundTheme,
): string {
	const visibleModes = [...modes.values()]
		.filter((event) => event.state !== "off")
		.sort((left, right) => modePriority(left.mode) - modePriority(right.mode));
	if (visibleModes.length === 0) return theme.fg(MODE_COLORS.build, "build");

	return visibleModes
		.map((event) => {
			const statusKey = event.mode === "plan" ? "plan-mode" : event.mode;
			const status = statuses.get(statusKey)?.trim();
			let text = `${event.mode} ${event.state.replaceAll("_", " ")}`;
			if (status)
				text = event.mode === "plan" ? status : `${event.mode} ${status}`;
			return theme.fg(colorForMode(event.mode), text);
		})
		.join(" + ");
}

function modePriority(mode: string): number {
	if (mode === "goal") return 0;
	if (mode === "plan") return 1;
	return 2;
}

function colorForMode(mode: string): PiThemeColor {
	if (mode === "goal") return MODE_COLORS.goal;
	if (mode === "plan") return MODE_COLORS.plan;
	return MODE_COLORS.unknown;
}
