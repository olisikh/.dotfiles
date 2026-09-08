import { describe, expect, it, mock } from "bun:test";

mock.module("@earendil-works/pi-coding-agent", () => ({
  getAgentDir: () => "/tmp/pi-agent-tests",
}));
mock.module("typebox", () => ({
  Type: {
    Object: <T>(value: T) => value,
    String: (value?: unknown) => value,
    Optional: <T>(value: T) => value,
    Boolean: (value?: unknown) => value,
  },
}));

const { default: modes } = await import("./modes.ts");

type Handler = (event: unknown, ctx: Context) => unknown | Promise<unknown>;
type Command = { handler: (args: string, ctx: Context) => unknown };
type Context = {
  hasUI: boolean;
  ui: {
    notify: (message: string, type: string) => void;
    setStatus: (key: string, value: string | undefined) => void;
  };
  sessionManager: { getBranch: () => unknown[] };
};

function harness(restoredState?: unknown) {
  const handlers = new Map<string, Handler>();
  const commands = new Map<string, Command>();
  const tools = new Map<string, unknown>();
  let activeTools = ["read", "edit", "goal_complete"];
  const pi = {
    on: (name: string, handler: Handler) => handlers.set(name, handler),
    registerCommand: (name: string, command: Command) =>
      commands.set(name, command),
    registerTool: (tool: { name: string }) => tools.set(tool.name, tool),
    getActiveTools: () => [...activeTools],
    setActiveTools: (tools: string[]) => {
      activeTools = [...tools];
    },
    appendEntry: () => undefined,
    sendUserMessage: () => undefined,
    getCommands: () => [],
    events: { emit: () => undefined },
  };
  modes(pi as never);
  const ctx: Context = {
    hasUI: false,
    ui: { notify: () => undefined, setStatus: () => undefined },
    sessionManager: {
      getBranch: () =>
        restoredState === undefined
          ? []
          : [
              {
                type: "custom",
                customType: "olisikh:modes",
                data: restoredState,
              },
            ],
    },
  };
  return {
    activeTools: () => [...activeTools],
    runCommand: (name: string, args: string) =>
      commands.get(name)?.handler(args, ctx),
    sessionStart: () => handlers.get("session_start")?.({}, ctx),
    toolCall: () =>
      handlers.get("tool_call")?.({ toolName: "goal_complete" }, ctx),
  };
}

describe("goal_complete mode guard", () => {
  it("removes the tool and blocks calls in Build mode", async () => {
    const h = harness();
    await h.sessionStart();

    expect(h.activeTools()).not.toContain("goal_complete");
    expect(h.toolCall()).toEqual({
      block: true,
      reason: "goal_complete is only available while a goal is active.",
    });
  });

  it("activates the tool only while a Goal is active", async () => {
    const h = harness();
    await h.sessionStart();

    await h.runCommand("goal", "finish the release");
    expect(h.activeTools()).toContain("goal_complete");

    await h.runCommand("goal", "clear");
    expect(h.activeTools()).not.toContain("goal_complete");
  });

  for (const [name, state, active] of [
    ["Build", { version: 1, mode: "build" }, false],
    ["Plan", { version: 1, mode: "plan", plan: { objective: "plan" } }, false],
    [
      "Goal",
      {
        version: 1,
        mode: "goal",
        goal: { objective: "ship", runs: 0, paused: false },
      },
      true,
    ],
  ] as const) {
    it(`restores ${name} mode with goal_complete ${active ? "enabled" : "disabled"}`, async () => {
      const h = harness(state);
      await h.sessionStart();
      expect(h.activeTools().includes("goal_complete")).toBe(active);
    });
  }
});
