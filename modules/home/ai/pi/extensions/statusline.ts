import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";

type BranchEntries = ReturnType<ExtensionContext["sessionManager"]["getBranch"]>;

interface CostTotals {
	value: number;
	available: boolean;
}

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
	let requestRender: (() => void) | null = null;

	const syncCostTotals = (ctx: ExtensionContext) => {
		costTotals = collectCostTotals(ctx.sessionManager.getBranch());
		requestRender?.();
	};

	pi.on("session_start", (_event, ctx) => {
		syncCostTotals(ctx);

		ctx.ui.setFooter((tui, theme, footerData) => {
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
					const provider = (ctx.model as { provider?: string } | undefined)?.provider ?? "unknown";
					const model = ctx.model?.id ?? "no-model";
					const reasoning = pi.getThinkingLevel();
					const branch = footerData.getGitBranch();
					const folder = path.basename(ctx.cwd ?? process.cwd());

					const parts = [
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
		});
	});

	pi.on("session_switch", (_event, ctx) => syncCostTotals(ctx));
	pi.on("session_tree", (_event, ctx) => syncCostTotals(ctx));
	pi.on("session_fork", (_event, ctx) => syncCostTotals(ctx));

	pi.on("turn_end", (event) => {
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
