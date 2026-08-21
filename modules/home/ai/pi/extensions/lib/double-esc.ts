/**
 * Double-Esc abort guard — pure state machine ported from the pi-double-esc
 * fork so the .dotfiles-owned prompt editor can debounce Escape aborts without
 * a separate editor extension competing for the single editor slot.
 *
 * Contract: the host editor calls `pressEsc()` on every Normal-mode Esc aimed
 * at aborting the agent. It returns:
 *   - "abort"     -> proceed with the abort (idle, or second press in window)
 *   - "suppress"  -> swallow the Esc, show a hint, wait for a second press
 *   - "timeout"   -> the debounce window expired; hint clears (state reset)
 */

export interface DoubleEscState {
 /** First escape pressed, awaiting confirmation. */
 hintActive: boolean;
 /** Escapes in the current debounce window. */
 escapeCount: number;
}

export type DoubleEscAction = "abort" | "suppress" | "timeout";

export type HintPosition = "left" | "center" | "right";

const DEFAULT_DEBOUNCE_MS = 1500;
const DEFAULT_HINT_POSITION: HintPosition = "left";

function readEnvironment(name: string): string | undefined {
 const processLike = globalThis as typeof globalThis & {
  process?: { env?: Record<string, string | undefined> };
 };
 return processLike.process?.env?.[name];
}

export function getDoubleEscDebounceMs(): number {
 const env = readEnvironment("PI_DOUBLE_ESC_MS");
 if (env) {
  const parsed = parseInt(env, 10);
  if (!Number.isNaN(parsed) && parsed > 0) return parsed;
 }
 return DEFAULT_DEBOUNCE_MS;
}

/** Where the "esc again to abort" hint sits in the editor border. */
export function getHintPosition(): HintPosition {
 const position = readEnvironment("PI_DOUBLE_ESC_HINT_POSITION")
  ?.trim()
  .toLowerCase();
 if (position === "left" || position === "center" || position === "right") {
  return position;
 }
 return DEFAULT_HINT_POSITION;
}

export function createDoubleEscState(): DoubleEscState {
 return { hintActive: false, escapeCount: 0 };
}

/**
 * Advance the state machine on an Esc press. `isIdle` is the host's "agent not
 * streaming" signal; when idle the guard never debounces — one Esc aborts.
 */
export function pressEsc(
 state: DoubleEscState,
 isIdle: boolean,
): { state: DoubleEscState; action: DoubleEscAction } {
 if (isIdle && !state.hintActive) {
  return { state, action: "abort" };
 }
 const count = state.escapeCount + 1;
 if (count === 1) {
  return { state: { hintActive: true, escapeCount: 1 }, action: "suppress" };
 }
 return { state: { hintActive: false, escapeCount: 0 }, action: "abort" };
}

/** Non-Esc key while a hint is showing: clear the hint and reset. */
export function pressOtherKey(state: DoubleEscState): {
 state: DoubleEscState;
 action: "abort";
} {
 if (!state.hintActive) return { state, action: "abort" };
 return { state: { hintActive: false, escapeCount: 0 }, action: "abort" };
}

/** Debounce window expired: clear the hint and reset. */
export function expireDoubleEsc(state: DoubleEscState): {
 state: DoubleEscState;
 action: "timeout";
} {
 if (!state.hintActive) return { state, action: "timeout" };
 return { state: { hintActive: false, escapeCount: 0 }, action: "timeout" };
}
