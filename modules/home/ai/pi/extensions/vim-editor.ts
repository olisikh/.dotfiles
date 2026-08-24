// Owns the single prompt-editor slot for pi. Composes pi-vim's ModalEditor
// (imported from the pi-vim git package) with a double-Esc abort guard, so the
// two behaviors no longer fight over `ctx.ui.setEditorComponent`.
//
// pi-vim's package default export is a no-op by design; this local extension
// is the one place that calls setEditorComponent, keeping editor ownership in
// .dotfiles. pi-vim only contributes the ModalEditor factory + abort guard
// seam (`setAbortGuard`).
//
// The pi-vim import is resolved from $HOME (not a relative path) because under
// Nix this file is a symlink into the store, so a relative `../git/...` would
// resolve against the store path where the git clone does not exist.

/* @ts-expect-error Pi provides this module to extensions at runtime. */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
/* @ts-expect-error Pi provides this module to extensions at runtime. */
import { matchesKey, visibleWidth } from "@mariozechner/pi-tui";
import {
  createDoubleEscState,
  expireDoubleEsc,
  getDoubleEscDebounceMs,
  getHintPosition,
  pressEsc,
  pressOtherKey,
  type HintPosition,
} from "./lib/double-esc.ts";

const UPPER_STATUS_EVENT = "olisikh:upper-status-changed";

type PiVimEditor = {
  getMode?: () => string;
  setAbortGuard?: (fn: (() => boolean) | null) => void;
  render: (width: number) => string[];
  handleInput: (data: string) => void;
  borderColor: (text: string) => string;
};

type PiVimHandle = {
  factory: (tui: unknown, editorTheme: unknown, kb: unknown) => PiVimEditor;
  cleanup: (event?: { reason?: string }) => void;
};

function piVimCloneUrl(): string {
  const home = readEnvironment("HOME");
  if (!home?.startsWith("/")) {
    throw new Error("an absolute HOME is required to locate the pi-vim clone");
  }
  return `file://${`${home}/.pi/agent/git/github.com/olisikh/pi-vim/index.ts`
    .split("/")
    .map(encodeURIComponent)
    .join("/")}`;
}

function readEnvironment(name: string): string | undefined {
  const processLike = globalThis as typeof globalThis & {
    process?: { env?: Record<string, string | undefined> };
  };
  return processLike.process?.env?.[name];
}

type DoubleEscGuard = {
  guard: () => boolean;
  isHintActive: () => boolean;
  handleOtherKey: () => void;
};

function makeDoubleEscGuard(
  ctx: { isIdle?: () => boolean },
  requestRender: () => void,
): DoubleEscGuard {
  let state = createDoubleEscState();
  let timer: ReturnType<typeof setTimeout> | null = null;
  const clear = (): void => {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
  };
  const guard = (): boolean => {
    const result = pressEsc(state, ctx.isIdle?.() ?? true);
    state = result.state;
    if (result.action === "abort") {
      clear();
      return true;
    }
    if (result.action === "suppress") {
      clear();
      timer = setTimeout(() => {
        state = expireDoubleEsc(state).state;
        requestRender();
      }, getDoubleEscDebounceMs());
      requestRender();
      return false;
    }
    return true;
  };
  return {
    guard,
    isHintActive: () => state.hintActive,
    handleOtherKey: () => {
      if (!state.hintActive) return;
      state = pressOtherKey(state).state;
      clear();
      requestRender();
    },
  };
}

const HINT_LABEL = " esc again to abort ";
const HINT_LEFT_OFFSET = 2;

function dimHintLabel(theme: unknown, text: string): string {
  const t = theme as { fg?: (color: string, value: string) => string } | null;
  try {
    return t?.fg?.("dim", text) ?? `\x1b[2m${text}\x1b[22m`;
  } catch {
    return `\x1b[2m${text}\x1b[22m`;
  }
}

