/* @ts-expect-error Pi provides this module at runtime. */
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const FRAME_INTERVAL_MS = 120;
const PHRASE_INTERVAL_MS = 2_400;
const COLOR_INTERVAL_MS = 2_500;
const STALL_TIMEOUT_MS = 3_000;
const CHARS_PER_TOKEN = 4;
const COLORS = ["#cba6f7", "#a66bd8"];
const STALLED_COLOR = "#f38ba8";
const INPUT_ARROW = "↑";
const OUTPUT_ARROW = "↓";
const PHRASES = [
	"Bamboozling...",
	"Contemplating the orb...",
	"Wrestling the electrons...",
	"Consulting the vibes...",
	"Untangling spaghetti...",
	"Convincing the pixels...",
	"Polishing the goblins...",
	"Performing tasteful wizardry...",
];

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
type Phase = "requesting" | "thinking" | "responding" | "tool-use";

type WorkingState = {
	phrase: string;
	phase: Phase;
	startedAt: number;
	thinkingStartedAt?: number;
	streamedChars: number;
	inputTokens: number;
	outputTokens: number;
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

function formatOutputEstimate(streamedChars: number): string {
	const tokens = Math.max(1, Math.round(streamedChars / CHARS_PER_TOKEN));
	return `${OUTPUT_ARROW} ~${formatCount(tokens)} tokens`;
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

function buildWorkingMessage(
	state: WorkingState,
	now: number,
	gradientOffset: number,
): string {
	const stalled = isStalled(state, now);
	const details = [formatDuration(now - state.startedAt)];

	if (state.inputTokens > 0) {
		details.push(`${INPUT_ARROW} ${formatCount(state.inputTokens)} tokens`);
	}
	if (state.outputTokens > 0) {
		details.push(`${OUTPUT_ARROW} ${formatCount(state.outputTokens)} tokens`);
	} else if (state.streamedChars > 0) {
		details.push(formatOutputEstimate(state.streamedChars));
	}

	if (state.phase === "thinking") {
		const thinkingDuration =
			state.thinkingStartedAt === undefined
				? ""
				: ` ${formatDuration(now - state.thinkingStartedAt)}`;
		details.push(`thinking${thinkingDuration}`);
	} else if (state.phase === "tool-use") {
		details.push(
			state.activeTools > 0 ? `tools (${state.activeTools})` : "tools",
		);
	} else {
		details.push(state.phase);
	}

	if (stalled) {
		details.push("stalled");
	}

	const phrase = stalled
		? paint(STALLED_COLOR, state.phrase)
		: gradientText(state.phrase, gradientOffset);
	return `${phrase} · ${details.join(" · ")}`;
}

export default function (pi: ExtensionAPI) {
	let previousPhrase: string | undefined;
	let activeContext: ExtensionContext | undefined;
	let state: WorkingState | undefined;
	let refreshTimer: ReturnType<typeof setInterval> | undefined;
	let phraseTimer: ReturnType<typeof setInterval> | undefined;
	let colorTimer: ReturnType<typeof setInterval> | undefined;
	let gradientTimer: ReturnType<typeof setInterval> | undefined;
	let colorIndex = 0;
	let gradientOffset = 0;

	const render = () => {
		if (!state || !activeContext) return;
		activeContext.ui.setWorkingMessage(
			buildWorkingMessage(state, Date.now(), gradientOffset),
		);
	};

	const stopRefreshTimer = () => {
		if (refreshTimer) clearInterval(refreshTimer);
		refreshTimer = undefined;
	};

	const applyIndicatorStyle = () => {
		if (!activeContext) return;
		activeContext.ui.setWorkingIndicator({
			frames: SPINNER.map((glyph) => paint(COLORS[colorIndex], glyph)),
			intervalMs: FRAME_INTERVAL_MS,
		});
	};

	const stopAnimationTimers = () => {
		if (phraseTimer) clearInterval(phraseTimer);
		if (colorTimer) clearInterval(colorTimer);
		if (gradientTimer) clearInterval(gradientTimer);
		phraseTimer = undefined;
		colorTimer = undefined;
		gradientTimer = undefined;
	};

	const startAnimationTimers = () => {
		stopAnimationTimers();
		gradientOffset = 0;
		gradientTimer = setInterval(() => {
			gradientOffset = (gradientOffset + 1) % (COLORS.length * 4);
			render();
		}, FRAME_INTERVAL_MS);
		phraseTimer = setInterval(() => {
			if (!state) return;
			state.phrase = randomPhrase(state.phrase);
			render();
		}, PHRASE_INTERVAL_MS);
		colorTimer = setInterval(() => {
			colorIndex = (colorIndex + 1) % COLORS.length;
			applyIndicatorStyle();
			render();
		}, COLOR_INTERVAL_MS);
	};

	const startRefreshTimer = () => {
		stopRefreshTimer();
		refreshTimer = setInterval(render, FRAME_INTERVAL_MS);
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
			outputTokens: 0,
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
		state = undefined;
		activeContext = ctx;
		colorIndex = 0;
		gradientOffset = 0;
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
	pi.on("session_shutdown", () => finishRequest());
}

function gradientText(text: string, offset: number): string {
	return [...text]
		.map((character, index) => {
			if (character === " ") return character;
			const color = COLORS[Math.floor((index + offset) / 3) % COLORS.length];
			return paint(color, character);
		})
		.join("");
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
