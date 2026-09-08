// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
// @ts-ignore Pi provides node at runtime.
import { execFile } from "node:child_process";
// @ts-ignore Pi provides node at runtime.
import { createHash } from "node:crypto";
// @ts-ignore Pi provides node at runtime.
import {
	access,
	lstat,
	readFile,
	readlink,
	readdir,
	writeFile,
} from "node:fs/promises";
// @ts-ignore Pi provides node at runtime.
import path from "node:path";
import { subscribeToModeChanges } from "./lib/mode-events.ts";
import {
	agentDirectory,
	graphOutputState,
	registerGraphifyTools,
	STALE_MARKER,
} from "./lib/graphify-tools.ts";

const GRAPHIFY_OUTPUT_DIR = "graphify-out";
const GRAPHIFY_GRAPH = `${GRAPHIFY_OUTPUT_DIR}/graph.json`;
const MAX_WARNING_DETAIL_LENGTH = 240;

const CODE_EXTENSIONS = new Set([
	".astro",
	".bash",
	".c",
	".cc",
	".clj",
	".cljs",
	".cpp",
	".cs",
	".cxx",
	".d",
	".dart",
	".ex",
	".exs",
	".fish",
	".fs",
	".fsx",
	".go",
	".graphql",
	".h",
	".hh",
	".hpp",
	".hs",
	".java",
	".jl",
	".js",
	".json",
	".jsx",
	".kts",
	".kt",
	".lua",
	".m",
	".mm",
	".mjs",
	".nim",
	".nix",
	".php",
	".pl",
	".pm",
	".py",
	".r",
	".rb",
	".rs",
	".scala",
	".scm",
	".sh",
	".sol",
	".sql",
	".swift",
	".tcl",
	".ts",
	".tsx",
	".vue",
	".zig",
]);

const PROJECT_MARKERS = new Set([
	"Bazel",
	"CMakeLists.txt",
	"Cargo.toml",
	"Gemfile",
	"Makefile",
	"Package.swift",
	"build.gradle",
	"build.gradle.kts",
	"composer.json",
	"deno.json",
	"flake.nix",
	"go.mod",
	"mix.exs",
	"package.json",
	"pom.xml",
	"pyproject.toml",
	"requirements.txt",
	"setup.py",
	"tsconfig.json",
]);

const TRANSIENT_UNTRACKED_PREFIXES = [
	".cache/",
	".direnv/",
	".gradle/",
	".next/",
	".parcel-cache/",
	".pytest_cache/",
	".turbo/",
	".venv/",
	"__pycache__/",
	"build/",
	"coverage/",
	"dist/",
	"node_modules/",
	"target/",
	"vendor/bundle/",
] as const;

const GRAPHIFY_POLICY = [
	"## Graphify codebase navigation policy",
	"Graphify is the default mechanism for understanding and navigating an existing codebase.",
	"",
	"Before broad source-code exploration, check whether `graphify-out/graph.json` exists at the repository root.",
	"If it is absent, use the installed `graphify` skill with the Pi session guide to build it in the current agent session. `graphify_build` only supplies the workflow briefing; it does not build a graph.",
	"If the graph exists, consult Graphify before broad Grep/Glob/find/file-tree exploration. A stale graph must be refreshed by the current agent before use, not by an automatic post-task process.",
	"Semantic extraction belongs to the current Pi agent or native configured subagents. The Pi session guide overrides the upstream skill's external API and Claude-style Agent instructions. Headless extraction is not the Pi workflow.",
	"",
	"Prefer Graphify queries (`graphify_query`, `graphify_path`, and `graphify_explain`) for where a feature is implemented, which components participate in a flow, what calls or depends on a symbol, how codebase parts connect, and which files are likely relevant.",
	"Use Graphify to narrow the search space, then read relevant source files normally. Direct reads/searches remain appropriate when the exact file or symbol is known, the search is cheaper, the files were already identified, or Graphify cannot answer.",
	"Do not blindly replace every grep/read with Graphify. Reuse the installed skill's graph algorithms with the Pi session guide's execution rules. In read-only/Plan tasks, use source inspection instead; never build, refresh, or delegate merely to answer a planning question.",
].join("\n");

export type PiExecResult = {
	stdout?: string;
	stderr?: string;
	code?: number | null;
	exitCode?: number | null;
	killed?: boolean;
};

export type PiExecOptions = {
	cwd?: string;
	signal?: AbortSignal;
	timeout?: number;
	maxBuffer?: number;
};

export type PiExec = (
	command: string,
	args: string[],
	options?: PiExecOptions,
) => Promise<PiExecResult>;

