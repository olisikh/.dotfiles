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
