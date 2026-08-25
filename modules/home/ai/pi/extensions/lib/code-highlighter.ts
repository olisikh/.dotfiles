import type { PiTextTheme, PiNamedThemeColor } from "./pi-theme.ts";
import { PI_THEME_COLORS } from "./pi-theme.ts";

/** The small part of Lumis's highlighter API used by the renderer. */
export type LumisHighlighter = {
	highlightIter: (
		source: string,
		language: unknown,
		theme: undefined,
		onToken: (
			text: string,
			language: string,
			range: unknown,
			scope: string,
			style: unknown,
		) => void,
	) => void;
};

export type CodeHighlighter = (
	code: string,
	language: string,
	theme: PiTextTheme,
) => string;

/** Languages deliberately loaded by the Pi extension's local Lumis bundle. */
const LUMIS_LANGUAGE_ALIASES: Record<string, string> = {
	bash: "bash",
	sh: "bash",
	shell: "bash",
	zsh: "bash",
	nix: "nix",
	javascript: "javascript",
	js: "javascript",
	jsx: "javascript",
	mjs: "javascript",
	cjs: "javascript",
	typescript: "typescript",
	ts: "typescript",
	tsx: "typescript",
	python: "python",
	py: "python",
	java: "java",
	scala: "scala",
	kotlin: "kotlin",
	kt: "kotlin",
	kts: "kotlin",
};

export function normalizeLumisLanguage(
	language: string | undefined,
): string | undefined {
	const normalized = language?.trim().toLowerCase();
	return normalized ? LUMIS_LANGUAGE_ALIASES[normalized] : undefined;
}

function colorForScope(scope: string): PiNamedThemeColor {
	const normalized = scope.toLowerCase();

	if (normalized.includes("comment")) {
		return PI_THEME_COLORS.syntaxComment;
	}
	if (normalized.includes("string") || normalized.includes("character")) {
		return PI_THEME_COLORS.syntaxString;
	}
	if (normalized.includes("number") || normalized.includes("boolean")) {
		return PI_THEME_COLORS.syntaxNumber;
	}
	if (normalized.includes("keyword") || normalized.includes("storage")) {
		return PI_THEME_COLORS.syntaxKeyword;
	}
	if (
		normalized.includes("function") ||
		normalized.includes("method") ||
		normalized.includes("constructor")
	) {
		return PI_THEME_COLORS.syntaxFunction;
	}
	if (
		normalized.includes("type") ||
		normalized.includes("class") ||
		normalized.includes("namespace") ||
		normalized.includes("module")
	) {
		return PI_THEME_COLORS.syntaxType;
	}
	if (normalized.includes("operator")) {
		return PI_THEME_COLORS.syntaxOperator;
	}
	if (
		normalized.includes("variable") ||
		normalized.includes("parameter") ||
		normalized.includes("property") ||
		normalized.includes("attribute") ||
		normalized.includes("constant")
	) {
		return PI_THEME_COLORS.syntaxVariable;
	}
	if (normalized.includes("punctuation") || normalized.includes("delimiter")) {
		return PI_THEME_COLORS.syntaxPunctuation;
	}

	return PI_THEME_COLORS.syntaxPunctuation;
}

/**
 * Adapt Lumis's Tree-sitter token stream to Pi's active theme.
 *
 * Lumis supplies scopes and source ranges; Pi supplies the actual ANSI colors.
 * Keeping those concerns separate means Catppuccin and user-selected themes
 * continue to work without duplicating a palette in the highlighter.
 */
export function createCodeHighlighter(
	lumis: LumisHighlighter,
	languages: Record<string, unknown>,
): CodeHighlighter {
	return (code, language, theme) => {
		const tokens: string[] = [];
		const languageRef = languages[language] ?? language;

		lumis.highlightIter(
			code,
			languageRef,
			undefined,
			(text, _language, _range, scope) => {
				if (!scope) {
					tokens.push(text);
					return;
				}
				tokens.push(theme.fg(colorForScope(scope), text));
			},
		);

		return tokens.join("");
	};
}