type ExecFileError = Error & {
	code?: number | string;
	killed?: boolean;
};

const PROCESS_MAX_BUFFER = 8 * 1024 * 1024;

/** Run a direct argv process with an explicit cwd; no shell is involved. */
export function runProcess(
	command: string,
	args: string[],
	options: PiExecOptions = {},
): Promise<PiExecResult> {
	return new Promise((resolve) => {
		execFile(
			command,
			args,
			{
				cwd: options.cwd,
				encoding: "utf8",
				maxBuffer: options.maxBuffer ?? PROCESS_MAX_BUFFER,
				env: {
					...process.env,
					GRAPHIFY_OUT: GRAPHIFY_OUTPUT_DIR,
					GRAPHIFY_GOOGLE_WORKSPACE: "0",
				},
				signal: options.signal,
				timeout: options.timeout,
			},
			(error, stdout, stderr) => {
				const processError = error as ExecFileError | null;
				const code =
					typeof processError?.code === "number"
						? processError.code
						: processError
							? 127
							: 0;
				const diagnostic =
					String(stderr ?? "").trim() || processError?.message || "";
				resolve({
					stdout: String(stdout ?? ""),
					stderr: diagnostic,
					code,
					killed: processError?.killed,
				});
			},
		);
	});
}

export type RepositoryContext = {
	root: string;
	graphPath: string;
};

type StatusRecord = {
	status: string;
	paths: string[];
};

type PathSnapshot = {
	path: string;
	status: string;
	content: string;
};

type RunState = RepositoryContext & {
	initialFingerprint: string;
};

type BeforeAgentStartEvent = {
	systemPrompt?: string;
};

type NotifyContext = Pick<ExtensionContext, "ui">;

function resultCode(result: PiExecResult): number {
	return result.code ?? result.exitCode ?? 1;
}

