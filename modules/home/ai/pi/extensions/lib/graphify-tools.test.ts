import { afterEach, describe, expect, it } from "bun:test";
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
import {
  registerGraphifyTools,
  FRESHNESS_SCRIPT,
  graphFreshness,
} from "./graphify-tools";
import { runProcess } from "../graphify-integration";
import type {
  PiExec,
  PiExecOptions,
  PiExecResult,
} from "../graphify-integration";

type Result = {
  content: Array<{ text: string }>;
  details: {
    status: string;
    operation?: string;
    params?: Record<string, unknown>;
    truncated?: boolean;
  };
};
type Context = { cwd: string; isIdle: () => boolean };
type Tool = {
  name: string;
  execute: (
    id: string,
    params: Record<string, unknown>,
    signal: AbortSignal,
    update: undefined,
    ctx: Context,
  ) => Promise<Result>;
};
type Command = { handler: (args: string, ctx: Context) => Promise<void> };
const roots: string[] = [];
const originalPath = process.env.PATH;
const fresh = JSON.stringify({
  changed: 0,
  deleted: 0,
  excluded: 0,
  incomplete: false,
});

function harness() {
  const root = mkdtempSync(path.join(tmpdir(), "pi-graphify-tools-"));
  roots.push(root);
  const bin = path.join(root, "bin");
  mkdirSync(bin);
  writeFileSync(path.join(bin, "graphify"), "#!/usr/bin/true\n");
  process.env.PATH = bin;
  const tools = new Map<string, Tool>();
  const commands = new Map<string, Command>();
  const calls: Array<{
    command: string;
    args: string[];
    options?: PiExecOptions;
  }> = [];
  const messages: Array<{ text: string; options: unknown }> = [];
  let plan = false;
  let probe: PiExecResult = { code: 0, stdout: fresh };
  let traversal: PiExecResult = { code: 0, stdout: "Graph evidence" };
  const exec: PiExec = async (command, args, options) => {
    calls.push({ command, args, options });
    if (command === "git") return { code: 0, stdout: root };
    return command === "graphify" ? traversal : probe;
  };
  registerGraphifyTools(
    {
      registerTool: (tool: Tool) => tools.set(tool.name, tool),
      registerCommand: (name: string, cmd: Command) => commands.set(name, cmd),
      sendUserMessage: (text: string, options: unknown) =>
        messages.push({ text, options }),
    } as never,
    { exec, isPlan: () => plan, agentDir: "/trusted/pi" },
  );
  const ctx = { cwd: path.join(root, "nested"), isIdle: () => true };
  const invoke = (
    name: string,
    params: Record<string, unknown>,
    signal = new AbortController().signal,
  ) => {
    const tool = tools.get(name);
    if (!tool) throw new Error(`Missing ${name}`);
    return tool.execute("fixture", params, signal, undefined, ctx);
  };
  function graph() {
    const out = path.join(root, "graphify-out");
    mkdirSync(out);
    writeFileSync(
      path.join(out, "graph.json"),
      '{"nodes":[{"id":"a"}],"links":[]}',
    );
    writeFileSync(
      path.join(out, "manifest.json"),
      '{"auth.ts":{"semantic_hash":"hash","ast_hash":"hash","mtime":1}}',
    );
    writeFileSync(path.join(out, "GRAPH_REPORT.md"), "Fixture report");
  }
  return {
    root,
    calls,
    tools,
    commands,
    messages,
    ctx,
    invoke,
    graph,
    setPlan: () => {
      plan = true;
    },
    setProbe: (value: PiExecResult) => {
      probe = value;
    },
    setTraversal: (value: PiExecResult) => {
      traversal = value;
    },
  };
}
afterEach(() => {
  process.env.PATH = originalPath;
  for (const root of roots.splice(0))
    rmSync(root, { recursive: true, force: true });
});

