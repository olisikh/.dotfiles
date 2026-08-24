import type {
  ExtensionAPI,
  ExtensionContext,
  // @ts-expect-error Pi provides this module at runtime.
} from "@mariozechner/pi-coding-agent";

const DEFAULT_SHIMMER_INTERVAL_MS = 120;
const DEFAULT_SPINNER_INTERVAL_MS = 120;
const TOKEN_COUNTER_INTERVAL_MS = 50;
const TOKEN_COUNTER_ANIMATION_MS = 3_000;
const TOKEN_DELTA_VISIBLE_MS = TOKEN_COUNTER_ANIMATION_MS + 1_000;
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
  "Asking Calcifer...",
  "Asking your mom...",
  "Asking your dad...",
  "Checking your horoscope...",
  "Blessing the code...",
  "Kissing the frog...",
];

const SHIMMER_FRAMES = ["·", "✢", "✳", "✶", "✻", "✽", "✻", "✶", "✳", "✢"];
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const GRADIENT_STEP = 3;
const GRADIENT_CYCLE_LENGTH = 8;
const RAINBOW_CYCLE_LENGTH = CATPPUCCIN_COLORS.length * GRADIENT_STEP;
type IndicatorType = "shimmer" | "spinner";
type ColorMode = "none" | "rotate" | "rainbow";
type Phase = "requesting" | "thinking" | "responding" | "tool-use";

type CounterAnimation = {
  target: number;
  startValue: number;
  startedAt: number;
};

