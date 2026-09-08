// Pi supplies TypeBox to extensions, but standalone Bun tests do not use Pi's
// loader. Resolve the real installed dependency without installing into Nix's
// read-only extension tree or substituting fake schema implementations.
import { mock } from "bun:test";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const agentDir = process.env.PI_CODING_AGENT_DIR || path.join(homedir(), ".pi", "agent");
const runtime = createRequire(path.join(agentDir, "npm", "package.json"));
const typebox = await import(pathToFileURL(runtime.resolve("typebox")).href);
mock.module("typebox", () => typebox);
