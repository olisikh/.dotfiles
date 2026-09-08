import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { access, lstat, readFile, stat } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";
import type { PiExec, PiExecResult } from "../graphify-integration.ts";

export const STALE_MARKER = ".needs_update";
const MAX_GRAPH_BYTES = 50 * 1024 * 1024;
const MAX_OUTPUT_CHARS = 48_000;

// detect_incremental calls detect(), which normally writes word-count caches
// and office sidecars. Redirect those to disposable scratch, never the corpus.
// Keep the scan root and live manifest unchanged; no LLM or remote conversion.
export const FRESHNESS_SCRIPT = `
import contextlib, io, json, os, sys, tempfile
from pathlib import Path
os.environ['GRAPHIFY_OUT'] = 'graphify-out'
os.environ['GRAPHIFY_GOOGLE_WORKSPACE'] = '0'
import graphify.detect as detector
root = Path(sys.argv[1]).resolve()
manifest = root / 'graphify-out' / 'manifest.json'
raw = json.loads(manifest.read_text(encoding='utf-8'))
if not isinstance(raw, dict) or not raw:
    raise ValueError('Missing or empty manifest; run the session build workflow')
original_detect = detector.detect
with tempfile.TemporaryDirectory(prefix='pi-graphify-probe-') as scratch:
    def isolated_detect(scan_root, **kwargs):
        kwargs['cache_root'] = Path(scratch)
        kwargs['google_workspace'] = False
        return original_detect(scan_root, **kwargs)
    detector.detect = isolated_detect
    with contextlib.redirect_stdout(io.StringIO()):
        result = detector.detect_incremental(root, manifest_path=str(manifest))
    # Office sidecars have temporary paths. They require the session workflow
    # to reconcile their provenance; a probe must not stamp them as current.
    converted = any(Path(scratch) in Path(f).parents
                    for group in result['files'].values() for f in group)
    print(json.dumps({
        'changed': result['new_total'],
        'deleted': len(result.get('deleted_files', [])),
        'excluded': len(result.get('excluded_files', [])),
        'incomplete': bool(result.get('walk_errors')) or converted,
    }))
`;

export interface GraphifyDependencies {
  exec: PiExec;
  isPlan: (ctx: ExtensionContext) => boolean;
  agentDir?: string;
}

type ToolContext = Pick<ExtensionContext, "cwd">;
type Operation = "build" | "update";
type TraversalParams = {
  path?: string;
  question?: string;
  mode?: string;
  budget?: number;
  from?: string;
  to?: string;
  concept?: string;
};

function parseObject(text: string): Record<string, unknown> {
  try {
    const value: unknown = JSON.parse(text);
    if (value && typeof value === "object" && !Array.isArray(value))
      return value as Record<string, unknown>;
  } catch {
    /* Invalid JSON is reported by the enclosing freshness check. */
  }
  throw new Error("Invalid Graphify JSON object.");
}

export function agentDirectory(): string {
  return (
    process.env.PI_CODING_AGENT_DIR || path.join(homedir(), ".pi", "agent")
  );
}

export function workflowBriefing(
  operation: Operation,
  params: Record<string, unknown>,
  ctx: ToolContext,
  reason = "Graphify extraction is owned by the active Pi agent.",
  agentDir = agentDirectory(),
) {
  const guide = path.join(agentDir, "graphify", "session.md");
  const skill = path.join(agentDir, "skills", "graphify", "SKILL.md");
  return {
    content: [
      {
        type: "text" as const,
        text: [
          `Agent action required: ${reason}`,
          `Read ${guide}, then ${skill}. The Pi guide takes precedence for execution ownership.`,
          `Request: ${JSON.stringify({ operation, cwd: ctx.cwd, ...params })}`,
          "Carry out that workflow in this session, using native configured subagents for semantic chunks. This tool has NOT built or updated the graph. Do not call this briefing tool repeatedly; follow the guide and verify the outputs before reporting completion.",
        ].join("\n"),
      },
    ],
    details: {
      status: "requires_agent_work",
      operation,
      params,
      cwd: ctx.cwd,
      guide,
      skill,
      reason,
    },
  };
}

export function resultCode(result: PiExecResult): number {
  return result.code ?? result.exitCode ?? 1;
}

function assertAllowed(
  deps: GraphifyDependencies,
  ctx: ExtensionContext,
  signal?: AbortSignal,
): void {
  signal?.throwIfAborted();
  if (deps.isPlan(ctx))
    throw new Error(
      "Graphify execution is unavailable in Plan mode. Continue with read-only source inspection.",
    );
}

async function exists(file: string): Promise<boolean> {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

export async function graphOutputState(
  root: string,
): Promise<"directory" | "missing" | "unsafe"> {
  try {
    const entry = await lstat(path.join(root, "graphify-out"));
    return entry.isDirectory() && !entry.isSymbolicLink()
      ? "directory"
      : "unsafe";
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "ENOENT")
      return "missing";
    return "unsafe";
  }
}