type WorkingState = {
  phrase: string;
  phase: Phase;
  startedAt: number;
  thinkingStartedAt?: number;
  streamedChars: number;
  inputTokens: number;
  inputTokenDelta: number;
  inputTokenDeltaExpiresAt: number;
  displayedInputTokens: number;
  inputAnimation: CounterAnimation;
  outputTokens: number;
  outputTokenDelta: number;
  outputTokenDeltaExpiresAt: number;
  displayedOutputChars: number;
  outputAnimation: CounterAnimation;
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

function readColorMode(value: string | undefined): ColorMode {
  switch (value?.trim().toLowerCase()) {
    case "rotate":
    case "rotation":
    case "1":
    case "true":
      return "rotate";
    case "rainbow":
      return "rainbow";
    default:
      return "none";
  }
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
const COLOR_MODE = readColorMode(
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

function formatTokenLine(arrow: string, tokens: number, delta = 0): string {
  const formattedDelta = delta > 0 ? ` +${formatCount(delta)}` : "";
  return `${arrow} ${formatCount(tokens)}${formattedDelta}`;
}

function advanceCounter(
  current: number,
  target: number,
  animation: CounterAnimation,
  now: number,
): number {
  if (current >= target) return current;
  if (animation.target !== target) {
    animation.target = target;
    animation.startValue = current;
    animation.startedAt = now;
  }

  const progress = Math.min(
    1,
    (now - animation.startedAt) / TOKEN_COUNTER_ANIMATION_MS,
  );
  return progress >= 1
    ? target
    : animation.startValue + (target - animation.startValue) * progress;
}

function advanceTokenCounters(state: WorkingState, now: number): boolean {
  const outputTarget = Math.max(
    state.streamedChars,
    state.outputTokens * CHARS_PER_TOKEN,
  );
  const nextInput = advanceCounter(
    state.displayedInputTokens,
    state.inputTokens,
    state.inputAnimation,
    now,
  );
  const nextOutput = advanceCounter(
    state.displayedOutputChars,
    outputTarget,
    state.outputAnimation,
    now,
  );
  const changed =
    nextInput !== state.displayedInputTokens ||
    nextOutput !== state.displayedOutputChars;
  state.displayedInputTokens = nextInput;
  state.displayedOutputChars = nextOutput;
  return changed;
}

function recordUsage(state: WorkingState, message: unknown, now: number): void {
  if (!isRecord(message) || !isRecord(message.usage)) return;

  const input = Number(message.usage.input ?? message.usage.inputTokens);
  if (Number.isFinite(input) && input > 0) {
    state.inputTokens += input;
    state.inputTokenDelta = input;
    state.inputTokenDeltaExpiresAt = now + TOKEN_DELTA_VISIBLE_MS;
  }

  const output = Number(message.usage.output ?? message.usage.outputTokens);
  if (Number.isFinite(output) && output > 0) {
    state.outputTokens += output;
    state.outputTokenDelta = output;
    state.outputTokenDeltaExpiresAt = now + TOKEN_DELTA_VISIBLE_MS;
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
  activeColor: string,
  colorMode: ColorMode,
): string {
  const stalled = isStalled(state, now);
  const details = [`${TIMER_ICON} ${formatDuration(now - state.startedAt)}`];

  const inputTokens = Math.round(state.displayedInputTokens);
  if (inputTokens > 0) {
    const inputDelta =
      now < state.inputTokenDeltaExpiresAt ? state.inputTokenDelta : 0;
    details.push(formatTokenLine(INPUT_ARROW, inputTokens, inputDelta));
  }

  const outputTokens = Math.round(state.displayedOutputChars / CHARS_PER_TOKEN);
  if (outputTokens > 0) {
    const outputDelta =
      now < state.outputTokenDeltaExpiresAt ? state.outputTokenDelta : 0;
    details.push(formatTokenLine(OUTPUT_ARROW, outputTokens, outputDelta));
  }

  if (stalled) {
    details.push("stalled");
  }

  const phrase = stalled
    ? paint(STALLED_COLOR, state.phrase)
    : gradientText(state.phrase, gradientOffset, activeColor, colorMode);
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
  let dialogDepth = 0;
  let workingHiddenForDialog = false;

  const render = () => {
    if (!state || !activeContext) return;
    activeContext.ui.setWorkingMessage(
      buildWorkingMessage(
        state,
        Date.now(),
        gradientOffset,
        activeColor,
        COLOR_MODE,
      ),
    );
  };

  const stopRefreshTimer = () => {
    if (refreshTimer) clearInterval(refreshTimer);
    refreshTimer = undefined;
  };

  const applyIndicatorStyle = () => {
    if (!activeContext) return;
    const frames =
      INDICATOR_TYPE === "shimmer" ? SHIMMER_FRAMES : SPINNER_FRAMES;
    const indicatorFrames =
      COLOR_MODE === "rainbow"
        ? Array.from(
            { length: frames.length * RAINBOW_CYCLE_LENGTH },
            (_, index) =>
              paint(
                paletteColor(CATPPUCCIN_COLORS, index % RAINBOW_CYCLE_LENGTH),
                frames[index % frames.length] ?? "",
              ),
          )
        : frames.map((glyph) => paint(activeColor, glyph));
    activeContext.ui.setWorkingIndicator({
      frames: indicatorFrames,
      intervalMs:
        INDICATOR_TYPE === "shimmer"
          ? SHIMMER_INTERVAL_MS
          : SPINNER_INTERVAL_MS,
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
      if (state && advanceTokenCounters(state, Date.now())) render();
    }, TOKEN_COUNTER_INTERVAL_MS);
    gradientTimer = setInterval(() => {
      const cycleLength =
        COLOR_MODE === "rainbow" ? RAINBOW_CYCLE_LENGTH : GRADIENT_CYCLE_LENGTH;
      gradientOffset = (gradientOffset + 1) % cycleLength;
      render();
    }, SHIMMER_INTERVAL_MS);
    phraseTimer = setInterval(() => {
      if (!state) return;
      state.phrase = randomPhrase(state.phrase);
      render();
    }, PHRASE_INTERVAL_MS);
    if (COLOR_MODE === "rotate") {
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

  const enterDialog = () => {
    dialogDepth += 1;
    if (dialogDepth === 1 && state && activeContext) {
      workingHiddenForDialog = true;
      activeContext.ui.setWorkingVisible(false);
    }
  };

  const exitDialog = () => {
    dialogDepth = Math.max(0, dialogDepth - 1);
    if (dialogDepth !== 0 || !workingHiddenForDialog) return;

    workingHiddenForDialog = false;
    if (!activeContext) return;
    activeContext.ui.setWorkingVisible(true);
    applyIndicatorStyle();
    render();
  };

  const duringDialog = async <T>(operation: () => Promise<T>): Promise<T> => {
    enterDialog();
    try {
      return await operation();
    } finally {
      exitDialog();
    }
  };

  const wrapDialogUi = (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;

    const ui = ctx.ui;
    const select = ui.select.bind(ui);
    const confirm = ui.confirm.bind(ui);
    const input = ui.input.bind(ui);
    const editor = ui.editor.bind(ui);
    const custom = ui.custom.bind(ui);

    ui.select = ((...args: Parameters<typeof ui.select>) =>
      duringDialog(() => select(...args))) as typeof ui.select;
    ui.confirm = ((...args: Parameters<typeof ui.confirm>) =>
      duringDialog(() => confirm(...args))) as typeof ui.confirm;
    ui.input = ((...args: Parameters<typeof ui.input>) =>
      duringDialog(() => input(...args))) as typeof ui.input;
    ui.editor = ((...args: Parameters<typeof ui.editor>) =>
      duringDialog(() => editor(...args))) as typeof ui.editor;
    ui.custom = ((...args: Parameters<typeof ui.custom>) =>
      duringDialog(() => custom(...args))) as typeof ui.custom;
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
      inputTokenDelta: 0,
      inputTokenDeltaExpiresAt: 0,
      displayedInputTokens: 0,
      inputAnimation: { target: 0, startValue: 0, startedAt: 0 },
      outputTokens: 0,
      outputTokenDelta: 0,
      outputTokenDeltaExpiresAt: 0,
      displayedOutputChars: 0,
      outputAnimation: { target: 0, startValue: 0, startedAt: 0 },
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
        const missing = Math.max(
          0,
          finalTextLength - state.currentTextBlockChars,
        );
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
        const missing = Math.max(
          0,
          finalTextLength - state.currentAssistantChars,
        );
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
    recordUsage(state, event.message, Date.now());
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
    dialogDepth = 0;
    workingHiddenForDialog = false;
    wrapDialogUi(ctx);
    colorIndex = 0;
    activeColor = DEFAULT_COLOR_VALUE;
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

function gradientText(
  text: string,
  offset: number,
  baseColor: string,
  colorMode: ColorMode,
): string {
  const colors = [baseColor, lighten(baseColor)];
  return [...text]
    .map((character, index) => {
      if (character === " ") return character;
      const color =
        colorMode === "rainbow"
          ? paletteColor(CATPPUCCIN_COLORS, index + offset)
          : colors[
              Math.floor((index + offset) / GRADIENT_STEP) % colors.length
            ];
      return paint(color, character);
    })
    .join("");
}

function paletteColor(colors: readonly string[], position: number): string {
  const palettePosition = position / GRADIENT_STEP;
  const index = Math.floor(palettePosition) % colors.length;
  const progress = palettePosition - Math.floor(palettePosition);
  return blend(colors[index], colors[(index + 1) % colors.length], progress);
}

function blend(first: string, second: string, progress: number): string {
  const firstRgb = rgb(first);
  const secondRgb = rgb(second);
  return `#${firstRgb
    .map((channel, index) =>
      Math.round(channel + (secondRgb[index] - channel) * progress)
        .toString(16)
        .padStart(2, "0"),
    )
    .join("")}`;
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
