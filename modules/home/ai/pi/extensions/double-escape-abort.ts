import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";

const DEFAULT_DOUBLE_ESCAPE_WINDOW_MS = 3_000;
const DOUBLE_ESCAPE_WINDOW_MS = readWindowMs();
const ARM_WIDGET_ID = "double-escape-abort";
const ARM_MESSAGE = "Press ESC again to cancel";
const CURSOR_BLINK_MS = 500;
const CURSOR_TRANSITION_STEPS = 10;
const CURSOR_SYMBOL = "█";
const WORKING_CURSOR_SYMBOL = "░";
const FAKE_CURSOR = /\x1b\[7m([^\x1b]*)\x1b\[(?:0|27)m/g;
const RESET_COLOR = "\x1b[39m";

type EscapeStateChange = (armed: boolean) => void;

function readWindowMs(): number {
	const configured = Number.parseInt(process.env.PI_DOUBLE_ESCAPE_WINDOW_MS ?? "", 10);
	return Number.isFinite(configured) && configured > 0 ? configured : DEFAULT_DOUBLE_ESCAPE_WINDOW_MS;
}

class DoubleEscapeEditor extends CustomEditor {
	private armedAt: number | undefined;
	private expiryTimer: ReturnType<typeof setTimeout> | undefined;
	private cursorStep = 0;
	private cursorTimer: ReturnType<typeof setTimeout> | undefined;
	private working = false;

	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		keybindings: ConstructorParameters<typeof CustomEditor>[2],
		private readonly isIdle: () => boolean,
		private readonly onEscapeStateChange: EscapeStateChange,
	) {
		super(tui, theme, keybindings);
		this.scheduleCursorBlink();
	}

	override render(width: number): string[] {
		const replacement = this.working
			? paintCursor(WORKING_CURSOR_SYMBOL, 110)
			: paintCursor(CURSOR_SYMBOL, cursorBrightness(this.cursorStep));

		return super.render(width).map((line) => line.replace(FAKE_CURSOR, replacement));
	}

	private disarmEscape(): void {
		const wasArmed = this.armedAt !== undefined;
		this.armedAt = undefined;
		if (this.expiryTimer) {
			clearTimeout(this.expiryTimer);
			this.expiryTimer = undefined;
		}
		if (wasArmed) {
			this.onEscapeStateChange(false);
		}
	}

	private armEscape(now: number): void {
		this.disarmEscape();
		this.armedAt = now;
		this.onEscapeStateChange(true);
		this.expiryTimer = setTimeout(() => {
			if (this.armedAt !== now) return;
			this.disarmEscape();
		}, DOUBLE_ESCAPE_WINDOW_MS);
	}

	clearEscapeState(): void {
		this.disarmEscape();
	}

	setWorking(working: boolean): void {
		if (this.working === working) return;
		this.working = working;
		this.stopCursorBlink();
		this.cursorStep = 0;
		if (!working) this.scheduleCursorBlink();
		this.tui.requestRender();
	}

	dispose(): void {
		this.disarmEscape();
		this.stopCursorBlink();
	}

	private stopCursorBlink(): void {
		if (this.cursorTimer) clearTimeout(this.cursorTimer);
		this.cursorTimer = undefined;
	}

	private scheduleCursorBlink(): void {
		this.cursorTimer = setTimeout(() => {
			if (this.working) return;
			this.cursorStep = (this.cursorStep + 1) % (CURSOR_TRANSITION_STEPS * 2);
			this.tui.requestRender();
			this.scheduleCursorBlink();
		}, CURSOR_BLINK_MS / CURSOR_TRANSITION_STEPS);
	}

	override handleInput(data: string): void {
		const isInterrupt = this.keybindings.matches(data, "app.interrupt");

		// Preserve normal editor behavior, including the first Escape closing
		// autocomplete and the built-in idle double-Escape action.
		if (!isInterrupt || this.isShowingAutocomplete()) {
			this.disarmEscape();
			super.handleInput(data);
			return;
		}
		if (this.isIdle()) {
			this.disarmEscape();
			super.handleInput(data);
			return;
		}

		const now = Date.now();
		if (this.armedAt !== undefined && now - this.armedAt < DOUBLE_ESCAPE_WINDOW_MS) {
			this.disarmEscape();
			super.handleInput(data);
			return;
		}

		// While the agent is active, the first Escape only arms cancellation.
		this.armEscape(now);
	}
}

function cursorBrightness(step: number): number {
	const progress = step < CURSOR_TRANSITION_STEPS
		? step / CURSOR_TRANSITION_STEPS
		: (CURSOR_TRANSITION_STEPS * 2 - step) / CURSOR_TRANSITION_STEPS;
	return Math.round(255 * progress);
}

function paintCursor(symbol: string, brightness: number): string {
	if (brightness === 0) return "$1";
	return `\x1b[38;2;${brightness};${brightness};${brightness}m${symbol}${RESET_COLOR}`;
}

export default function (pi: ExtensionAPI) {
	let editor: DoubleEscapeEditor | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			editor = new DoubleEscapeEditor(
				tui,
				theme,
				keybindings,
				ctx.isIdle,
				(armed) => {
					ctx.ui.setWidget(
						ARM_WIDGET_ID,
						armed ? (_tui, theme) => new Text(theme.fg("dim", ARM_MESSAGE), 0, 0) : undefined,
						{ placement: "belowEditor" },
					);
				},
			);
			return editor;
		});
	});

	// Clear the prompt whenever the active run ends or the session runtime is
	// replaced, so a stale cancellation hint cannot remain on screen.
	pi.on("agent_start", () => {
		editor?.clearEscapeState();
		editor?.setWorking(true);
	});
	pi.on("agent_settled", () => {
		editor?.clearEscapeState();
		editor?.setWorking(false);
	});
	pi.on("session_shutdown", () => editor?.dispose());
}