describe("Graphify entry points", () => {
  it("build/update briefings preserve intent without subprocesses or false completion", async () => {
    const h = harness();
    const params = {
      path: "../corpus with spaces",
      mode: "deep",
      no_viz: true,
      obsidian: true,
      svg: true,
      graphml: true,
      neo4j: true,
    };
    for (const operation of ["build", "update"]) {
      const result = await h.invoke(`graphify_${operation}`, params);
      expect(result.details.status).toBe("requires_agent_work");
      expect(result.details.params).toEqual(params);
      expect(result.content[0].text).toContain("has NOT built or updated");
      expect(result.content[0].text).toContain(
        "/trusted/pi/graphify/session.md",
      );
    }
    expect(h.calls).toEqual([]);
    expect(h.messages).toEqual([]);
    expect(h.tools.has("graphify_extract")).toBe(false);
  });

  it("/graphify passes syntax to the current agent, without raw CLI execution", async () => {
    const h = harness();
    await h.commands
      .get("graphify")
      ?.handler('"folder with spaces" --update --no-viz', h.ctx);
    expect(h.messages).toHaveLength(1);
    expect(h.messages[0].text).toContain("--update --no-viz");
    expect(h.messages[0].options).toEqual({ deliverAs: "followUp" });
    expect(h.calls).toEqual([]);
  });

  it("blocks tools AND slash commands in Plan mode", async () => {
    const h = harness();
    h.setPlan();
    for (const name of h.tools.keys())
      await expect(h.invoke(name, { path: "." })).rejects.toThrow("Plan mode");
    await expect(
      h.commands.get("graphify")!.handler(".", h.ctx),
    ).rejects.toThrow("Plan mode");
    expect(h.calls).toEqual([]);
    expect(h.messages).toEqual([]);
  });

  it("missing graphs request a build, not an implicit CLI extraction", async () => {
    const h = harness();
    const result = await h.invoke("graphify_query", { question: "auth" });
    expect(result.details.operation).toBe("build");
    expect(h.calls.map((call) => call.command)).toEqual(["git"]);
  });

  it("traverses fresh graphs with literal argv, root cwd, bounds and signal", async () => {
    const h = harness();
    h.graph();
    const question = 'auth; $(touch /tmp/should-not-exist) "quoted"';
    const signal = new AbortController().signal;
    const result = await h.invoke(
      "graphify_query",
      { question, mode: "dfs", budget: 1500 },
      signal,
    );
    expect(result.details.status).toBe("complete");
    expect(h.calls.at(-1)).toEqual({
      command: "graphify",
      args: ["query", question, "--dfs", "--budget", "1500"],
      options: { cwd: h.root, signal, timeout: 30_000, maxBuffer: 256 * 1024 },
    });
    expect(h.calls[1].args).toEqual(["-I", "-c", FRESHNESS_SCRIPT, h.root]);
  });

  it("supports path/explain and explicit non-Git corpora", async () => {
    const h = harness();
    h.graph();
    await h.invoke("graphify_path", {
      from: "A space",
      to: "B'quote",
      path: h.root,
    });
    expect(h.calls.at(-1)?.args).toEqual(["path", "A space", "B'quote"]);
    await h.invoke("graphify_explain", { concept: "A space", path: h.root });
    expect(h.calls.at(-1)?.args).toEqual(["explain", "A space"]);
    expect(h.calls.some((call) => call.command === "git")).toBe(false);
  });

  for (const state of [
    { changed: 1, deleted: 0, excluded: 0, incomplete: false },
    { changed: 0, deleted: 1, excluded: 0, incomplete: false },
    { changed: 0, deleted: 0, excluded: 1, incomplete: false },
    { changed: 0, deleted: 0, excluded: 0, incomplete: true },
  ]) {
    it(`requires refresh for manifest state ${JSON.stringify(state)}`, async () => {
      const h = harness();
      h.graph();
      h.setProbe({ code: 0, stdout: JSON.stringify(state) });
      const result = await h.invoke("graphify_query", { question: "auth" });
      expect(result.details.operation).toBe("update");
      expect(h.calls.some((call) => call.command === "graphify")).toBe(false);
    });
  }

  it("retains stale marker and previous artifacts until the agent verifies refresh", async () => {
    const h = harness();
    h.graph();
    const out = path.join(h.root, "graphify-out");
    const before = readFileSync(path.join(out, "graph.json"), "utf8");
    writeFileSync(path.join(out, ".needs_update"), "stale");
    const result = await h.invoke("graphify_query", { question: "auth" });
    expect(result.details.operation).toBe("update");
    expect(readFileSync(path.join(out, ".needs_update"), "utf8")).toBe("stale");
    expect(readFileSync(path.join(out, "graph.json"), "utf8")).toBe(before);
    expect(h.calls).toHaveLength(1);
  });

  for (const failure of [
    "malformed graph",
    "missing manifest",
    "malformed probe",
    "failed probe",
    "missing CLI",
  ]) {
    it(`fails closed on ${failure}`, async () => {
      const h = harness();
      h.graph();
      const out = path.join(h.root, "graphify-out");
      if (failure === "malformed graph")
        writeFileSync(path.join(out, "graph.json"), "{invalid");
      if (failure === "missing manifest")
        rmSync(path.join(out, "manifest.json"));
      if (failure === "malformed probe") h.setProbe({ code: 0, stdout: "{}" });
      if (failure === "failed probe") h.setProbe({ code: 1, stderr: "failed" });
      if (failure === "missing CLI") process.env.PATH = "";
      const before = readFileSync(path.join(out, "graph.json"), "utf8");
      const result = await h.invoke("graphify_query", { question: "auth" });
      expect(result.details.operation).toBe("update");
      expect(readFileSync(path.join(out, "graph.json"), "utf8")).toBe(before);
      expect(h.calls.some((call) => call.command === "graphify")).toBe(false);
    });
  }

  it("refuses symlinked output before probing or traversal", async () => {
    const h = harness();
    const outside = mkdtempSync(path.join(tmpdir(), "graphify-outside-"));
    roots.push(outside);
    writeFileSync(
      path.join(outside, "graph.json"),
      '{"nodes":[{"id":"a"}],"links":[]}',
    );
    symlinkSync(outside, path.join(h.root, "graphify-out"));
    const result = await h.invoke("graphify_query", { question: "auth" });
    expect(result.details.operation).toBe("update");
    expect(result.content[0].text).toContain("symlinked");
    expect(h.calls.map((call) => call.command)).toEqual(["git"]);
  });

  (process.env.GRAPHIFY_LIVE_TESTS === "1" ? it : it.skip)(
    "installed Python ignores a corpus-local shadow package",
    async () => {
      const h = harness();
      h.graph();
      process.env.PATH = originalPath;
      const shadow = path.join(h.root, "graphify");
      mkdirSync(shadow);
      const sentinel = path.join(h.root, "shadow-executed");
      writeFileSync(
        path.join(shadow, "__init__.py"),
        `from pathlib import Path\nPath(${JSON.stringify(sentinel)}).write_text('unsafe')\n`,
      );
      writeFileSync(
        path.join(shadow, "detect.py"),
        "raise RuntimeError('shadow package executed')\n",
      );
      const stale = await graphFreshness(runProcess, h.root);
      expect(stale).toContain("changed");
      expect(existsSync(sentinel)).toBe(false);
    },
  );

  it("does not execute a repository-supplied Python marker", async () => {
    const h = harness();
    h.graph();
    writeFileSync(
      path.join(h.root, "graphify-out/.graphify_python"),
      "/untrusted/repo/program",
    );
    await h.invoke("graphify_query", { question: "auth" });
    expect(h.calls[1].command).toBe("/usr/bin/true");
  });

  it("does not start cancelled calls", async () => {
    const h = harness();
    const controller = new AbortController();
    controller.abort();
    await expect(
      h.invoke("graphify_query", { question: "auth" }, controller.signal),
    ).rejects.toThrow();
    expect(h.calls).toEqual([]);
  });

  it("reports traversal errors and signal deaths, even with stdout", async () => {
    const h = harness();
    h.graph();
    for (const response of [
      { code: 127, stderr: "missing CLI" },
      { code: 0, stdout: "partial", killed: true },
    ]) {
      h.setTraversal(response);
      await expect(
        h.invoke("graphify_explain", { concept: "auth" }),
      ).rejects.toThrow("failed");
    }
  });

  it("caps model-visible traversal output", async () => {
    const h = harness();
    h.graph();
    h.setTraversal({ code: 0, stdout: "x".repeat(60_000) });
    const result = await h.invoke("graphify_query", { question: "auth" });
    expect(result.details.truncated).toBe(true);
    expect(result.content[0].text.length).toBeLessThan(49_000);
  });

  it("deploys the overlay instead of the competing package", () => {
    const piRoot = path.resolve(import.meta.dir, "../..");
    const config = readFileSync(path.join(piRoot, "default.nix"), "utf8");
    expect(config).not.toContain('"npm:@gaodes/pi-graphify"');
    expect(config).toContain(
      '".pi/agent/graphify/session.md".source = ./prompts/graphify-session.md',
    );
    const guide = readFileSync(
      path.join(piRoot, "prompts/graphify-session.md"),
      "utf8",
    );
    expect(guide).toContain("`async: true`");
    expect(guide).toContain("configured native `delegate`");
    expect(guide).toContain(
      "Missing, malformed, failed or incomplete chunks block publication",
    );
    expect(guide).not.toContain("gpt-");
  });
});
