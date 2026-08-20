import type {
	ExtensionAPI,
	ExtensionCommandContext,
	// @ts-expect-error Pi provides this module at runtime.
} from "@earendil-works/pi-coding-agent";

type PermissionSystemGlobal = typeof globalThis & {
	__piPermissionSystem?: {
		toggleYoloMode(options?: { persist?: boolean; source?: string }): {
			error?: string;
		};
	};
};

type YoloState = { enabled: boolean; initialized: boolean };
type RuntimePermissionManager = {
	isYoloEnabled: () => boolean;
};
type RuntimePermissionService = {
	resolver?: {
		permissionManager?: RuntimePermissionManager;
	};
};
const PERMISSION_SERVICE_KEY = Symbol.for(
	"@gotgenes/pi-permission-system:service",
);
const YOLO_STATE_KEY = Symbol.for("olisikh.pi.yolo-state");
const YOLO_RENDER_KEY = Symbol.for("olisikh.pi.yolo-render");
const LOCAL_API_KEY = Symbol.for("olisikh.pi.yolo-local-api");

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

function permissionManager(): RuntimePermissionManager | undefined {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	const service = global[PERMISSION_SERVICE_KEY] as
		| RuntimePermissionService
		| undefined;
	return service?.resolver?.permissionManager;
}

function installRuntimePermissionSystem():
	| NonNullable<PermissionSystemGlobal["__piPermissionSystem"]>
	| undefined {
	const global = globalThis as PermissionSystemGlobal;
	if (global.__piPermissionSystem) return global.__piPermissionSystem;

	const toggleYoloMode = (options?: {
		persist?: boolean;
		source?: string;
	}): { error?: string } => {
		if (options?.persist === true) {
			return { error: "YOLO persistence is disabled" };
		}
		const manager = permissionManager();
		if (!manager) return { error: "permission system is not ready" };
		manager.isYoloEnabled = () => yoloState().enabled;
		yoloState().enabled = !yoloState().enabled;
		return {};
	};

	(global as typeof globalThis & Record<symbol, unknown>)[LOCAL_API_KEY] = true;
	global.__piPermissionSystem = { toggleYoloMode };
	return global.__piPermissionSystem;
}

function bindRuntimePermissionManager(): void {
	const global = globalThis as typeof globalThis &
		Record<symbol, unknown> &
		PermissionSystemGlobal;
	const officialApi =
		global.__piPermissionSystem && global[LOCAL_API_KEY] !== true;
	const manager = permissionManager();
	if (!manager) return;
	const state = yoloState();
	if (!state.initialized) {
		state.enabled = manager.isYoloEnabled();
		state.initialized = true;
	}
	if (officialApi) return;
	// ponytail: bind the current package's private reader until its public runtime API ships.
	manager.isYoloEnabled = () => yoloState().enabled;
	if (!global.__piPermissionSystem) installRuntimePermissionSystem();
}

function setYoloMode(enabled: boolean, source: string): string | undefined {
	const permissionSystem =
		(globalThis as PermissionSystemGlobal).__piPermissionSystem ??
		installRuntimePermissionSystem();
	if (!permissionSystem) {
		return "pi-permission-system runtime API is unavailable";
	}

	bindRuntimePermissionManager();
	const state = yoloState();
	if (state.enabled === enabled) return undefined;

	const result = permissionSystem.toggleYoloMode({
		persist: false,
		source,
	});
	if (result.error) return result.error;

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

	const error = setYoloMode(enabled, "yolo-command");
	if (error) {
		ctx.ui.notify(`Unable to change YOLO mode: ${error}`, "error");
		return;
	}

	ctx.ui.setStatus("pi-permission-system", enabled ? "yolo" : undefined);
}

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", () => bindRuntimePermissionManager());

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
