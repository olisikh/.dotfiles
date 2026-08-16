type ModeEventBus = {
	events: {
		on: (channel: string, handler: (value: unknown) => void) => () => void;
	};
};

export const MODE_CHANGED_EVENT = "pi:mode-changed" as const;

export interface ModeChangedEvent {
	version: 1;
	source: string;
	mode: string;
	state: string;
	active: boolean;
}

export function isModeChangedEvent(value: unknown): value is ModeChangedEvent {
	if (!value || typeof value !== "object" || Array.isArray(value)) return false;
	const event = value as Record<string, unknown>;
	return (
		event.version === 1 &&
		safeField(event.source) &&
		safeField(event.mode) &&
		safeField(event.state) &&
		typeof event.active === "boolean"
	);
}

export function subscribeToModeChanges(
	pi: ModeEventBus,
	onChange: (event: ModeChangedEvent) => void,
) {
	return pi.events.on(MODE_CHANGED_EVENT, (value: unknown) => {
		if (isModeChangedEvent(value)) onChange(value);
	});
}

function safeField(value: unknown): value is string {
	return (
		typeof value === "string" &&
		value.length > 0 &&
		value.length <= 64 &&
		!/[\u0000-\u001f\u007f]/u.test(value)
	);
}
