import type {
	ExtensionAPI,
	ExtensionCommandContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@earendil-works/pi-coding-agent";

type YoloState = { enabled: boolean; initialized: boolean };
type RuntimePermissionManager = {
	isYoloEnabled: () => boolean;
};
type RuntimePermissionService = {
	resolver?: {
		permissionManager?: RuntimePermissionManager;
	};
	session?: {
		config?: { yoloMode?: boolean };
	};
};
const PERMISSION_SERVICE_KEY = Symbol.for(
	"@gotgenes/pi-permission-system:service",
);
const YOLO_STATE_KEY = Symbol.for("olisikh.pi.yolo-state");
const YOLO_RENDER_KEY = Symbol.for("olisikh.pi.yolo-render");

function yoloState(): YoloState {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	const existing = global[YOLO_STATE_KEY] as YoloState | undefined;
	if (existing) return existing;

	const state = { enabled: false, initialized: false };
	global[YOLO_STATE_KEY] = state;
	return state;
}

export function isYoloModeEnabled(): boolean {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	return (global[YOLO_STATE_KEY] as YoloState | undefined)?.enabled === true;
}

function requestYoloRender(): void {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	const requestRender = global[YOLO_RENDER_KEY];
	if (typeof requestRender === "function") requestRender();
}

function permissionService(): RuntimePermissionService | undefined {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	return global[PERMISSION_SERVICE_KEY] as RuntimePermissionService | undefined;
}

function permissionManager(): RuntimePermissionManager | undefined {
	return permissionService()?.resolver?.permissionManager;
}

function bindRuntimePermissionManager(): void {
	const manager = permissionManager();
	if (!manager) return;
	const state = yoloState();
	if (!state.initialized) {
		state.enabled = manager.isYoloEnabled();
		state.initialized = true;
	}
	// ponytail: bind the current package's private readers until its public runtime API ships.
	manager.isYoloEnabled = () => yoloState().enabled;
	const runtimeConfig = permissionService()?.session?.config;
	if (runtimeConfig) runtimeConfig.yoloMode = state.enabled;
}

function setYoloMode(enabled: boolean): string | undefined {
	if (!permissionManager()) return "permission system is not ready";

	bindRuntimePermissionManager();
	const state = yoloState();
	if (state.enabled === enabled) return undefined;

	state.enabled = enabled;
	bindRuntimePermissionManager();
	requestYoloRender();
	return undefined;
}

async function handleYolo(
	requested: string,
	ctx: ExtensionCommandContext,
): Promise<void> {
	const value = requested.trim().toLowerCase();
	const state = yoloState();
	let enabled: boolean;
	if (value === "on") {
		enabled = true;
	} else if (value === "off") {
		enabled = false;
	} else if (value === "") {
		enabled = !state.enabled;
	} else {
		ctx.ui.notify("Usage: /yolo [on|off]", "warning");
		return;
	}

	const error = setYoloMode(enabled);
	if (error) {
		ctx.ui.notify(`Unable to change YOLO mode: ${error}`, "error");
		return;
	}

	ctx.ui.setStatus("pi-permission-system", enabled ? "yolo" : undefined);
}

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", () => bindRuntimePermissionManager());
	pi.events.on("permissions:ready", () => bindRuntimePermissionManager());

	pi.registerCommand("yolo", {
		description: "Toggle permission-system YOLO mode for this Pi process",
		getArgumentCompletions: (prefix: string) => {
			const normalized = prefix.trim().toLowerCase();
			return ["on", "off"].flatMap((value) =>
				value.startsWith(normalized) ? [{ value, label: value }] : [],
			);
		},
		handler: async (args: string, ctx: ExtensionCommandContext) =>
			handleYolo(args, ctx),
	});

	pi.registerShortcut("ctrl+alt+y", {
		description: "Toggle permission-system YOLO mode",
		handler: async () => {
			pi.sendUserMessage("/yolo");
		},
	});
}
