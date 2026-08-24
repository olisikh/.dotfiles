// @ts-ignore Pi provides this module to extensions at runtime.
import type { TUI } from "@earendil-works/pi-tui";

/** The TUI capability needed by renderers that trigger a refresh. */
export type PiRenderTui = Pick<TUI, "requestRender">;
