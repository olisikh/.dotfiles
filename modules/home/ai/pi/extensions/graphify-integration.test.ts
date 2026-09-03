import { afterEach, describe, expect, it } from "bun:test";
import { execFile, execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import {
	captureRepositoryFingerprint,
	default as graphifyIntegration,
} from "./graphify-integration";

type ExecResult = { stdout: string; stderr: string; code: number };
type ExecOptions = { cwd?: string };
type Handler = (event: unknown, ctx: { cwd: string; ui: { notify: (...args: string[]) => void } }) => Promise<unknown> | unknown;

type PiStub = {
	handlers: Map<string, Handler>;
	calls: Array<{ command: string; args: string[]; options?: ExecOptions }>;
	notifications: string[];
	pi: {
		on: (event: string, handler: Handler) => void;
		exec: (command: string, args: string[], options?: ExecOptions) => Promise<ExecResult>;
	};
};

const temporaryRoots: string[] = [];

function runGit(root: string, args: string[]): string {
	return execFileSync("git", args, { cwd: root, encoding: "utf8" });
}

function createGitProject(options: { code?: boolean } = {}): string {
	const root = mkdtempSync(path.join(tmpdir(), "pi-graphify-integration-"));
	temporaryRoots.push(root);
	runGit(root, ["init", "-q"]);
	runGit(root, ["config", "user.email", "pi-graphify-tests@example.com"]);
	runGit(root, ["config", "user.name", "Pi Graphify Tests"]);
	if (options.code !== false) {
		writeFileSync(path.join(root, "package.json"), '{"name":"graphify-test"}\n');
		mkdirSync(path.join(root, "src"));
		writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 3;\n");
	} else {
		writeFileSync(path.join(root, "README.md"), "Notes only.\n");
	}
	runGit(root, ["add", "."]);
	runGit(root, ["commit", "-qm", "initial"]);
	return root;
}

function createPiStub(updateResult: ExecResult = { stdout: "", stderr: "", code: 0 }): PiStub {
	const handlers = new Map<string, Handler>();
	const calls: PiStub["calls"] = [];
	const notifications: string[] = [];
	const pi = {
		on(event: string, handler: Handler) {
			handlers.set(event, handler);
		},
		exec(command: string, args: string[], options?: ExecOptions): Promise<ExecResult> {
			calls.push({ command, args, options });
			if (command === "graphify") return Promise.resolve(updateResult);
			return new Promise((resolve) => {
				execFile(command, args, { cwd: options?.cwd, encoding: "utf8" }, (error, stdout, stderr) => {
					resolve({
						stdout: String(stdout),
						stderr: String(stderr),
						code: typeof error?.code === "number" ? error.code : error ? 1 : 0,
					});
				});
			});
		},
	};
	return { handlers, calls, notifications, pi };
}

function createGraph(root: string): void {
	mkdirSync(path.join(root, "graphify-out"));
	writeFileSync(path.join(root, "graphify-out", "graph.json"), '{"nodes":[]}\n');
}

async function runBeforeAndEnd(
	stub: PiStub,
	cwd: string,
	mutate?: () => void,
): Promise<{ before: unknown; end: unknown }> {
	const ctx = { cwd, ui: { notify: (...args: string[]) => stub.notifications.push(args.join(" ")) } };
	const before = await stub.handlers.get("before_agent_start")?.({ systemPrompt: "base prompt" }, ctx);
	mutate?.();
	const end = await stub.handlers.get("agent_end")?.({}, ctx);
	return { before, end };
}

afterEach(() => {
	while (temporaryRoots.length > 0) {
		rmSync(temporaryRoots.pop() as string, { recursive: true, force: true });
	}
});

describe("automatic Graphify integration", () => {
	it("injects the concise Graphify policy when a code repository has no graph", async () => {
		const root = createGitProject();
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		const { before } = await runBeforeAndEnd(stub, root);
		const prompt = (before as { systemPrompt: string }).systemPrompt;

		expect(prompt).toContain("Graphify is the default mechanism");
		expect(prompt).toContain("graphify-out/graph.json");
		expect(prompt).toContain("installed `graphify` skill");
		expect(prompt).toContain("graphify_build");
		expect(prompt).toContain("graphify_query");
		expect(prompt).toContain("Graph state at this run's start: absent.");
		expect(stub.calls.filter(({ command }) => command === "graphify")).toHaveLength(0);
	});

	it("tells the agent to query an existing graph before broad exploration", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		const { before } = await runBeforeAndEnd(stub, root);
		const prompt = (before as { systemPrompt: string }).systemPrompt;

		expect(prompt).toContain("If the graph exists, consult Graphify before broad");
		expect(prompt).toContain("graphify_query");
		expect(prompt).toContain("graphify_path");
		expect(prompt).toContain("Graph state at this run's start: present.");
	});

	it("updates an existing graph after an unstaged tracked source change", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, root, () => {
			writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 5;\n");
		});

		expect(stub.calls.filter(({ command }) => command === "graphify")).toEqual([
			expect.objectContaining({
				command: "graphify",
				args: ["update", "."],
				options: expect.objectContaining({ cwd: realpathSync(root) }),
			}),
		]);
	});

	it("does not update when the final source state is unchanged", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, root);

		expect(stub.calls.filter(({ command }) => command === "graphify")).toHaveLength(0);
	});

	it("does not update when a changed file is restored exactly", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, root, () => {
			writeFileSync(path.join(root, "src", "service.ts"), "temporary change\n");
			writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 3;\n");
		});

		expect(stub.calls.filter(({ command }) => command === "graphify")).toHaveLength(0);
	});

	it("ignores changes under graphify-out", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, root, () => {
			writeFileSync(path.join(root, "graphify-out", "GRAPH_REPORT.md"), "generated\n");
			writeFileSync(path.join(root, "graphify-out", "graph.json"), '{"nodes":[{"id":"generated"}]}\n');
		});

		expect(stub.calls.filter(({ command }) => command === "graphify")).toHaveLength(0);
	});

	it("updates for a newly created untracked source file", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, root, () => {
			writeFileSync(path.join(root, "src", "new-service.ts"), "export const newService = true;\n");
		});

		expect(stub.calls.filter(({ command }) => command === "graphify")).toHaveLength(1);
	});

	it("detects staged changes and deletions in the repository fingerprint", async () => {
		const root = createGitProject();
		const stub = createPiStub();
		const before = await captureRepositoryFingerprint(stub.pi.exec, root);

		writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 4;\n");
		runGit(root, ["add", "src/service.ts"]);
		const staged = await captureRepositoryFingerprint(stub.pi.exec, root);
		expect(staged).not.toBe(before);

		runGit(root, ["rm", "-fq", "src/service.ts"]);
		const deleted = await captureRepositoryFingerprint(stub.pi.exec, root);
		expect(deleted).not.toBe(staged);
	});

	it("runs update from the repository root when Pi starts in a nested directory", async () => {
		const root = createGitProject();
		const nested = path.join(root, "packages", "payments");
		mkdirSync(nested, { recursive: true });
		createGraph(root);
		const stub = createPiStub();
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await runBeforeAndEnd(stub, nested, () => {
			writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 6;\n");
		});

		const update = stub.calls.find(({ command }) => command === "graphify");
		expect(update?.options?.cwd).toBe(realpathSync(root));
	});

	it("preserves the agent result and reports a concise warning when update fails", async () => {
		const root = createGitProject();
		createGraph(root);
		const stub = createPiStub({ stdout: "", stderr: "graphify unavailable", code: 127 });
		graphifyIntegration(stub.pi as never, stub.pi.exec);

		await expect(
			runBeforeAndEnd(stub, root, () => {
				writeFileSync(path.join(root, "src", "service.ts"), "export const retry = 7;\n");
			}),
		).resolves.toBeDefined();
		expect(stub.notifications.join("\n")).toContain("Graphify update skipped");
		expect(stub.notifications.join("\n")).toContain("graphify unavailable");
	});

	it("does not activate in a non-code repository or a non-repository directory", async () => {
		const docsRoot = createGitProject({ code: false });
		const docsStub = createPiStub();
		graphifyIntegration(docsStub.pi as never);
		const docsBefore = await docsStub.handlers.get("before_agent_start")?.(
			{ systemPrompt: "base prompt" },
			{ cwd: docsRoot, ui: { notify: () => undefined } },
		);
		expect(docsBefore).toBeUndefined();

		const plainRoot = mkdtempSync(path.join(tmpdir(), "pi-graphify-plain-"));
		temporaryRoots.push(plainRoot);
		writeFileSync(path.join(plainRoot, "notes.txt"), "not source code\n");
		const plainStub = createPiStub();
		graphifyIntegration(plainStub.pi as never);
		const plainBefore = await plainStub.handlers.get("before_agent_start")?.(
			{ systemPrompt: "base prompt" },
			{ cwd: plainRoot, ui: { notify: () => undefined } },
		);
		expect(plainBefore).toBeUndefined();
	});
});
