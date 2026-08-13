import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_DOUBLE_ESCAPE_WINDOW_MS = 3_000;
const DOUBLE_ESCAPE_WINDOW_MS = readWindowMs();
const ARM_WIDGET_ID = "double-escape-abort";
const ARM_MESSAGE = "Press ESC again to cancel";

type EscapeStateChange = (armed: boolean) => void;

function readWindowMs(): number {
	const configured = Number.parseInt(process.env.PI_DOUBLE_ESCAPE_WINDOW_MS ?? "", 10);
	return Number.isFinite(configured) && configured > 0 ? configured : DEFAULT_DOUBLE_ESCAPE_WINDOW_MS;
}

class DoubleEscapeEditor extends CustomEditor {
	private armedAt: number | undefined;
	private expiryTimer: ReturnType<typeof setTimeout> | undefined;

	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		keybindings: ConstructorParameters<typeof CustomEditor>[2],
		private readonly isIdle: () => boolean,
		private readonly onEscapeStateChange: EscapeStateChange,
	) {
		super(tui, theme, keybindings);
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
					ctx.ui.setWidget(ARM_WIDGET_ID, armed ? [ARM_MESSAGE] : undefined, { placement: "belowEditor" });
				},
			);
			return editor;
		});
	});

	// Clear the prompt whenever the active run ends or the session runtime is
	// replaced, so a stale cancellation hint cannot remain on screen.
	pi.on("agent_start", () => editor?.clearEscapeState());
	pi.on("agent_end", () => editor?.clearEscapeState());
	pi.on("session_shutdown", () => editor?.clearEscapeState());
}
