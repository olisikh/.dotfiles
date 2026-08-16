/* @ts-expect-error Pi provides this module at runtime. */
import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";

const DEFAULT_SHIMMER_INTERVAL_MS = 120;
const DEFAULT_SPINNER_INTERVAL_MS = 120;
const TOKEN_COUNTER_INTERVAL_MS = 50;
const PHRASE_INTERVAL_MS = 2_400;
const DEFAULT_COLOR_ROTATION_INTERVAL_MS = 2_500;
const STALL_TIMEOUT_MS = 3_000;
const CHARS_PER_TOKEN = 4;
const DEFAULT_COLOR = "#cba6f7";
const CATPPUCCIN_COLORS = [
	"#cba6f7", // mauve
	"#b4befe", // lavender
	"#89b4fa", // blue
	"#94e2d5", // teal
	"#a6e3a1", // green
	"#f9e2af", // yellow
	"#fab387", // peach
];
const STALLED_COLOR = "#f38ba8";
const NORMAL_BORDER_COLOR = "#f38ba8";
const PLAN_MODE_BORDER_COLOR = "#a6e3a1";
const PLAN_MODE_STATE_ENTRY = "plan-mode-state";
const PLAN_MODE_POLL_INTERVAL_MS = 250;
const TELEMETRY_COLOR = "#6c7086"; // Catppuccin overlay0; visible even when SGR dim is ignored.
const INPUT_ARROW = "↑";
const OUTPUT_ARROW = "↓";
const TIMER_ICON = "󰔟";
const PHRASES = [
	"Bamboozling...",
	"Contemplating the orb...",
	"Wrestling the electrons...",
	"Consulting the vibes...",
	"Untangling spaghetti...",
	"Convincing the pixels...",
	"Polishing the goblins...",
	"Performing tasteful wizardry...",
	"Forming a Voltron...",
	"Consuming energon...",
	"Running the hamster...",
	"Questioning the universe...",
	"Sending hornets...",
	"Tickling the dragon...",
	"Summoning the Kraken...",
	"Brewing a potion...",
	"Aligning the stars...",
	"Consulting magic 8-ball...",
	"Negotiating with AI overlords...",
	"Transmogrifying the data...",
	"Meaning of life?..",
	"Asking Calcifer...",
	"Asking your mom...",
	"Asking your dad...",
	"Checking your horoscope...",
	"Blessing the code...",
	"Kissing the frog...",
];

const SHIMMER_FRAMES = ["·", "✢", "✳", "✶", "✻", "✽", "✻", "✶", "✳", "✢"];
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const GRADIENT_CYCLE_LENGTH = 8;
type IndicatorType = "shimmer" | "spinner";
type Phase = "requesting" | "thinking" | "responding" | "tool-use";

type WorkingState = {
	phrase: string;
	phase: Phase;
	startedAt: number;
	thinkingStartedAt?: number;
	streamedChars: number;
	inputTokens: number;
	displayedInputTokens: number;
	outputTokens: number;
	displayedOutputChars: number;
	currentAssistantChars: number;
	currentTextBlockChars: number;
	assistantMessageActive: boolean;
	lastTokenAt: number;
	activeTools: number;
};

function randomPhrase(previous?: string): string {
	const choices = PHRASES.filter((phrase) => phrase !== previous);
	return choices[Math.floor(Math.random() * choices.length)] ?? PHRASES[0];
}

function readEnvironment(name: string): string | undefined {
	const processLike = (
		globalThis as typeof globalThis & {
			process?: { env?: Record<string, string | undefined> };
		}
	).process;
	return processLike?.env?.[name];
}

function readHexColor(value: string | undefined, fallback: string): string {
	const candidate = value?.trim().toLowerCase();
	return candidate && /^#[0-9a-f]{6}$/u.test(candidate) ? candidate : fallback;
}

function readPositiveInteger(
	value: string | undefined,
	fallback: number,
): number {
	const candidate = Number(value);
	return Number.isInteger(candidate) && candidate > 0 ? candidate : fallback;
}

function readBoolean(value: string | undefined): boolean {
	return value === "1" || value?.toLowerCase() === "true";
}

function readIndicatorType(value: string | undefined): IndicatorType {
	return value === "spinner" ? "spinner" : "shimmer";
}

