/* @ts-expect-error Pi provides this module to extensions at runtime. */
import path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";
/* @ts-expect-error Pi provides this module to extensions at runtime. */
import { truncateToWidth } from "@mariozechner/pi-tui";

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
	getGitBranch(): string | null;
};
type AssistantTurn = {
	message: { role: string; usage: { cost: { total: number } } };
};

const PLAN_MODE_STATE_ENTRY = "plan-mode-state";
const PLAN_MODE_COLOR = "#a6e3a1";
const BUILD_MODE_COLOR = "#f38ba8";
const PLAN_MODE_POLL_INTERVAL_MS = 250;

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

function paint(hex: string, text: string): string {
	const red = Number.parseInt(hex.slice(1, 3), 16);
	const green = Number.parseInt(hex.slice(3, 5), 16);
	const blue = Number.parseInt(hex.slice(5, 7), 16);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}

function isPlanModeEnabled(entries: BranchEntries): boolean {
	for (let index = entries.length - 1; index >= 0; index -= 1) {
		const entry = entries[index] as {
			type?: string;
			customType?: string;
			data?: { enabled?: unknown };
		};
		if (entry.type === "custom" && entry.customType === PLAN_MODE_STATE_ENTRY) {
			return entry.data?.enabled === true;
		}
	}
	return false;
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
	let planModeActive = false;
	let planModeTimer: ReturnType<typeof setInterval> | undefined;
	let requestRender: (() => void) | null = null;

	const syncCostTotals = (ctx: ExtensionContext) => {
		costTotals = collectCostTotals(ctx.sessionManager.getBranch());
		requestRender?.();
	};

	const syncPlanMode = (ctx: ExtensionContext) => {
		const nextPlanModeActive = isPlanModeEnabled(ctx.sessionManager.getBranch());
		if (nextPlanModeActive === planModeActive) return;
		planModeActive = nextPlanModeActive;
		requestRender?.();
	};

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		syncCostTotals(ctx);
		planModeActive = isPlanModeEnabled(ctx.sessionManager.getBranch());
		clearInterval(planModeTimer);
		planModeTimer = setInterval(
			() => syncPlanMode(ctx),
			PLAN_MODE_POLL_INTERVAL_MS,
		);

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

						const parts = [
							paint(
								planModeActive ? PLAN_MODE_COLOR : BUILD_MODE_COLOR,
								planModeActive ? "plan" : "build",
							),
							theme.fg("accent", `${provider}/${model}:${reasoning}`),
							theme.fg(
								"muted",
								`${compact(usage?.tokens)} / ${compact(usage?.contextWindow)} (${usage?.percent?.toFixed(0) ?? "?"}%)`,
							),
						];

						if (costTotals.available) {
							parts.push(theme.fg("warning", `$${costTotals.value.toFixed(2)}`));
						}

						parts.push(theme.fg("muted", `${folder}:${branch ?? "-"}`));

						return [truncateToWidth(parts.join(theme.fg("dim", " | ")), width)];
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
		clearInterval(planModeTimer);
		planModeTimer = undefined;
		planModeActive = false;
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
