const PLAN_MODE_STATE_ENTRY = "plan-mode-state";
const PLAN_MODE_POLL_INTERVAL_MS = 250;

export const planModeColors = {
	build: "#f38ba8",
	plan: "#a6e3a1",
} as const;

type PlanModeContext = {
	sessionManager: { getBranch(): unknown[] };
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

export function isPlanModeEnabled(entries: unknown[]): boolean {
	for (let index = entries.length - 1; index >= 0; index -= 1) {
		const entry = entries[index];
		if (
			!isRecord(entry) ||
			entry.type !== "custom" ||
			entry.customType !== PLAN_MODE_STATE_ENTRY ||
			!isRecord(entry.data)
		) {
			continue;
		}
		return entry.data.enabled === true;
	}
	return false;
}

export function watchPlanMode(
	ctx: PlanModeContext,
	onChange: (enabled: boolean) => void,
): () => void {
	let enabled = isPlanModeEnabled(ctx.sessionManager.getBranch());
	onChange(enabled);

	const timer = setInterval(() => {
		const nextEnabled = isPlanModeEnabled(ctx.sessionManager.getBranch());
		if (nextEnabled === enabled) return;
		enabled = nextEnabled;
		onChange(enabled);
	}, PLAN_MODE_POLL_INTERVAL_MS);

	return () => clearInterval(timer);
}

export function paintPlanMode(enabled: boolean, text: string): string {
	const hex = enabled ? planModeColors.plan : planModeColors.build;
	const red = Number.parseInt(hex.slice(1, 3), 16);
	const green = Number.parseInt(hex.slice(3, 5), 16);
	const blue = Number.parseInt(hex.slice(5, 7), 16);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}
