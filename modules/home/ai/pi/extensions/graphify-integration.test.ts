import { afterEach, describe, expect, it } from "bun:test";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import graphifyIntegration, {
  captureRepositoryFingerprint,
  runProcess,
  type PiExec,
} from "./graphify-integration";

const roots: string[] = [];
const git = (root: string, args: string[]) =>
  execFileSync("git", args, { cwd: root, encoding: "utf8" });
function project(code = true) {
  const root = mkdtempSync(path.join(tmpdir(), "pi-graphify-integration-"));
  roots.push(root);
  git(root, ["init", "-q"]);
  git(root, ["config", "user.email", "fixture@example.com"]);
  git(root, ["config", "user.name", "Fixture"]);
  writeFileSync(
    path.join(root, code ? "service.ts" : "notes.md"),
    code ? "export const retry = 3;\n" : "Notes only.\n",
  );
  git(root, ["add", "."]);
  git(root, ["commit", "-qm", "initial"]);
  return root;
}
function graph(root: string) {
  mkdirSync(path.join(root, "graphify-out"));
  writeFileSync(
    path.join(root, "graphify-out", "graph.json"),
    '{"nodes":[{"id":"a"}],"links":[]}\n',
  );
}
const marker = (root: string) =>
  path.join(root, "graphify-out", ".needs_update");
type Context = {
  cwd: string;
  ui: { notify: (message: string) => void };
  sessionManager: {
    getBranch: () => Array<{
      type: string;
      customType: string;
      data: { mode: string };
    }>;
  };
};
type Handler = (event: unknown, ctx: Context) => unknown | Promise<unknown>;
function harness(root: string, execOverride?: PiExec) {
  const handlers = new Map<string, Handler>();
  const channels = new Map<string, (event: unknown) => void>();
  const calls: string[] = [];
  const notifications: string[] = [];
  const messages: unknown[] = [];
  const exec: PiExec = async (command, args, options) => {
    calls.push(command);
    return (execOverride ?? runProcess)(command, args, options);
  };
  const pi = {
    on: (name: string, handler: Handler) => handlers.set(name, handler),
    registerTool: (_tool: unknown) => {},
    registerCommand: (_name: string, _command: unknown) => {},
    sendUserMessage: (text: string) => messages.push(text),
    events: {
      on: (name: string, handler: (event: unknown) => void) => {
        channels.set(name, handler);
        return () => {
          channels.delete(name);
        };
      },
    },
  };
  graphifyIntegration(pi as never, exec);
  const ctx: Context = {
    cwd: root,
    ui: { notify: (message) => notifications.push(message) },
    sessionManager: { getBranch: () => [] },
  };
  const before = () =>
    handlers.get("before_agent_start")?.({ systemPrompt: "base" }, ctx);
  const end = () => handlers.get("agent_end")?.({}, ctx);
  const mode = (value: string) =>
    channels.get("pi:mode-changed")?.({
      version: 1,
      source: "olisikh:modes",
      mode: value,
      state: "active",
      active: value !== "build",
    });
  return { handlers, calls, notifications, messages, ctx, before, end, mode };
}
afterEach(() => {
  for (const root of roots.splice(0))
    rmSync(root, { recursive: true, force: true });
});