function normalizeRepoPath(value: string): string {
	return value.replaceAll("\\", "/").replace(/^\.\//, "");
}

function isGraphifyOutputPath(relativePath: string): boolean {
	const normalized = normalizeRepoPath(relativePath);
	return (
		normalized === GRAPHIFY_OUTPUT_DIR ||
		normalized.startsWith(`${GRAPHIFY_OUTPUT_DIR}/`)
	);
}

function isTransientUntrackedPath(
	relativePath: string,
	status: string,
): boolean {
	if (!status.includes("?")) return false;
	const normalized = normalizeRepoPath(relativePath);
	return TRANSIENT_UNTRACKED_PREFIXES.some(
		(prefix) =>
			normalized === prefix.slice(0, -1) || normalized.startsWith(prefix),
	);
}

function isIgnoredFingerprintPath(
	relativePath: string,
	status: string,
): boolean {
	return (
		isGraphifyOutputPath(relativePath) ||
		normalizeRepoPath(relativePath).startsWith(".git/") ||
		isTransientUntrackedPath(relativePath, status)
	);
}

function parsePorcelainStatus(output: string): StatusRecord[] {
	const fields = output.split("\0").filter(Boolean);
	const records: StatusRecord[] = [];

	for (let index = 0; index < fields.length; index += 1) {
		const field = fields[index];
		if (field.length < 3) continue;

		const status = field.slice(0, 2);
		const paths = [field.slice(3)];
		if (status.includes("R") || status.includes("C")) {
			const destination = fields[index + 1];
			if (destination !== undefined) {
				paths.push(destination);
				index += 1;
			}
		}
		records.push({ status, paths });
	}

	return records;
}

function parseIndexEntries(output: string): string[] {
	return output
		.split("\0")
		.filter(Boolean)
		.filter((entry) => {
			const tab = entry.indexOf("\t");
			const relativePath = tab >= 0 ? entry.slice(tab + 1) : entry;
			return !isGraphifyOutputPath(relativePath);
		})
		.sort();
}

async function snapshotPath(
	root: string,
	relativePath: string,
): Promise<string> {
	const absolutePath = path.resolve(root, relativePath);
	try {
		const stats = await lstat(absolutePath);
		if (stats.isSymbolicLink()) {
			return `symlink:${await readlink(absolutePath)}`;
		}
		if (stats.isFile()) {
			const content = await readFile(absolutePath);
			return `file:${stats.mode & 0o777}:${createHash("sha256").update(content).digest("hex")}`;
		}
		return `other:${stats.mode}:${stats.size}`;
	} catch (error) {
		if (error instanceof Error && "code" in error && error.code === "ENOENT") {
			return "missing";
		}
		return `unreadable:${error instanceof Error ? error.name : String(error)}`;
	}
}

/** Build the exact policy appended to the current Pi system prompt. */
export function buildGraphifyPolicy(graphExists: boolean): string {
	return `${GRAPHIFY_POLICY}\nPi session guide: ${path.join(agentDirectory(), "graphify", "session.md")}\nGraph state at this run's start: ${graphExists ? "present" : "absent"}.`;
}

/**
 * Resolve the Git repository root and reject non-code repositories.
 * This is intentionally Git-based: non-repository directories do not get
 * Graphify behavior, and a nested Pi cwd is normalized to one project root.
 */
export async function detectRepositoryContext(
	exec: PiExec,
	cwd: string,
): Promise<RepositoryContext | undefined> {
	const rootResult = await exec("git", ["rev-parse", "--show-toplevel"], {
		cwd,
		timeout: 5_000,
	});
	if (resultCode(rootResult) !== 0 || !rootResult.stdout?.trim())
		return undefined;

	const root = path.resolve(rootResult.stdout.trim());
	const filesResult = await exec(
		"git",
		["ls-files", "--cached", "--others", "--exclude-standard", "-z"],
		{ cwd: root, timeout: 5_000 },
	);
	const repositoryFiles = (filesResult.stdout ?? "")
		.split("\0")
		.filter(Boolean)
		.map(normalizeRepoPath)
		.filter((file) => !isIgnoredFingerprintPath(file, "??"));

	const hasCodeFile = repositoryFiles.some((file) =>
		CODE_EXTENSIONS.has(path.extname(file).toLowerCase()),
	);
	let hasProjectMarker = repositoryFiles.some((file) =>
		PROJECT_MARKERS.has(path.basename(file)),
	);
	if (!hasProjectMarker) {
		try {
			const entries = await readdir(root, { withFileTypes: true });
			hasProjectMarker = entries.some(
				(entry) => entry.isFile() && PROJECT_MARKERS.has(entry.name),
			);
		} catch {
			// A repository that cannot be read is not a safe Graphify target.
		}
	}

	if (!hasCodeFile && !hasProjectMarker) return undefined;
	return { root, graphPath: path.join(root, GRAPHIFY_GRAPH) };
}

/**
 * Capture a comparable Git/filesystem fingerprint.
 *
 * The snapshot includes HEAD, index object IDs, porcelain status, and hashes
 * only for changed/untracked working-tree paths. Graphify output is excluded
 * at every layer, so its own update cannot trigger another update.
 */
export async function captureRepositoryFingerprint(
	exec: PiExec,
	root: string,
): Promise<string | undefined> {
	const [headResult, statusResult, indexResult] = await Promise.all([
		exec("git", ["rev-parse", "--verify", "HEAD"], { cwd: root, timeout: 5_000 }),
		exec("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], {
			cwd: root,
			timeout: 5_000,
		}),
		exec("git", ["ls-files", "-s", "-z"], { cwd: root, timeout: 5_000 }),
	]);

	if (resultCode(statusResult) !== 0) return undefined;

	const records = parsePorcelainStatus(statusResult.stdout ?? "")
		.map((record) => ({
			status: record.status,
			paths: record.paths
				.map(normalizeRepoPath)
				.filter(
					(relativePath) => !isIgnoredFingerprintPath(relativePath, record.status),
				)
				.sort(),
		}))
		.filter((record) => record.paths.length > 0)
		.sort((left, right) =>
			JSON.stringify(left).localeCompare(JSON.stringify(right)),
		);

	const pathSnapshots: PathSnapshot[] = [];
	for (const record of records) {
		for (const relativePath of record.paths) {
			pathSnapshots.push({
				path: relativePath,
				status: record.status,
				content: await snapshotPath(root, relativePath),
			});
		}
	}

	const indexEntries =
		resultCode(indexResult) === 0
			? parseIndexEntries(indexResult.stdout ?? "")
			: ["index-unavailable"];
	const head =
		resultCode(headResult) === 0 ? (headResult.stdout?.trim() ?? "") : "NO_HEAD";
	return createHash("sha256")
		.update(
			JSON.stringify({
				head,
				indexEntries,
				records,
				pathSnapshots,
			}),
		)
		.digest("hex");
}

function shortenDiagnostic(value: string): string {
	const normalized = value.replace(/\s+/g, " ").trim();
	if (normalized.length <= MAX_WARNING_DETAIL_LENGTH) return normalized;
	return `${normalized.slice(0, MAX_WARNING_DETAIL_LENGTH - 1)}…`;
}

function notifyUpdateWarning(ctx: NotifyContext, message: string): void {
	const warning = `[Graphify] ${shortenDiagnostic(message)}`;
	try {
		ctx.ui?.notify(warning, "warning");
	} catch {
		// Pi must keep the original agent result even if UI notification fails.
	}
	console.warn(warning);
}

