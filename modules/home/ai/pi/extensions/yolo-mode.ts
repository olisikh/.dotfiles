const UPPER_STATUS_EVENT = "olisikh:upper-status-changed";

type ExtensionAPI = {
	on: (event: string, handler: (...args: unknown[]) => void) => void;
	events: {
		emit: (channel: string, value: unknown) => void;
		on: (channel: string, handler: (...args: unknown[]) => void) => () => void;
	};
	registerCommand: (name: string, command: unknown) => void;
	registerShortcut: (name: string, shortcut: unknown) => void;
	sendUserMessage: (message: string) => void;
};

type ExtensionCommandContext = {
	ui: {
		notify: (message: string, level: "warning" | "error") => void;
		setStatus: (key: string, value: string | undefined) => void;
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
	session?: {
		config?: { yoloMode?: boolean };
	};
};
const PERMISSION_SERVICE_KEY = Symbol.for(
	"@gotgenes/pi-permission-system:service",
);
const YOLO_STATE_KEY = Symbol.for("olisikh.pi.yolo-state");

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

function publishYoloState(pi: ExtensionAPI, enabled: boolean): void {
	pi.events.emit(UPPER_STATUS_EVENT, { version: 1, source: "yolo", enabled });
}

function setYoloMode(enabled: boolean): string | undefined {
	if (!permissionManager()) return "permission system is not ready";

	bindRuntimePermissionManager();
	const state = yoloState();
	if (state.enabled === enabled) return undefined;

	state.enabled = enabled;
	bindRuntimePermissionManager();
	return undefined;
}

async function handleYolo(
	pi: ExtensionAPI,
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

	publishYoloState(pi, isYoloModeEnabled());
	ctx.ui.setStatus("pi-permission-system", enabled ? "yolo" : undefined);
}

export default function (pi: ExtensionAPI): void {
	const syncYoloState = () => {
		bindRuntimePermissionManager();
		publishYoloState(pi, isYoloModeEnabled());
	};
	pi.on("session_start", syncYoloState);
	pi.events.on("permissions:ready", syncYoloState);

	pi.registerCommand("yolo", {
		description: "Toggle permission-system YOLO mode for this Pi process",
		getArgumentCompletions: (prefix: string) => {
			const normalized = prefix.trim().toLowerCase();
			return ["on", "off"].flatMap((value) =>
				value.startsWith(normalized) ? [{ value, label: value }] : [],
			);
		},
		handler: async (args: string, ctx: ExtensionCommandContext) =>
			handleYolo(pi, args, ctx),
	});

	pi.registerShortcut("ctrl+alt+y", {
		description: "Toggle permission-system YOLO mode",
		handler: async () => {
			pi.sendUserMessage("/yolo");
		},
	});
}