const INDICATOR_TYPE = readIndicatorType(
	readEnvironment("PI_WORKING_INDICATOR_TYPE"),
);
const DEFAULT_COLOR_VALUE = readHexColor(
	readEnvironment("PI_WORKING_INDICATOR_DEFAULT_COLOR"),
	DEFAULT_COLOR,
);
const ROTATE_COLORS = readBoolean(
	readEnvironment("PI_WORKING_INDICATOR_ROTATE_COLORS"),
);
const COLOR_ROTATION_INTERVAL_MS = readPositiveInteger(
	readEnvironment("PI_WORKING_INDICATOR_COLOR_ROTATION_MS"),
	DEFAULT_COLOR_ROTATION_INTERVAL_MS,
);
const SHIMMER_INTERVAL_MS = readPositiveInteger(
	readEnvironment("PI_WORKING_INDICATOR_SHIMMER_INTERVAL_MS"),
	DEFAULT_SHIMMER_INTERVAL_MS,
);
const SPINNER_INTERVAL_MS = readPositiveInteger(
	readEnvironment("PI_WORKING_INDICATOR_SPINNER_INTERVAL_MS"),
	DEFAULT_SPINNER_INTERVAL_MS,
);
const ROTATION_COLORS = [
	DEFAULT_COLOR_VALUE,
	...CATPPUCCIN_COLORS.filter((color) => color !== DEFAULT_COLOR_VALUE),
];

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function getAssistantMessageEvent(
	event: unknown,
): Record<string, unknown> | undefined {
	if (!isRecord(event) || !isRecord(event.assistantMessageEvent)) {
		return undefined;
	}
	return event.assistantMessageEvent;
}

function textLength(content: unknown): number {
	if (typeof content === "string") return content.length;
	if (!Array.isArray(content)) return 0;

	return content.reduce((length, block) => {
		if (
			!isRecord(block) ||
			block.type !== "text" ||
			typeof block.text !== "string"
		) {
			return length;
		}
		return length + block.text.length;
	}, 0);
}

function formatDuration(milliseconds: number): string {
	const seconds = Math.max(0, Math.floor(milliseconds / 1_000));
	const minutes = Math.floor(seconds / 60);
	return minutes > 0 ? `${minutes}m ${seconds % 60}s` : `${seconds}s`;
}

function formatCount(tokens: number): string {
	return Math.max(0, Math.round(tokens)).toLocaleString("en-US");
}

function formatTokenLine(arrow: string, tokens: number): string {
	return `${arrow} ${formatCount(tokens)}`;
}

function advanceCounter(current: number, target: number): number {
	if (current >= target) return current;
	const gap = target - current;
	let increment = 50;
	if (gap < 70) {
		increment = 3;
	} else if (gap < 200) {
		increment = Math.max(8, Math.ceil(gap * 0.15));
	}
	return Math.min(current + increment, target);
}

function advanceTokenCounters(state: WorkingState): boolean {
	const outputTarget = Math.max(
		state.streamedChars,
		state.outputTokens * CHARS_PER_TOKEN,
	);
	const nextInput = advanceCounter(
		state.displayedInputTokens,
		state.inputTokens,
	);
	const nextOutput = advanceCounter(state.displayedOutputChars, outputTarget);
	const changed =
		nextInput !== state.displayedInputTokens ||
		nextOutput !== state.displayedOutputChars;
	state.displayedInputTokens = nextInput;
	state.displayedOutputChars = nextOutput;
	return changed;
}

function recordUsage(state: WorkingState, message: unknown): void {
	if (!isRecord(message) || !isRecord(message.usage)) return;

	const input = Number(message.usage.input ?? message.usage.inputTokens);
	if (Number.isFinite(input) && input > 0) {
		state.inputTokens += input;
	}

	const output = Number(message.usage.output ?? message.usage.outputTokens);
	if (Number.isFinite(output) && output > 0) {
		state.outputTokens += output;
	}
}

function isStalled(state: WorkingState, now: number): boolean {
	return (
		state.lastTokenAt > 0 &&
		now - state.lastTokenAt >= STALL_TIMEOUT_MS &&
		state.phase !== "tool-use" &&
		state.activeTools === 0
	);
}

