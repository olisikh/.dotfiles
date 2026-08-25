// @ts-ignore Pi provides this module to extensions at runtime.
import type { Theme, ThemeColor } from "@earendil-works/pi-coding-agent";

/**
 * The canonical Pi theme surface, narrowed to the capabilities each
 * extension actually needs. Keep these aliases capability-oriented so a
 * renderer can share a type without depending on another extension.
 */
export type PiThemeColor = ThemeColor;
export type PiTheme = Theme;
export type PiForegroundTheme = Pick<Theme, "fg">;
export type PiTextTheme = Pick<Theme, "fg" | "bold">;
export type PiItalicTheme = Pick<Theme, "fg" | "italic">;
export type PiInverseTheme = Pick<Theme, "fg" | "inverse">;

/**
 * Pi theme tokens used by these extensions. Keep upstream-facing names in one
 * place so a Pi theme rename is a single, type-checked change.
 */
export const PI_THEME_COLORS = {
	accent: "accent",
	bashMode: "bashMode",
	dim: "dim",
	error: "error",
	mdLink: "mdLink",
	muted: "muted",
	success: "success",
	toolOutput: "toolOutput",
	toolTitle: "toolTitle",
	toolDiffAdded: "toolDiffAdded",
	toolDiffRemoved: "toolDiffRemoved",
	toolDiffContext: "toolDiffContext",
	warning: "warning",
	syntaxComment: "syntaxComment",
	syntaxKeyword: "syntaxKeyword",
	syntaxFunction: "syntaxFunction",
	syntaxVariable: "syntaxVariable",
	syntaxString: "syntaxString",
	syntaxNumber: "syntaxNumber",
	syntaxType: "syntaxType",
	syntaxOperator: "syntaxOperator",
	syntaxPunctuation: "syntaxPunctuation",
} as const satisfies Record<string, PiThemeColor>;

export type PiNamedThemeColor =
	(typeof PI_THEME_COLORS)[keyof typeof PI_THEME_COLORS];

/** Catppuccin Mocha colors used by the working indicator. */
export const CATPPUCCIN_MOCHA = {
	blue: "#89b4fa",
	green: "#a6e3a1",
	lavender: "#b4befe",
	mauve: "#cba6f7",
	peach: "#fab387",
	red: "#f38ba8",
	teal: "#94e2d5",
	yellow: "#f9e2af",
} as const;

export const CATPPUCCIN_MOCHA_PALETTE = [
	CATPPUCCIN_MOCHA.mauve,
	CATPPUCCIN_MOCHA.lavender,
	CATPPUCCIN_MOCHA.blue,
	CATPPUCCIN_MOCHA.teal,
	CATPPUCCIN_MOCHA.green,
	CATPPUCCIN_MOCHA.yellow,
	CATPPUCCIN_MOCHA.peach,
] as const;
