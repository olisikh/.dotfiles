import { describe, expect, it, mock } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const ctxRepoRoot = resolve(import.meta.dir, "../../../../..");

let agentDir = "/tmp/pi-agent-tests";
mock.module("@earendil-works/pi-coding-agent", () => ({
  getAgentDir: () => agentDir,
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

type Handler = (event: any, ctx: Context) => any;
type Context = {
  hasUI: boolean;
  cwd: string;
  ui: {
    notify: (message: string, type: string) => void;
    setStatus: (key: string, value: string | undefined) => void;
    select: (title: string, options: string[]) => Promise<string | undefined>;
    input: (title: string, placeholder: string) => Promise<string | undefined>;
  };
  sessionManager: { getBranch: () => any[] };
};

function harness(options: {
  restoredState?: unknown;
  hasUI?: boolean;
  choices?: (string | undefined)[];
  answers?: (string | undefined)[];
  tools?: string[];
} = {}) {
  const handlers = new Map<string, Handler>();
  const commands = new Map<string, { handler: Handler }>();
  const tools = new Map<string, { execute: Handler }>();
  const sent: string[] = [];
  const notices: string[] = [];
  const persisted: unknown[] = [];
  const choices = [...(options.choices ?? [])];
  const answers = [...(options.answers ?? [])];
  const branch: any[] = options.restoredState === undefined ? [] : [{ type: "custom", customType: "olisikh:modes", data: options.restoredState }];
  let activeTools = options.tools ?? ["read", "grep", "edit", "goal_complete", "plan_ready"];
  const pi = {
    on: (name: string, handler: Handler) => handlers.set(name, handler),
    registerCommand: (name: string, command: { handler: Handler }) => commands.set(name, command),
    registerTool: (tool: { name: string; execute: Handler }) => tools.set(tool.name, tool),
    getActiveTools: () => [...activeTools],
    setActiveTools: (names: string[]) => { activeTools = [...names]; },
    appendEntry: (_name: string, data: unknown) => { persisted.push(data); },
    sendUserMessage: (text: string) => { sent.push(text); },
    events: { emit: () => undefined },
  };
  modes(pi as never);
  const ctx: Context = {
    cwd: ctxRepoRoot,
    hasUI: options.hasUI ?? false,
    ui: {
      notify: (text) => { notices.push(text); },
      setStatus: () => undefined,
      select: async () => choices.shift(),
      input: async () => answers.shift(),
    },
    sessionManager: { getBranch: () => branch },
  };
  return {
    activeTools: () => [...activeTools],
    sent,
    notices,
    persisted,
    branch,
    runCommand: (name: string, args: string) => commands.get(name)?.handler(args, ctx),
    sessionStart: () => handlers.get("session_start")?.({}, ctx),
    toolCall: (name: string, input: Record<string, unknown> = {}) => handlers.get("tool_call")?.({ toolName: name, input }, ctx),
    toolResult: (name: string, content: string, input: Record<string, unknown> = {}) => handlers.get("tool_result")?.({ toolName: name, input, content: [{ type: "text", text: content }] }, ctx),
    input: (text: string, source = "interactive") => handlers.get("input")?.({ text, source }, ctx),
    context: (messages: any[]) => handlers.get("context")?.({ messages }, ctx),
    beforeAgent: () => handlers.get("before_agent_start")?.({ systemPrompt: "base" }, ctx),
    settled: () => handlers.get("agent_settled")?.({}, ctx),
    execute: (name: string, params: Record<string, unknown>, visibleText?: string) => {
      if (name === "plan_ready") {
        const text = visibleText ?? params.plan;
        branch.push({ type: "message", message: { role: "assistant", stopReason: "toolUse", content: typeof text === "string" ? [{ type: "text", text }] : [] } });
      }
      return tools.get(name)?.execute("id", params, undefined, undefined, ctx);
    },
  };
}

const plan = "## Implementation plan\n\n1. Change the first behavior and validate the result.\n2. Change the second behavior and check all affected modes.\n3. Run focused tests and inspect the final configuration.";

describe("mode-scoped tools and instructions", () => {
  it("hides plan_ready and blocks the reported prompt read and call in Build", async () => {
    const h = harness();
    await h.sessionStart();
    expect(h.activeTools()).not.toContain("plan_ready");
    expect(h.toolCall("plan_ready")).toMatchObject({ block: true });
    expect(h.toolCall("read", { path: "modules/home/ai/pi/prompts/plan-mode.md" })).toMatchObject({ block: true });
    expect(h.beforeAgent()).toBeUndefined();
  });

  it("allows plan_ready only in Plan, including on restored sessions", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    expect(h.activeTools()).toContain("plan_ready");
    expect(h.activeTools()).not.toContain("edit");
    h.branch.push({ type: "message", message: { role: "assistant", stopReason: "toolUse", content: [{ type: "text", text: plan }] } });
    expect(h.toolCall("plan_ready", { plan })).toBeUndefined();
    expect(h.sent[0]).not.toContain("<personal_plan_instructions>");
    await h.runCommand("build", "");
    expect(h.activeTools()).not.toContain("plan_ready");
    expect(h.activeTools()).toContain("edit");
    const restored = harness({ restoredState: { version: 1, mode: "plan", plan: { objective: "restore", instructions: "RESTORED PLAN INSTRUCTIONS" } } });
    await restored.sessionStart();
    expect(restored.activeTools()).toContain("plan_ready");
    expect(restored.beforeAgent()?.systemPrompt).toContain("RESTORED PLAN INSTRUCTIONS");
  });

  it("loads the prompt only on user /plan, persists it for resume, and drops it in Build", async () => {
    const dir = mkdtempSync(join(tmpdir(), "pi-plan-test-"));
    agentDir = dir;
    try {
      mkdirSync(join(dir, "modes"));
      writeFileSync(join(dir, "modes", "plan.md"), "USER-OWNED PLAN RULE");
      const h = harness();
      await h.sessionStart();
      expect(h.beforeAgent()).toBeUndefined();
      await h.runCommand("plan", "change something");
      expect(h.beforeAgent()?.systemPrompt).toContain("USER-OWNED PLAN RULE");
      const saved = h.persisted.at(-1);
      await h.runCommand("build", "");
      expect(h.beforeAgent()).toBeUndefined();
      rmSync(join(dir, "modes", "plan.md"));
      const restored = harness({ restoredState: saved });
      await restored.sessionStart();
      expect(restored.beforeAgent()?.systemPrompt).toContain("USER-OWNED PLAN RULE");
    } finally {
      agentDir = "/tmp/pi-agent-tests";
      rmSync(dir, { recursive: true, force: true });
    }
  });

  it("keeps goal_complete scoped to Goal", async () => {
    const h = harness();
    await h.sessionStart();
    expect(h.activeTools()).not.toContain("goal_complete");
    expect(h.toolCall("goal_complete")).toMatchObject({ block: true });
    await h.runCommand("goal", "finish release");
    expect(h.activeTools()).toContain("goal_complete");
    expect(h.activeTools()).not.toContain("plan_ready");
    await h.runCommand("goal", "clear");
    expect(h.activeTools()).not.toContain("goal_complete");
  });

  it("drops legacy injected plan instructions from Build context", async () => {
    const h = harness();
    await h.sessionStart();
    const messages = [
      { role: "user", content: "Plan this work without modifying files: task\n\n<personal_plan_instructions>\nPRIVATE\n</personal_plan_instructions>" },
      { role: "user", content: "An unrelated user message" },
    ];
    const filtered = h.context(messages)?.messages;
    expect(filtered[0].content).toBe("Plan this work without modifying files: task");
    expect(filtered[1]).toEqual(messages[1]);
  });

  it("guards direct and search-tool exposures even in Plan", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "examine code");
    expect(h.toolCall("read", { path: "/tmp/pi-agent-tests/modes/plan.md" })).toMatchObject({ block: true });
    expect(h.toolCall("read", { path: "~/.dotfiles/modules/home/ai/pi/prompts/plan-mode.md" })).toMatchObject({ block: true });
    expect(h.toolCall("bash", { command: "cat modules/home/ai/pi/prompts/plan-mode.md" })).toMatchObject({ block: true });
    const dir = mkdtempSync(join(tmpdir(), "pi-plan-alias-"));
    try {
      const alias = join(dir, "alias.md");
      symlinkSync(join(ctxRepoRoot, "modules/home/ai/pi/prompts/plan-mode.md"), alias);
      expect(h.toolCall("read", { path: alias })).toMatchObject({ block: true });
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
    expect(h.toolCall("grep", { pattern: "plan", path: "modules/home/ai/pi/prompts/plan-mode.md" })).toMatchObject({ block: true });
    expect(h.toolResult("grep", "modules/home/ai/pi/prompts/plan-mode.md:1: PRIVATE")?.content[0].text).not.toContain("PRIVATE");
    expect(h.toolResult("grep", "> modules/home/ai/pi/prompts/plan-mode.md\n  1: PRIVATE")?.content[0].text).not.toContain("PRIVATE");
    expect(h.toolResult("grep", "> plan-mode.md\n  1: PRIVATE")?.content[0].text).not.toContain("PRIVATE");
    expect(h.toolResult("grep", "PRIVATE", { path: ctxRepoRoot })?.content[0].text).not.toContain("PRIVATE");
    expect(h.toolResult("grep", "other.ts:1: harmless", { path: ctxRepoRoot })).toBeUndefined();
    expect(h.toolResult("read", "This code refers to modules/home/ai/pi/prompts/plan-mode.md")).toBeUndefined();
  });

  for (const [name, restoredState, enabled] of [
    ["Build", { version: 1, mode: "build" }, false],
    ["Plan", { version: 1, mode: "plan", plan: { objective: "work" } }, true],
    ["Goal", { version: 1, mode: "goal", goal: { objective: "ship", runs: 0, paused: false } }, false],
  ] as const) {
    it(`restores ${name} with plan_ready ${enabled ? "enabled" : "disabled"}`, async () => {
      const h = harness({ restoredState });
      await h.sessionStart();
      expect(h.activeTools().includes("plan_ready")).toBe(enabled);
    });
  }
});

describe("plan approval", () => {
  it("rejects tool-only plan_ready before opening the approval dialog", async () => {
    const h = harness({ hasUI: true, choices: ["Implement"] });
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    h.branch.push({ type: "message", message: { role: "assistant", stopReason: "toolUse", content: [{ type: "toolCall", name: "plan_ready" }] } });
    expect(h.toolCall("plan_ready", { plan })).toMatchObject({ block: true });
    await expect(h.execute("plan_ready", { plan }, "Tool only; no visible plan.")).rejects.toThrow("Present the complete plan");
    expect(h.activeTools()).toContain("plan_ready");
    expect(h.sent).toHaveLength(1);
  });

  it("shows approval when the agent finishes a visible plan without plan_ready", async () => {
    const h = harness({ hasUI: true, choices: ["Implement"] });
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    h.branch.push({ type: "message", message: { role: "assistant", stopReason: "stop", content: [{ type: "text", text: plan }] } });
    await h.settled();
    expect(h.activeTools()).not.toContain("plan_ready");
    expect(h.sent.at(-1)).toContain(`Implement this approved plan now:\n\n${plan}`);
  });

  it("does not approve a clarification question", async () => {
    const h = harness({ hasUI: true, choices: ["Implement"] });
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    h.branch.push({ type: "message", message: { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "Which host should this change affect?" }] } });
    await h.settled();
    expect(h.activeTools()).toContain("plan_ready");
    expect(h.sent).toHaveLength(1);
  });

  it("implements a saved plan on explicit ordinary user approval", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    expect(h.input("implement it")).toEqual({ action: "handled" });
    expect(h.sent.at(-1)).toContain(plan);
    expect(h.activeTools()).not.toContain("plan_ready");
  });

  it("does not accept ambiguous, conditional, or extension-injected approval", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    expect(h.input("looks interesting")).not.toEqual({ action: "handled" });
    expect(h.input("implement only after I check it")).not.toEqual({ action: "handled" });
    expect(h.input("don't implement yet")).not.toEqual({ action: "handled" });
    expect(h.input("implement it", "extension")).not.toEqual({ action: "handled" });
    expect(h.activeTools()).toContain("plan_ready");
  });

  it("understands an explicit conversational user approval", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    expect(h.input("Yes, I want you to implement the plan.")).toEqual({ action: "handled" });
    expect(h.sent.at(-1)).toContain(plan);
  });

  it("revises then implements only on explicit user authorization", async () => {
    const h = harness({ hasUI: true, choices: ["Type your answer"], answers: ["Revise step 1, then implement the revised plan."] });
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    const revised = `${plan}\n4. Include the requested revision.`;
    await h.execute("plan_ready", { plan: revised });
    expect(h.sent.at(-1)).toContain(revised);
    expect(h.activeTools()).not.toContain("plan_ready");
  });

  it("honors a later typed revision-and-implement instruction only after a new plan", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    expect(h.input("Revise step 1, then implement the revised plan.")).not.toEqual({ action: "handled" });
    expect(h.activeTools()).toContain("plan_ready");
    await h.execute("plan_ready", { plan: `${plan}\n4. Requested revision.` });
    expect(h.activeTools()).not.toContain("plan_ready");
    expect(h.sent.at(-1)).toContain("Requested revision");
  });

  it("keeps a canceled plan ready and accepts later user approval", async () => {
    const h = harness({ hasUI: true, choices: [undefined] });
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan });
    expect(h.activeTools()).toContain("plan_ready");
    expect(h.input("go ahead")).toEqual({ action: "handled" });
    expect(h.sent.at(-1)).toContain(plan);
  });

  it("never treats a model's implement flag as authorization", async () => {
    const h = harness();
    await h.sessionStart();
    await h.runCommand("plan", "change something");
    await h.execute("plan_ready", { plan, implement: true });
    expect(h.activeTools()).toContain("plan_ready");
    expect(h.sent).toHaveLength(1);
  });
});
