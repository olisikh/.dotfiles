// @ts-ignore Pi provides this module to extensions at runtime.
import type {
	ExtensionWidgetOptions,
	Theme,
} from "@earendil-works/pi-coding-agent";
// @ts-ignore Pi provides this module to extensions at runtime.
import type { Component, TUI } from "@earendil-works/pi-tui";

export type PiWidget = Component & { dispose?(): void };
export type PiWidgetFactory = (tui: TUI, theme: Theme) => PiWidget;
export type PiWidgetContent = string[] | PiWidgetFactory | undefined;
export type PiWidgetOptions = ExtensionWidgetOptions | undefined;
export type PiWidgetUi = {
	setWidget: (
		key: string,
		widget: PiWidgetContent,
		options?: PiWidgetOptions,
	) => void;
};
