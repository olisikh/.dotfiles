// @ts-expect-error Pi runs this extension with Node's built-in modules.
import { mkdirSync, readFileSync, renameSync, unlinkSync, writeFileSync } from "node:fs";
// @ts-expect-error Pi runs this extension with Node's built-in modules.
import { dirname, join } from "node:path";
// @ts-expect-error Pi provides this module at runtime.
import { getAgentDir, type ExtensionAPI, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

type PermissionConfig = Record<string, unknown> & { yoloMode?: boolean };

function configPath(): string {
	return join(getAgentDir(), "extensions", "pi-permission-system", "config.json");
}

function readConfig(path: string): PermissionConfig {
	try {
		const parsed: unknown = JSON.parse(readFileSync(path, "utf8"));
		if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
			throw new Error("config root must be an object");
		}
		return parsed as PermissionConfig;
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		throw new Error(`cannot read ${path}: ${message}`);
	}
}

function writeYoloMode(path: string, enabled: boolean): void {
	const config = readConfig(path);
	const temporaryPath = `${path}.tmp`;

	mkdirSync(dirname(path), { recursive: true });
	writeFileSync(
		temporaryPath,
		`${JSON.stringify({ ...config, yoloMode: enabled }, null, 2)}\n`,
		{ encoding: "utf8", mode: 0o600 },
	);

	try {
		renameSync(temporaryPath, path);
	} catch (error) {
		try {
			unlinkSync(temporaryPath);
		} catch {
			// Preserve the original error.
		}
		throw error;
	}
}

async function setYoloMode(
	requested: string,
	ctx: ExtensionCommandContext,
): Promise<void> {
	const path = configPath();
	const current = readConfig(path).yoloMode === true;
	const value = requested.trim().toLowerCase();
	let enabled: boolean;
	if (value === "on") {
		enabled = true;
	} else if (value === "off") {
		enabled = false;
	} else if (value === "") {
		enabled = !current;
	} else {
		ctx.ui.notify("Usage: /yolo [on|off]", "warning");
		return;
	}

	writeYoloMode(path, enabled);
	ctx.ui.notify(`YOLO mode ${enabled ? "enabled" : "disabled"}.`, "info");
	await ctx.reload();
}

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("yolo", {
		description: "Toggle permission-system YOLO mode",
		getArgumentCompletions: (prefix: string) => {
			const normalized = prefix.trim().toLowerCase();
			return ["on", "off"].flatMap((value) =>
				value.startsWith(normalized) ? [{ value, label: value }] : [],
			);
		},
		handler: async (args: string, ctx: ExtensionCommandContext) =>
			setYoloMode(args, ctx),
	});

	pi.registerShortcut("ctrl+alt+y", {
		description: "Toggle permission-system YOLO mode",
		handler: async () => {
			pi.sendUserMessage("/yolo");
		},
	});
}