function stripModeLabel(
  line: string,
  width: number,
  border: (text: string) => string,
): string {
  const labelStart = line.lastIndexOf("\x1b[7m");
  if (labelStart < 0) return line;
  const content = line.slice(0, labelStart);
  return (
    content + border("─".repeat(Math.max(0, width - visibleWidth(content))))
  );
}

function renderHintLine(
  width: number,
  hintLabel: string,
  position: HintPosition,
  border: (text: string) => string,
): string {
  const borderFn = typeof border === "function" ? border : (t: string) => t;
  const hintWidth = visibleWidth(hintLabel);
  if (width <= hintWidth) return borderFn("─".repeat(width));
  const remaining = width - hintWidth;
  switch (position) {
    case "left": {
      const offset = Math.min(HINT_LEFT_OFFSET, remaining);
      return (
        borderFn("─".repeat(offset)) +
        hintLabel +
        borderFn("─".repeat(remaining - offset))
      );
    }
    case "right":
      return borderFn("─".repeat(remaining)) + hintLabel;
    case "center": {
      const left = Math.floor(remaining / 2);
      return (
        borderFn("─".repeat(left)) +
        hintLabel +
        borderFn("─".repeat(remaining - left))
      );
    }
  }
}

export default function (pi: ExtensionAPI) {
  let cleanup: ((event?: { reason?: string }) => void) | null = null;
  let modulePromise: Promise<{
    createPiVimEditorFactory: (pi: ExtensionAPI, ctx: unknown) => PiVimHandle;
  }> | null = null;

  const loadModule = async (): Promise<{
    createPiVimEditorFactory: (pi: ExtensionAPI, ctx: unknown) => PiVimHandle;
  }> => {
    if (!modulePromise) modulePromise = import(piVimCloneUrl());
    return modulePromise;
  };

  pi.on("session_start", async (_event: unknown, ctx: any) => {
    const mod = await loadModule();
    const handle = mod.createPiVimEditorFactory(pi, ctx);
    cleanup = handle.cleanup;
    let requestRender: (() => void) | null = null;
    const doubleEsc = makeDoubleEscGuard(ctx, () => requestRender?.());
    const hintLabel = dimHintLabel(ctx.ui?.theme, HINT_LABEL);
    const hintPosition = getHintPosition();
    ctx.ui.setEditorComponent(
      (tui: unknown, editorTheme: unknown, kb: unknown) => {
        const editor = handle.factory(tui, editorTheme, kb);
        requestRender = () =>
          (tui as { requestRender?: () => void }).requestRender?.();
        editor.setAbortGuard?.(doubleEsc.guard);
        pi.events.emit(UPPER_STATUS_EVENT, {
          version: 1,
          source: "vim",
          mode: editor.getMode?.() ?? "insert",
        });

        const render = editor.render.bind(editor);
        editor.render = (width: number) => {
          const lines = render(width);
          if (lines.length > 0) {
            const last = lines.length - 1;
            lines[last] = stripModeLabel(
              lines[last],
              width,
              editor.borderColor,
            );
          }
          if (doubleEsc.isHintActive() && lines.length > 0) {
            const last = lines.length - 1;
            lines[last] = renderHintLine(
              width,
              hintLabel,
              hintPosition,
              editor.borderColor,
            );
          }
          return lines;
        };

        const handleInput = editor.handleInput.bind(editor);
        editor.handleInput = (data: string) => {
          if (doubleEsc.isHintActive() && !matchesKey(data, "escape")) {
            doubleEsc.handleOtherKey();
          }
          handleInput(data);
          pi.events.emit(UPPER_STATUS_EVENT, {
            version: 1,
            source: "vim",
            mode: editor.getMode?.() ?? "insert",
          });
        };

        return editor;
      },
    );
  });

  pi.on("session_shutdown", (event: { reason?: string }) => {
    try {
      cleanup?.(event);
    } finally {
      cleanup = null;
    }
  });
}
