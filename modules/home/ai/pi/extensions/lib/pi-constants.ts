export const PI_VIM_MODES = {
	insert: "insert",
	normal: "normal",
	visual: "visual",
	visualLine: "visual-line",
	ex: "ex",
} as const;

export type PiVimMode = (typeof PI_VIM_MODES)[keyof typeof PI_VIM_MODES];

export const PI_MODE_STATUSES = {
	build: "build",
	plan: "plan",
	goal: "goal",
	unknown: "unknown",
	off: "off",
	planMode: "plan-mode",
} as const;

export type PiModeStatus =
	(typeof PI_MODE_STATUSES)[keyof typeof PI_MODE_STATUSES];

export const PI_WORKING_PHASES = {
	requesting: "requesting",
	thinking: "thinking",
	responding: "responding",
	toolUse: "tool-use",
} as const;

export type PiWorkingPhase =
	(typeof PI_WORKING_PHASES)[keyof typeof PI_WORKING_PHASES];

export const PI_WORKING_INDICATOR_TYPES = {
	shimmer: "shimmer",
	spinner: "spinner",
} as const;

export type PiWorkingIndicatorType =
	(typeof PI_WORKING_INDICATOR_TYPES)[keyof typeof PI_WORKING_INDICATOR_TYPES];

export const PI_WORKING_COLOR_MODES = {
	none: "none",
	rotate: "rotate",
	rainbow: "rainbow",
} as const;

export type PiWorkingColorMode =
	(typeof PI_WORKING_COLOR_MODES)[keyof typeof PI_WORKING_COLOR_MODES];

export const PI_STATUS_KEYS = {
	permissionSystem: "pi-permission-system",
	yolo: "yolo",
} as const;

export const PI_EXTENSION_EVENTS = {
	modeChanged: "pi:mode-changed",
	permissionsReady: "permissions:ready",
	upperStatusChanged: "olisikh:upper-status-changed",
} as const;

export const PI_EXTENSION_ENTRIES = {
	upperStatusMcpHistory: "olisikh:upper-status-mcps",
	yoloState: "olisikh:yolo-state",
} as const;

export const PI_RUNTIME_SYMBOLS = {
	permissionServices: Symbol.for(
		"@gotgenes/pi-permission-system:session-services",
	),
	yoloState: Symbol.for("olisikh.pi.yolo-state"),
} as const;

export const PI_WIDGET_KEYS = {
	planModePlan: "plan-mode-plan",
	upperStatusline: "zz-olisikh-upper-statusline",
} as const;

export const PI_WIDGET_PLACEMENTS = {
	belowEditor: "belowEditor",
} as const;
