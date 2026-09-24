/* @ts-expect-error Bun supplies this module while running tests. */
import { beforeEach, describe, expect, it, mock } from "bun:test";

let configJson = JSON.stringify({
  defaultModel: "openai-codex/gpt-6-luna",
  fallbackModels: ["openai-codex/gpt-6-sol"],
});

mock.module("@earendil-works/pi-ai", () => ({ uuidv7: () => "test-session" }));
mock.module("@earendil-works/pi-coding-agent", () => ({
  getAgentDir: () => "/tmp/pi-agent",
  convertToLlm: (messages: Array<{ content: string }>) => messages,
  serializeConversation: (messages: Array<{ content: string }>) =>
    messages.map(({ content }) => content).join("\n\n"),
}));
mock.module("node:fs/promises", () => ({ readFile: async () => configJson }));

const { configuredModelReferences, default: compactionModelRouting } =
  await import("./compaction-model-routing.ts");

function installHandler() {
  let handler: ((event: any, ctx: any) => Promise<unknown>) | undefined;
  compactionModelRouting({
    on: (
      _name: string,
      callback: (event: any, ctx: any) => Promise<unknown>,
    ) => {
      handler = callback;
    },
  } as never);
  return () => handler!;
}

function compactionEvent() {
  return {
    preparation: {
      messagesToSummarize: [{ content: "Earlier context" }],
      turnPrefixMessages: [],
      previousSummary: undefined,
      firstKeptEntryId: "keep-from-here",
      retainedTail: [{ content: "Current request" }],
      tokensBefore: 123_456,
      settings: { reserveTokens: 10_000 },
    },
    signal: new AbortController().signal,
  };
}

describe("compactionModelRouting", () => {
  beforeEach(() => {
    configJson = JSON.stringify({
      defaultModel: "openai-codex/gpt-6-luna",
      fallbackModels: ["openai-codex/gpt-6-sol"],
    });
  });

  it("normalizes a default and ordered unique fallback list", () => {
    expect(
      configuredModelReferences({
        defaultModel: "openai-codex/gpt-6-luna",
        fallbackModels: [
          "invalid",
          "openai-codex/gpt-6-luna",
          "openai-codex/gpt-6-sol",
        ],
      }),
    ).toEqual([
      {
        provider: "openai-codex",
        id: "gpt-6-luna",
        display: "openai-codex/gpt-6-luna",
      },
      {
        provider: "openai-codex",
        id: "gpt-6-sol",
        display: "openai-codex/gpt-6-sol",
      },
    ]);
  });

  it("uses the next configured model when the default candidate fails", async () => {
    const handler = installHandler();
    const found: string[] = [];
    const completed: string[] = [];

    const result = await handler()(compactionEvent(), {
      modelRegistry: {
        find: (_provider: string, id: string) => {
          found.push(id);
          return { id, maxTokens: 8_192 };
        },
        complete: async (model: { id: string }) => {
          completed.push(model.id);
          if (model.id === "gpt-6-luna") throw new Error("Luna unavailable");
          return {
            content: [{ type: "text", text: "## Goal\nContinue safely." }],
            usage: { input: 10, output: 2, totalTokens: 12 },
          };
        },
      },
      ui: { notify: () => {} },
    });

    expect(found).toEqual(["gpt-6-luna", "gpt-6-sol"]);
    expect(completed).toEqual(["gpt-6-luna", "gpt-6-sol"]);
    expect(result).toEqual({
      compaction: {
        summary: "## Goal\nContinue safely.",
        firstKeptEntryId: "keep-from-here",
        retainedTail: [{ content: "Current request" }],
        tokensBefore: 123_456,
        usage: { input: 10, output: 2, totalTokens: 12 },
      },
    });
  });

  it("delegates to Pi's active session model after every configured candidate fails", async () => {
    const handler = installHandler();
    const notifications: string[] = [];

    const result = await handler()(compactionEvent(), {
      modelRegistry: {
        find: (_provider: string, id: string) => ({ id, maxTokens: 8_192 }),
        complete: async () => {
          throw new Error("provider unavailable");
        },
      },
      ui: { notify: (message: string) => notifications.push(message) },
    });

    expect(result).toBeUndefined();
    expect(notifications).toEqual([
      "Configured compaction models were unavailable or failed; using the active session model.",
    ]);
  });
});
