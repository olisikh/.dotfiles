// @ts-ignore Pi provides this module at runtime.
import type {
	ExtensionAPI,
	ExtensionContext,
	SessionStartEvent,
} from "@mariozechner/pi-coding-agent";
import {
	PI_EXTENSION_ENTRIES,
	PI_EXTENSION_EVENTS,
	PI_RUNTIME_SYMBOLS,
	PI_STATUS_KEYS,
} from "./lib/pi-constants.ts";
import { PI_THEME_COLORS } from "./lib/pi-theme.ts";

const UPPER_STATUS_EVENT = PI_EXTENSION_EVENTS.upperStatusChanged;
type YoloState = { enabled: boolean };
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
const PERMISSION_SERVICE_KEY = PI_RUNTIME_SYMBOLS.permissionService;
const YOLO_STATE_KEY = PI_RUNTIME_SYMBOLS.yoloState;
const YOLO_STATE_ENTRY = PI_EXTENSION_ENTRIES.yoloState;

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function restoreYoloState(ctx: ExtensionContext): boolean {
	const entries = ctx.sessionManager.getEntries();
	for (let index = entries.length - 1; index >= 0; index -= 1) {
		const entry = entries[index];
		if (
			entry.type === "custom" &&
			entry.customType === YOLO_STATE_ENTRY &&
			isRecord(entry.data) &&
			typeof entry.data.enabled === "boolean"
		) {
			return entry.data.enabled;
		}
	}
	return false;
}

function yoloState(): YoloState {
	const global = globalThis as typeof globalThis & Record<symbol, unknown>;
	const existing = global[YOLO_STATE_KEY] as YoloState | undefined;
	if (existing) return existing;

	const state = { enabled: false };
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
	// ponytail: bind the current package's private readers until its public runtime API ships.
	manager.isYoloEnabled = () => yoloState().enabled;
	const runtimeConfig = permissionService()?.session?.config;
	if (runtimeConfig) runtimeConfig.yoloMode = state.enabled;
}

function publishYoloState(pi: ExtensionAPI, enabled: boolean): void {
	pi.events.emit(UPPER_STATUS_EVENT, {
		version: 1,
		source: PI_STATUS_KEYS.yolo,
		enabled,
	});
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
	ctx: ExtensionContext,
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
		ctx.ui.notify("Usage: /yolo [on|off]", PI_THEME_COLORS.warning);
		return;
	}

	const error = setYoloMode(enabled);
	if (error) {
		ctx.ui.notify(`Unable to change YOLO mode: ${error}`, PI_THEME_COLORS.error);
		return;
	}

	pi.appendEntry(YOLO_STATE_ENTRY, { enabled });
	publishYoloState(pi, isYoloModeEnabled());
	ctx.ui.setStatus(
		PI_STATUS_KEYS.permissionSystem,
		enabled ? PI_STATUS_KEYS.yolo : undefined,
	);
}

export default function (pi: ExtensionAPI): void {
	const syncRuntimeYoloState = () => {
		bindRuntimePermissionManager();
		publishYoloState(pi, isYoloModeEnabled());
	};
	pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext) => {
		yoloState().enabled = restoreYoloState(ctx);
		syncRuntimeYoloState();
	});
	pi.events.on(PI_EXTENSION_EVENTS.permissionsReady, syncRuntimeYoloState);

	pi.registerCommand("yolo", {
		description: "Toggle permission-system YOLO mode for the current Pi session",
		getArgumentCompletions: (prefix: string) => {
			const normalized = prefix.trim().toLowerCase();
			return ["on", "off"].flatMap((value) =>
				value.startsWith(normalized) ? [{ value, label: value }] : [],
			);
		},
		handler: async (args: string, ctx: ExtensionContext) =>
			handleYolo(pi, args, ctx),
	});

	pi.registerShortcut("ctrl+alt+y", {
		description: "Toggle permission-system YOLO mode",
		handler: async (ctx: ExtensionContext) => handleYolo(pi, "", ctx),
	});
}
