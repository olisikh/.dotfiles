/* @ts-expect-error Pi provides this module to extensions at runtime. */
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
/* @ts-expect-error Pi provides this module to extensions at runtime. */
import { truncateToWidth } from "@mariozechner/pi-tui";
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

type FooterTui = { requestRender(): void };
type FooterTheme = { fg(color: string, text: string): string };
type FooterData = {
	onBranchChange(listener: () => void): () => void;
	getExtensionStatuses(): ReadonlyMap<string, string>;
	getGitBranch(): string | null;
};
type AssistantTurn = {
	message: { role: string; usage: { cost: { total: number } } };
};

const MODE_COLORS = {
	build: "#f38ba8",
	plan: "#a6e3a1",
	goal: "#f9e2af",
	unknown: "#cba6f7",
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

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		modes.clear();
		syncCostTotals(ctx);

		ctx.ui.setFooter(
			(tui: FooterTui, theme: FooterTheme, footerData: FooterData) => {
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
						const usageText = `${compact(usage?.tokens)} / ${compact(usage?.contextWindow)} (${usage?.percent?.toFixed(0) ?? "?"}%)`;

						const parts = [
							renderModeStatus(modes, footerData.getExtensionStatuses()),
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

	pi.on("session_switch", (_event: unknown, ctx: ExtensionContext) =>
		syncCostTotals(ctx),
	);
	pi.on("session_tree", (_event: unknown, ctx: ExtensionContext) =>
		syncCostTotals(ctx),
	);
	pi.on("session_fork", (_event: unknown, ctx: ExtensionContext) =>
		syncCostTotals(ctx),
	);

	pi.on("session_shutdown", () => {
		modes.clear();
		stopWatchingModes?.();
		stopWatchingModes = undefined;
		requestRender = null;
	});

	pi.on("turn_end", (event: AssistantTurn) => {
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
): string {
	const visibleModes = [...modes.values()]
		.filter((event) => event.state !== "off")
		.sort((left, right) => modePriority(left.mode) - modePriority(right.mode));
	if (visibleModes.length === 0) return paint(MODE_COLORS.build, "build");

	return visibleModes
		.map((event) => {
			const statusKey = event.mode === "plan" ? "plan-mode" : event.mode;
			const status = statuses.get(statusKey)?.trim();
			let text = `${event.mode} ${event.state.replaceAll("_", " ")}`;
			if (status)
				text = event.mode === "plan" ? status : `${event.mode} ${status}`;
			return paint(colorForMode(event.mode), text);
		})
		.join(" + ");
}

function modePriority(mode: string): number {
	if (mode === "goal") return 0;
	if (mode === "plan") return 1;
	return 2;
}

function colorForMode(mode: string): string {
	if (mode === "goal") return MODE_COLORS.goal;
	if (mode === "plan") return MODE_COLORS.plan;
	return MODE_COLORS.unknown;
}

function paint(hex: string, text: string): string {
	const red = Number.parseInt(hex.slice(1, 3), 16);
	const green = Number.parseInt(hex.slice(3, 5), 16);
	const blue = Number.parseInt(hex.slice(5, 7), 16);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}