async function fileExists(filePath: string): Promise<boolean> {
	try {
		await access(filePath);
		return true;
	} catch {
		return false;
	}
}

async function markGraphStale(root: string): Promise<void> {
	const marker = path.join(root, GRAPHIFY_OUTPUT_DIR, STALE_MARKER);
	try {
		// Exclusive creation cannot follow an existing marker symlink.
		await writeFile(
			marker,
			"Source edits observed by Pi; verify the manifest and refresh before next use.\n",
			{ encoding: "utf8", flag: "wx" },
		);
	} catch (error) {
		if (error instanceof Error && "code" in error && error.code === "EEXIST") {
			const entry = await lstat(marker);
			if (entry.isFile() && !entry.isSymbolicLink()) return;
		}
		throw error;
	}
}

export default function graphifyIntegration(
	pi: ExtensionAPI,
	processExecutor: PiExec = runProcess,
): void {
	let runState: RunState | undefined;
	let planMode = false;
	let stopped = false;
	let lifecycle = new AbortController();
	const isPlan = (_ctx: ExtensionContext) => planMode || stopped;
	const exec: PiExec = (command, args, options = {}) => {
		if (planMode || stopped)
			throw new Error(
				"Graphify execution is unavailable in Plan mode or after shutdown.",
			);
		const signal = options.signal
			? AbortSignal.any([options.signal, lifecycle.signal])
			: lifecycle.signal;
		return processExecutor(command, args, { ...options, signal });
	};
	const unsubscribe = subscribeToModeChanges(pi, (event) => {
		if (event.source !== "olisikh:modes") return;
		const nextPlan = event.mode === "plan" && event.active;
		if (nextPlan) {
			lifecycle.abort();
			runState = undefined;
		} else if (planMode) lifecycle = new AbortController();
		planMode = nextPlan;
	});
	registerGraphifyTools(pi, { exec, isPlan });

	pi.on("session_start", (_event, ctx) => {
		stopped = false;
		// Restore before hooks run, even when the modes extension loads later.
		const entries = ctx.sessionManager.getBranch();
		const mode = [...entries]
			.reverse()
			.find(
				(entry) => entry.type === "custom" && entry.customType === "olisikh:modes",
			);
		planMode =
			mode?.type === "custom" &&
			(mode.data as { mode?: string } | undefined)?.mode === "plan";
		if (planMode) lifecycle.abort();
	});

	pi.on(
		"before_agent_start",
		async (event: BeforeAgentStartEvent, ctx: ExtensionContext) => {
			runState = undefined;
			if (isPlan(ctx)) return;
			const generation = lifecycle;
			try {
				const repository = await detectRepositoryContext(exec, ctx.cwd);
				if (!repository || isPlan(ctx) || generation.signal.aborted) return;
				const initialFingerprint = await captureRepositoryFingerprint(
					exec,
					repository.root,
				);
				if (!initialFingerprint || isPlan(ctx) || generation.signal.aborted) return;
				runState = { ...repository, initialFingerprint };
				const graphExists =
					(await graphOutputState(repository.root)) === "directory" &&
					(await fileExists(repository.graphPath));
				if (isPlan(ctx) || generation.signal.aborted) return;
				return {
					systemPrompt: `${event.systemPrompt ?? ""}\n\n${buildGraphifyPolicy(graphExists)}`,
				};
			} catch {
				// Probing is advisory; ordinary source inspection must remain usable.
				runState = undefined;
			}
		},
	);

	pi.on("agent_end", async (_event: unknown, ctx: ExtensionContext) => {
		const state = runState;
		runState = undefined;
		if (!state || isPlan(ctx)) return;
		const generation = lifecycle;
		try {
			const finalFingerprint = await captureRepositoryFingerprint(
				exec,
				state.root,
			);
			if (!finalFingerprint || finalFingerprint === state.initialFingerprint)
				return;
			if (
				(await graphOutputState(state.root)) !== "directory" ||
				!(await fileExists(state.graphPath)) ||
				isPlan(ctx) ||
				generation.signal.aborted
			)
				return;
			// Metadata only: no graph rebuild, subprocess extraction, or queued turn.
			await markGraphStale(state.root);
		} catch (error) {
			if (!isPlan(ctx) && !generation.signal.aborted)
				notifyUpdateWarning(
					ctx,
					`Could not mark graph stale; the next query will verify its manifest: ${error instanceof Error ? error.message : String(error)}`,
				);
		}
	});

	pi.on("session_shutdown", () => {
		stopped = true;
		lifecycle.abort();
		unsubscribe();
		runState = undefined;
	});
}
