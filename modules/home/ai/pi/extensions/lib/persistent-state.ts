// prettier-ignore
import {
	existsSync,
	mkdirSync,
	readFileSync,
	renameSync,
	writeFileSync,
	// @ts-ignore Pi provides Node built-ins at runtime.
} from "node:fs";
// @ts-ignore Pi provides Node built-ins at runtime.
import { homedir } from "node:os";
// @ts-ignore Pi provides Node built-ins at runtime.
import { join } from "node:path";

declare const process: { pid: number };

const STATE_FILE = join(homedir(), ".pi", "agent", "upper-status-state.json");

type PersistentPiState = {
	yoloEnabled?: boolean;
};

function defaultState(): PersistentPiState {
	return {};
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

export function loadPersistentPiState(): PersistentPiState {
	if (!existsSync(STATE_FILE)) return defaultState();

	try {
		const value: unknown = JSON.parse(readFileSync(STATE_FILE, "utf8"));
		if (!isRecord(value)) return defaultState();

		return typeof value.yoloEnabled === "boolean"
			? { yoloEnabled: value.yoloEnabled }
			: defaultState();
	} catch {
		return defaultState();
	}
}

function savePersistentPiState(state: PersistentPiState): void {
	try {
		mkdirSync(join(homedir(), ".pi", "agent"), { recursive: true });
		const temporaryFile = `${STATE_FILE}.${process.pid}.tmp`;
		writeFileSync(temporaryFile, `${JSON.stringify(state)}\n`, {
			encoding: "utf8",
			mode: 0o600,
		});
		renameSync(temporaryFile, STATE_FILE);
	} catch {
		// The status widget must remain usable if its optional state file cannot be written.
	}
}

export function saveYoloMode(yoloEnabled: boolean): void {
	savePersistentPiState({ yoloEnabled });
}