function resolveInput(cwd: string, input: string): string {
  const value = input.replace(/^@/, "");
  return path.resolve(
    cwd,
    value.startsWith("~/") ? path.join(homedir(), value.slice(2)) : value,
  );
}

async function queryRoot(
  exec: PiExec,
  cwd: string,
  input: string | undefined,
  signal?: AbortSignal,
): Promise<string> {
  if (input) return resolveInput(cwd, input);
  const result = await exec("git", ["rev-parse", "--show-toplevel"], {
    cwd,
    signal,
    timeout: 5_000,
  });
  signal?.throwIfAborted();
  if (result.killed)
    throw new Error("Graphify repository lookup was cancelled or timed out.");
  return resultCode(result) === 0 && result.stdout?.trim()
    ? path.resolve(result.stdout.trim())
    : path.resolve(cwd);
}

/** Use the installed CLI's interpreter, not an unrelated system Python. */
export async function graphifyPython(): Promise<string> {
  // Repository .graphify_python markers are not executable authority. Resolve
  // from the trusted CLI on PATH instead (never execute repository marker text).
  for (const directory of (process.env.PATH ?? "").split(path.delimiter)) {
    if (!directory || !path.isAbsolute(directory)) continue;
    try {
      const cli = path.join(directory, "graphify");
      const firstLine = (await readFile(cli, "utf8")).split("\n", 1)[0];
      const match = /^#!(\/[^\r\n]+)$/.exec(firstLine);
      if (
        match &&
        !match[1].startsWith("/usr/bin/env") &&
        (await exists(match[1]))
      )
        return match[1];
    } catch {
      /* Try the next installed CLI. No auto-install or shell fallback. */
    }
  }
  throw new Error(
    "Cannot resolve Graphify's Python interpreter from its CLI on PATH. Repair the existing Graphify installation; no API key is needed.",
  );
}

export async function graphFreshness(
  exec: PiExec,
  root: string,
  signal?: AbortSignal,
): Promise<string | undefined> {
  if ((await graphOutputState(root)) !== "directory")
    return "Graph output is absent or unsafe (symlink/non-directory). Resolve its location before graph work.";
  const output = path.join(root, "graphify-out");
  const graphPath = path.join(output, "graph.json");
  const graphStat = await stat(graphPath);
  if (graphStat.size > MAX_GRAPH_BYTES)
    return "Graph exceeds the safe query size; narrow the corpus in the session workflow.";
  const graph = parseObject(await readFile(graphPath, "utf8"));
  if (
    !graph ||
    !Array.isArray(graph.nodes) ||
    graph.nodes.length === 0 ||
    !Array.isArray(graph.links ?? graph.edges)
  )
    return "Graph is empty or malformed.";
  if (!(await exists(path.join(output, "GRAPH_REPORT.md"))))
    return "Graph report is missing; verify and finish the session workflow.";
  if (!(await exists(path.join(output, "manifest.json"))))
    return "Graph manifest is missing; verify and refresh the graph in this session.";
  if (await exists(path.join(output, STALE_MARKER)))
    return "Source edits marked this graph stale. Verify incremental changes and refresh before querying.";
  const python = await graphifyPython();
  const result = await exec(python, ["-I", "-c", FRESHNESS_SCRIPT, root], {
    cwd: root,
    signal,
    timeout: 30_000,
    maxBuffer: 256 * 1024,
  });
  signal?.throwIfAborted();
  if (result.killed || resultCode(result) !== 0) {
    throw new Error(
      `Graphify freshness check failed: ${(result.stderr || result.stdout || "process failed").slice(0, 1200)}`,
    );
  }
  const state = parseObject(result.stdout ?? "");
  for (const key of ["changed", "deleted", "excluded"]) {
    if (
      typeof state[key] !== "number" ||
      !Number.isSafeInteger(state[key]) ||
      state[key] < 0
    )
      throw new Error("Invalid Graphify freshness response.");
  }
  if (typeof state.incomplete !== "boolean")
    throw new Error("Invalid Graphify freshness response.");
  if (state.changed || state.deleted || state.excluded || state.incomplete) {
    return `Manifest check: ${state.changed} changed, ${state.deleted} deleted, ${state.excluded} excluded files${state.incomplete ? "; scan needs session reconciliation" : ""}.`;
  }
  return undefined;
}

