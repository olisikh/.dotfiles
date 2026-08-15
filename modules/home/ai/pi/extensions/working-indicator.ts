/* @ts-expect-error Pi provides this module at runtime. */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const FRAME_INTERVAL_MS = 120;
const PHRASE_INTERVAL_MS = 2_400;
const COLOR_INTERVAL_MS = 2_500;
const PHRASES = [
	"Bamboozling...",
	"Contemplating the orb...",
	"Wrestling the electrons...",
	"Consulting the vibes...",
	"Untangling spaghetti...",
	"Convincing the pixels...",
	"Polishing the goblins...",
	"Performing tasteful wizardry...",
];

const COLORS = ["#cba6f7", "#a66bd8"];
const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

function randomPhrase(previous?: string): string {
	const choices = PHRASES.filter((phrase) => phrase !== previous);
	return choices[Math.floor(Math.random() * choices.length)];
}

export default function (pi: ExtensionAPI) {
	let phrase = randomPhrase();
	let phraseTimer: ReturnType<typeof setInterval> | undefined;
	let colorTimer: ReturnType<typeof setInterval> | undefined;
	let gradientTimer: ReturnType<typeof setInterval> | undefined;
	let colorIndex = 0;
	let gradientOffset = 0;

	pi.on("session_start", (_event, ctx) => {
		const applyStyle = () => {
			const color = COLORS[colorIndex];
			ctx.ui.setWorkingIndicator({
				frames: SPINNER.map((glyph) => paint(color, glyph)),
				intervalMs: FRAME_INTERVAL_MS,
			});
			ctx.ui.setWorkingMessage(gradientText(phrase, gradientOffset));
		};

		applyStyle();
		colorTimer = setInterval(() => {
			colorIndex = (colorIndex + 1) % COLORS.length;
			applyStyle();
		}, COLOR_INTERVAL_MS);
		gradientTimer = setInterval(() => {
			gradientOffset = (gradientOffset + 1) % (COLORS.length * 4);
			ctx.ui.setWorkingMessage(gradientText(phrase, gradientOffset));
		}, FRAME_INTERVAL_MS);

		phraseTimer = setInterval(() => {
			phrase = randomPhrase(phrase);
			ctx.ui.setWorkingMessage(gradientText(phrase, gradientOffset));
		}, PHRASE_INTERVAL_MS);
	});

	pi.on("session_shutdown", () => {
		if (phraseTimer) clearInterval(phraseTimer);
		if (colorTimer) clearInterval(colorTimer);
		if (gradientTimer) clearInterval(gradientTimer);
		phraseTimer = undefined;
		colorTimer = undefined;
		gradientTimer = undefined;
	});
}

function paint(hex: string, text: string): string {
	const [red, green, blue] = rgb(hex);
	return `\x1b[38;2;${red};${green};${blue}m${text}\x1b[39m`;
}

function rgb(hex: string): [number, number, number] {
	return [
		Number.parseInt(hex.slice(1, 3), 16),
		Number.parseInt(hex.slice(3, 5), 16),
		Number.parseInt(hex.slice(5, 7), 16),
	];
}

function gradientText(text: string, offset: number): string {
	return [...text].map((character, index) => {
		if (character === " ") return character;
		const color = COLORS[(Math.floor((index + offset) / 3)) % COLORS.length];
		return paint(color, character);
	}).join("");
}
