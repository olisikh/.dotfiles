import type { ModeChangedEvent } from "./mode-events.ts";

export type BorderMode = "build" | "plan" | "goal";

export const MODE_COLORS: Record<BorderMode, string> = {
	build: "#f38ba8",
	plan: "#a6e3a1",
	goal: "#f9e2af",
};

export function borderModeFor(
	modes: ReadonlyMap<string, ModeChangedEvent>,
): BorderMode {
	if (modes.get("goal")?.active) return "goal";
	if (modes.get("plan")?.active) return "plan";
	return "build";
}

export function paintBorder(mode: BorderMode, text: string): string {
	const hex = MODE_COLORS[mode];
	const red = Number.parseInt(hex.slice(1, 3), 16);
	const green = Number.parseInt(hex.slice(3, 5), 16);
	const blue = Number.parseInt(hex.slice(5, 7), 16);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}