function isPlanModeEnabled(ctx: ExtensionContext): boolean {
	const entries = ctx.sessionManager.getBranch();
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

function buildWorkingMessage(
	state: WorkingState,
	now: number,
	gradientOffset: number,
	activeColor: string,
): string {
	const stalled = isStalled(state, now);
	const details = [`${TIMER_ICON} ${formatDuration(now - state.startedAt)}`];

	const inputTokens = Math.round(state.displayedInputTokens);
	if (inputTokens > 0) {
		details.push(formatTokenLine(INPUT_ARROW, inputTokens));
	}

	const outputTokens = Math.round(state.displayedOutputChars / CHARS_PER_TOKEN);
	if (outputTokens > 0) {
		details.push(formatTokenLine(OUTPUT_ARROW, outputTokens));
	}

	if (stalled) {
		details.push("stalled");
	}

	const phrase = stalled
		? paint(STALLED_COLOR, state.phrase)
		: gradientText(state.phrase, gradientOffset, activeColor);
	const telemetry = paint(TELEMETRY_COLOR, `· ${details.join(" · ")}`);
	return `${phrase} \x1b[2m${telemetry}\x1b[22m`;
}

export default function (pi: ExtensionAPI) {
	let previousPhrase: string | undefined;
	let activeContext: ExtensionContext | undefined;
	let state: WorkingState | undefined;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let tokenTimer: ReturnType<typeof setInterval> | undefined;
	let phraseTimer: ReturnType<typeof setInterval> | undefined;
	let colorTimer: ReturnType<typeof setInterval> | undefined;
	let gradientTimer: ReturnType<typeof setInterval> | undefined;
	let colorIndex = 0;
	let activeColor = DEFAULT_COLOR_VALUE;
	let gradientOffset = 0;
	let planModeActive = false;
	let planModeTimer: ReturnType<typeof setInterval> | undefined;
	let activeTui: TUI | undefined;
	let editorComponentInstalled = false;

	const render = () => {
		if (!state || !activeContext) return;
		activeContext.ui.setWorkingMessage(
			buildWorkingMessage(state, Date.now(), gradientOffset, activeColor),
		);
	};

	const stopRefreshTimer = () => {
		if (refreshTimer) clearInterval(refreshTimer);
		refreshTimer = undefined;
	};

	const stopPlanModeTimer = () => {
		if (planModeTimer) clearInterval(planModeTimer);
		planModeTimer = undefined;
	};

	const refreshPlanModeBorder = (ctx: ExtensionContext) => {
		const nextPlanModeActive = isPlanModeEnabled(ctx);
		if (nextPlanModeActive === planModeActive) return;
		planModeActive = nextPlanModeActive;
		activeTui?.requestRender();
	};

	const installPlanModeBorder = (ctx: ExtensionContext) => {
		if (editorComponentInstalled || ctx.mode !== "tui" || !ctx.hasUI) return;
		const previousEditor = ctx.ui.getEditorComponent();
		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			const editor = (previousEditor?.(tui, theme, keybindings) ??
				new CustomEditor(tui, theme, keybindings)) as CustomEditor;
			activeTui = tui;
			editor.borderColor = (text: string) =>
				paint(planModeActive ? PLAN_MODE_BORDER_COLOR : NORMAL_BORDER_COLOR, text);
			return editor;
		});
		editorComponentInstalled = true;
	};

	const startPlanModeTimer = (ctx: ExtensionContext) => {
		stopPlanModeTimer();
		planModeActive = isPlanModeEnabled(ctx);
		if (ctx.mode !== "tui" || !ctx.hasUI) return;
		// ponytail: poll the plan-mode entry because the package exposes no transition event; use pi.events if it adds one.
		planModeTimer = setInterval(
			() => refreshPlanModeBorder(ctx),
			PLAN_MODE_POLL_INTERVAL_MS,
		);
	};

	const applyIndicatorStyle = () => {
		if (!activeContext) return;
		const frames = INDICATOR_TYPE === "shimmer" ? SHIMMER_FRAMES : SPINNER_FRAMES;
		activeContext.ui.setWorkingIndicator({
			frames: frames.map((glyph) => paint(activeColor, glyph)),
			intervalMs: SPINNER_INTERVAL_MS,
		});
	};

	const stopAnimationTimers = () => {
		if (tokenTimer) clearInterval(tokenTimer);
		if (phraseTimer) clearInterval(phraseTimer);
		if (colorTimer) clearInterval(colorTimer);
		if (gradientTimer) clearInterval(gradientTimer);
		tokenTimer = undefined;
		phraseTimer = undefined;
		colorTimer = undefined;
		gradientTimer = undefined;
	};

	const startAnimationTimers = () => {
		stopAnimationTimers();
		gradientOffset = 0;
		tokenTimer = setInterval(() => {
			if (state && advanceTokenCounters(state)) render();
		}, TOKEN_COUNTER_INTERVAL_MS);
		gradientTimer = setInterval(() => {
			gradientOffset = (gradientOffset + 1) % GRADIENT_CYCLE_LENGTH;
			render();
		}, SHIMMER_INTERVAL_MS);
		phraseTimer = setInterval(() => {
			if (!state) return;
			state.phrase = randomPhrase(state.phrase);
			render();
		}, PHRASE_INTERVAL_MS);
		if (ROTATE_COLORS) {
			colorTimer = setInterval(() => {
				colorIndex = (colorIndex + 1) % ROTATION_COLORS.length;
				activeColor = ROTATION_COLORS[colorIndex];
				applyIndicatorStyle();
				render();
			}, COLOR_ROTATION_INTERVAL_MS);
		}
	};

	const startRefreshTimer = () => {
		stopRefreshTimer();
		refreshTimer = setInterval(render, SHIMMER_INTERVAL_MS);
	};

	const beginRequest = (ctx: ExtensionContext) => {
		activeContext = ctx;
		stopRefreshTimer();

		const phrase = randomPhrase(previousPhrase);
		previousPhrase = phrase;
		state = {
			phrase,
			phase: "requesting",
			startedAt: Date.now(),
			streamedChars: 0,
			inputTokens: 0,
			displayedInputTokens: 0,
			outputTokens: 0,
			displayedOutputChars: 0,
			currentAssistantChars: 0,
			currentTextBlockChars: 0,
			assistantMessageActive: false,
			lastTokenAt: 0,
			activeTools: 0,
		};

		startAnimationTimers();
		startRefreshTimer();
		render();
	};

	const beginTurn = (ctx: ExtensionContext) => {
		activeContext = ctx;
		if (!state) {
			beginRequest(ctx);
			return;
		}

		state.phase = state.activeTools > 0 ? "tool-use" : "requesting";
		state.thinkingStartedAt = undefined;
		state.lastTokenAt = 0;
		state.currentAssistantChars = 0;
		state.currentTextBlockChars = 0;
		state.assistantMessageActive = false;
		render();
	};

	const finishRequest = () => {
		stopRefreshTimer();
		stopAnimationTimers();
		activeContext?.ui.setWorkingMessage();
		state = undefined;
		activeContext = undefined;
	};

	const addStreamedText = (length: number, now: number) => {
		if (!state || length <= 0) return;
		state.streamedChars += length;
		state.currentAssistantChars += length;
		state.currentTextBlockChars += length;
		state.lastTokenAt = now;
	};

	const handleMessageUpdate = (event: unknown, ctx: ExtensionContext) => {
		activeContext = ctx;
		if (!state) beginRequest(ctx);

		const assistantEvent = getAssistantMessageEvent(event);
		if (!assistantEvent || !state) return;

		const now = Date.now();
		switch (assistantEvent.type) {
			case "thinking_start":
				state.phase = "thinking";
				state.thinkingStartedAt = now;
				state.lastTokenAt = 0;
				break;
			case "thinking_delta":
				state.phase = "thinking";
				state.thinkingStartedAt ??= now;
				break;
			case "thinking_end":
				if (state.phase === "thinking") state.phase = "requesting";
				state.thinkingStartedAt = undefined;
				break;
			case "text_start":
				if (!state.assistantMessageActive) {
					state.assistantMessageActive = true;
					state.currentAssistantChars = 0;
				}
				state.currentTextBlockChars = 0;
				state.phase = "responding";
				state.thinkingStartedAt = undefined;
				break;
			case "text_delta":
				state.phase = "responding";
				state.thinkingStartedAt = undefined;
				if (typeof assistantEvent.delta === "string") {
					addStreamedText(assistantEvent.delta.length, now);
				}
				break;
			case "text_end": {
				const finalTextLength = textLength(assistantEvent.content);
				const missing = Math.max(0, finalTextLength - state.currentTextBlockChars);
				addStreamedText(missing, now);
				state.currentTextBlockChars = finalTextLength;
				break;
			}
			case "toolcall_start":
				state.phase = "tool-use";
				state.thinkingStartedAt = undefined;
				state.lastTokenAt = 0;
				break;
			case "done": {
				const message = isRecord(assistantEvent.message)
					? assistantEvent.message
					: undefined;
				const finalTextLength = textLength(message?.content);
				const missing = Math.max(0, finalTextLength - state.currentAssistantChars);
				addStreamedText(missing, now);
				state.currentTextBlockChars = 0;
				state.currentAssistantChars = 0;
				state.assistantMessageActive = false;
				state.thinkingStartedAt = undefined;
				state.phase = state.activeTools > 0 ? "tool-use" : "responding";
				break;
			}
			default:
				break;
		}

		render();
	};

	const handleToolStart = (ctx: ExtensionContext) => {
		activeContext = ctx;
		if (!state) beginRequest(ctx);
		if (!state) return;

		state.activeTools += 1;
		state.phase = "tool-use";
		state.lastTokenAt = 0;
		render();
	};

	const handleTurnEnd = (event: unknown, ctx: ExtensionContext) => {
		activeContext = ctx;
		if (!state || !isRecord(event)) return;
		recordUsage(state, event.message);
		render();
	};

	const handleToolEnd = (ctx: ExtensionContext) => {
		activeContext = ctx;
		if (!state) return;

		state.activeTools = Math.max(0, state.activeTools - 1);
		if (state.activeTools === 0 && state.phase === "tool-use") {
			state.phase = "responding";
		}
		state.lastTokenAt = 0;
		render();
	};

	pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => {
		stopRefreshTimer();
		stopAnimationTimers();
		activeTui = undefined;
		state = undefined;
		activeContext = ctx;
		colorIndex = 0;
		activeColor = DEFAULT_COLOR_VALUE;
		gradientOffset = 0;
		installPlanModeBorder(ctx);
		startPlanModeTimer(ctx);
		applyIndicatorStyle();
	});

	pi.on("agent_start", (_event: unknown, ctx: ExtensionContext) =>
		beginRequest(ctx),
	);
	pi.on("turn_start", (_event: unknown, ctx: ExtensionContext) =>
		beginTurn(ctx),
	);
	pi.on("message_update", (event: unknown, ctx: ExtensionContext) =>
		handleMessageUpdate(event, ctx),
	);
	pi.on("turn_end", (event: unknown, ctx: ExtensionContext) =>
		handleTurnEnd(event, ctx),
	);
	pi.on("tool_execution_start", (_event: unknown, ctx: ExtensionContext) =>
		handleToolStart(ctx),
	);
	pi.on("tool_execution_end", (_event: unknown, ctx: ExtensionContext) =>
		handleToolEnd(ctx),
	);
	pi.on("agent_end", () => finishRequest());
	pi.on("session_shutdown", () => {
		stopPlanModeTimer();
		activeTui = undefined;
		planModeActive = false;
		finishRequest();
	});
}

function gradientText(text: string, offset: number, baseColor: string): string {
	const colors = [baseColor, lighten(baseColor)];
	return [...text]
		.map((character, index) => {
			if (character === " ") return character;
			const color = colors[Math.floor((index + offset) / 3) % colors.length];
			return paint(color, character);
		})
		.join("");
}

function lighten(hex: string): string {
	const channels = rgb(hex).map((channel) =>
		Math.round(channel + (255 - channel) * 0.35),
	);
	return `#${channels.map((channel) => channel.toString(16).padStart(2, "0")).join("")}`;
}

function paint(hex: string, text: string): string {
	const [red, green, blue] = rgb(hex);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}

function rgb(hex: string): [number, number, number] {
	return [
		Number.parseInt(hex.slice(1, 3), 16),
		Number.parseInt(hex.slice(3, 5), 16),
		Number.parseInt(hex.slice(5, 7), 16),
	];
}