describe("session-owned Graphify lifecycle", () => {
  it("injects the session guide, not a headless execution route", async () => {
    const root = project();
    const h = harness(root);
    const result = (await h.before()) as { systemPrompt: string };
    expect(result.systemPrompt).toContain("Graphify is the default mechanism");
    expect(result.systemPrompt).toContain("graphify/session.md");
    expect(result.systemPrompt).toContain(
      "only supplies the workflow briefing",
    );
    expect(result.systemPrompt).toContain(
      "Graph state at this run's start: absent",
    );
    await h.end();
    expect(h.calls.every((name) => name === "git")).toBe(true);
    expect(h.messages).toEqual([]);
  });

  it("marks source changes stale without running Graphify or queuing a turn", async () => {
    const root = project();
    graph(root);
    const original = readFileSync(
      path.join(root, "graphify-out/graph.json"),
      "utf8",
    );
    const h = harness(root);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "export const retry = 5;\n");
    await h.end();
    expect(existsSync(marker(root))).toBe(true);
    expect(
      readFileSync(path.join(root, "graphify-out/graph.json"), "utf8"),
    ).toBe(original);
    expect(h.calls.every((name) => name === "git")).toBe(true);
    expect(h.messages).toEqual([]);
  });

  for (const scenario of ["unchanged", "restored", "generated"] as const) {
    it(`does not mark ${scenario} source state stale`, async () => {
      const root = project();
      graph(root);
      const h = harness(root);
      await h.before();
      if (scenario === "restored") {
        writeFileSync(path.join(root, "service.ts"), "temporary\n");
        writeFileSync(
          path.join(root, "service.ts"),
          "export const retry = 3;\n",
        );
      }
      if (scenario === "generated")
        writeFileSync(path.join(root, "graphify-out/report.md"), "generated\n");
      await h.end();
      expect(existsSync(marker(root))).toBe(false);
    });
  }

  for (const scenario of ["untracked", "staged", "deleted"] as const) {
    it(`marks ${scenario} changes stale`, async () => {
      const root = project();
      graph(root);
      const h = harness(root);
      await h.before();
      if (scenario === "untracked")
        writeFileSync(path.join(root, "new.ts"), "export const x = 1;\n");
      if (scenario === "staged") {
        writeFileSync(
          path.join(root, "service.ts"),
          "export const retry = 7;\n",
        );
        git(root, ["add", "service.ts"]);
      }
      if (scenario === "deleted") git(root, ["rm", "-f", "service.ts"]);
      await h.end();
      expect(existsSync(marker(root))).toBe(true);
    });
  }

  it("uses the Git root from a nested cwd", async () => {
    const root = project();
    graph(root);
    const nested = path.join(root, "nested");
    mkdirSync(nested);
    const h = harness(nested);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await h.end();
    expect(existsSync(marker(root))).toBe(true);
    expect(existsSync(path.join(nested, "graphify-out"))).toBe(false);
  });

  it("does not create a graph or marker when no graph exists", async () => {
    const root = project();
    const h = harness(root);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await h.end();
    expect(existsSync(path.join(root, "graphify-out"))).toBe(false);
  });

  it("does not follow a symlinked output directory", async () => {
    const root = project();
    const outside = project();
    graph(outside);
    symlinkSync(
      path.join(outside, "graphify-out"),
      path.join(root, "graphify-out"),
    );
    const h = harness(root);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await h.end();
    expect(existsSync(marker(outside))).toBe(false);
    expect(h.calls.every((name) => name === "git")).toBe(true);
  });

  it("does not follow an existing marker symlink", async () => {
    const root = project();
    graph(root);
    const outside = path.join(project(), "protected.txt");
    writeFileSync(outside, "preserve me");
    symlinkSync(outside, marker(root));
    const h = harness(root);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await h.end();
    expect(readFileSync(outside, "utf8")).toBe("preserve me");
    expect(h.notifications.join("\n")).toContain("Could not mark graph stale");
  });

  it("preserves the result if marking stale fails", async () => {
    const root = project();
    graph(root);
    mkdirSync(marker(root));
    const h = harness(root);
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await expect(Promise.resolve(h.end())).resolves.toBeUndefined();
    expect(h.notifications.join("\n")).toContain("Could not mark graph stale");
  });

  it("Plan mode suppresses all probing and maintenance", async () => {
    const root = project();
    graph(root);
    const h = harness(root);
    h.mode("plan");
    await h.before();
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    await h.end();
    expect(h.calls).toEqual([]);
    expect(existsSync(marker(root))).toBe(false);
    h.mode("build");
    await h.before();
    expect(h.calls.length).toBeGreaterThan(0);
  });

  it("restores Plan mode from session state before hooks run", async () => {
    const root = project();
    const h = harness(root);
    h.ctx.sessionManager.getBranch = () => [
      { type: "custom", customType: "olisikh:modes", data: { mode: "plan" } },
    ];
    await h.handlers.get("session_start")?.({}, h.ctx);
    await h.before();
    await h.end();
    expect(h.calls).toEqual([]);
  });

  it("cancels an in-flight probe on shutdown", async () => {
    const root = project();
    let observedSignal: AbortSignal | undefined;
    let started!: () => void;
    const ready = new Promise<void>((resolve) => {
      started = resolve;
    });
    const h = harness(root, async (_command, _args, options) => {
      observedSignal = options?.signal;
      started();
      await new Promise<void>((resolve) =>
        options?.signal?.addEventListener("abort", () => resolve(), {
          once: true,
        }),
      );
      return { code: 1, killed: true };
    });
    const pending = h.before();
    await ready;
    await h.handlers.get("session_shutdown")?.({}, h.ctx);
    await pending;
    expect(observedSignal?.aborted).toBe(true);
    expect(h.calls).toHaveLength(1);
    expect(existsSync(marker(root))).toBe(false);
  });

  it("keeps non-code and non-repository directories passive", async () => {
    const docs = harness(project(false));
    expect(await docs.before()).toBeUndefined();
    const root = mkdtempSync(path.join(tmpdir(), "pi-graphify-plain-"));
    roots.push(root);
    expect(await harness(root).before()).toBeUndefined();
  });

  it("fingerprints index changes independently of the graph", async () => {
    const root = project();
    const before = await captureRepositoryFingerprint(runProcess, root);
    writeFileSync(path.join(root, "service.ts"), "changed\n");
    git(root, ["add", "."]);
    expect(await captureRepositoryFingerprint(runProcess, root)).not.toBe(
      before,
    );
  });
});