export function registerGraphifyTools(
  pi: ExtensionAPI,
  deps: GraphifyDependencies,
): void {
  const guideDir = deps.agentDir ?? agentDirectory();
  const buildParameters = Type.Object({
    path: Type.String({
      description:
        "Corpus directory, relative to the current working directory",
    }),
    mode: Type.Optional(Type.String({ enum: ["standard", "deep"] })),
    no_viz: Type.Optional(Type.Boolean()),
    obsidian: Type.Optional(Type.Boolean()),
    svg: Type.Optional(Type.Boolean()),
    graphml: Type.Optional(Type.Boolean()),
    neo4j: Type.Optional(Type.Boolean()),
  });
  for (const operation of ["build", "update"] as const) {
    pi.registerTool({
      name: `graphify_${operation}`,
      label: `Graphify ${operation} briefing`,
      description: `Prepare an agent-owned Graphify ${operation}. Returns workflow instructions, NOT a completed graph. The current agent must execute the skill; semantic extraction uses native configured Pi subagents, not headless APIs.`,
      promptSnippet: `Request instructions for a session-owned Graphify ${operation}.`,
      parameters:
        operation === "build"
          ? buildParameters
          : Type.Object({ path: Type.String() }),
      async execute(_id, params, signal, _onUpdate, ctx) {
        assertAllowed(deps, ctx, signal);
        return workflowBriefing(operation, params, ctx, undefined, guideDir);
      },
    });
  }

  const optionalPath = Type.Optional(
    Type.String({
      description:
        "Explicit corpus root. Omit to use the current Git repository root, or cwd outside Git.",
    }),
  );
  const queryParameters = Type.Object({
    question: Type.String(),
    mode: Type.Optional(Type.String({ enum: ["bfs", "dfs"] })),
    budget: Type.Optional(Type.Integer({ minimum: 1, maximum: 100_000 })),
    path: optionalPath,
  });
  const pathParameters = Type.Object({
    from: Type.String(),
    to: Type.String(),
    path: optionalPath,
  });
  const explainParameters = Type.Object({
    concept: Type.String(),
    path: optionalPath,
  });

  // Keep each schema beside its argv builder; no shell interpolation or provider API.
  function registerTraversal(
    name: string,
    parameters:
      | typeof queryParameters
      | typeof pathParameters
      | typeof explainParameters,
    argv: (params: TraversalParams) => string[],
  ) {
    pi.registerTool({
      name: `graphify_${name}`,
      label: `Graphify ${name}`,
      description: `Traverse an existing, current Graphify graph (${name}). Missing/stale graphs return an agent workflow briefing. Output is capped at ${MAX_OUTPUT_CHARS} characters.`,
      promptSnippet: `Use graphify_${name} to navigate a current graph; follow any freshness briefing before retrying.`,
      parameters,
      async execute(_id, params, signal, _onUpdate, ctx) {
        assertAllowed(deps, ctx, signal);
        const root = await queryRoot(deps.exec, ctx.cwd, params.path, signal);
        assertAllowed(deps, ctx, signal);
        const outputState = await graphOutputState(root);
        if (outputState === "unsafe")
          return workflowBriefing(
            "update",
            { path: root },
            ctx,
            "Refusing symlinked or non-directory graphify-out. Resolve its location before graph work.",
            guideDir,
          );
        const graphPath = path.join(root, "graphify-out", "graph.json");
        if (outputState === "missing" || !(await exists(graphPath)))
          return workflowBriefing(
            "build",
            { path: root },
            ctx,
            "No graph exists for this corpus.",
            guideDir,
          );
        let stale: string | undefined;
        try {
          stale = await graphFreshness(deps.exec, root, signal);
        } catch (error) {
          assertAllowed(deps, ctx, signal);
          stale = `Cannot verify graph freshness: ${error instanceof Error ? error.message : String(error)}`;
        }
        assertAllowed(deps, ctx, signal);
        if (stale)
          return workflowBriefing(
            "update",
            { path: root },
            ctx,
            stale,
            guideDir,
          );
        const result = await deps.exec("graphify", argv(params), {
          cwd: root,
          signal,
          timeout: 30_000,
          maxBuffer: 256 * 1024,
        });
        assertAllowed(deps, ctx, signal);
        if (result.killed || resultCode(result) !== 0) {
          throw new Error(
            `Graphify ${name} failed: ${(result.stderr || result.stdout || "process failed").slice(0, 1200)}`,
          );
        }
        const raw = result.stdout ?? "";
        const truncated = raw.length > MAX_OUTPUT_CHARS;
        const text =
          raw.slice(0, MAX_OUTPUT_CHARS) +
          (truncated
            ? "\n[Graphify output truncated; narrow the query or reduce its budget.]"
            : "");
        return {
          content: [{ type: "text" as const, text }],
          details: { status: "complete", root, truncated },
        };
      },
    });
  }
  registerTraversal("query", queryParameters, (params) => [
    "query",
    params.question ?? "",
    ...(params.mode === "dfs" ? ["--dfs"] : []),
    "--budget",
    String(params.budget ?? 2000),
  ]);
  registerTraversal("path", pathParameters, (params) => [
    "path",
    params.from ?? "",
    params.to ?? "",
  ]);
  registerTraversal("explain", explainParameters, (params) => [
    "explain",
    params.concept ?? "",
  ]);

  pi.registerCommand("graphify", {
    description:
      "Run Graphify through the current Pi agent (build, --update, query, path, explain, exports)",
    handler: async (args, ctx) => {
      assertAllowed(deps, ctx);
      const briefing = workflowBriefing(
        "build",
        { arguments: args.trim() || "." },
        ctx,
        "Interpret these /graphify arguments using the installed skill. This is an agent request, not CLI execution.",
        guideDir,
      );
      pi.sendUserMessage(briefing.content[0].text, { deliverAs: "followUp" });
    },
  });
}
