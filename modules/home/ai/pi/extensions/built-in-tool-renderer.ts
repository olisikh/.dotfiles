// @ts-ignore Pi provides this virtual module to extensions at runtime.
import {
	createCodingTools,
	createReadOnlyTools,
	getLanguageFromPath,
	highlightCode,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
/* @ts-ignore Pi provides this module to extensions at runtime. */
import { Text } from "@earendil-works/pi-tui";
import type { PiTextTheme } from "./lib/pi-theme.ts";

type ReadArguments = {
	path?: string;
	file_path?: string;
	offset?: number;
	limit?: number;
};

type PathArguments = {
	path?: string;
	file_path?: string;
};

function currentWorkingDirectory(): string {
	const processLike = (
		globalThis as typeof globalThis & {
			process?: { cwd?: () => string };
		}
	).process;
	return processLike?.cwd?.() ?? ".";
}

const BASH_HASH_PLACEHOLDER = "__PI_BASH_HASH__";

type BashMaskState = {
	quote: "'" | '"' | undefined;
	inComment: boolean;
	atWordStart: boolean;
};

type BashMaskConsumption = {
	text: string;
	nextIndex: number;
};

function isBashWordBoundary(character: string): boolean {
	return /\s/u.test(character) || "|&;()<>".includes(character);
}

function consumeBashCommentCharacter(
	state: BashMaskState,
	character: string,
): string {
	if (character === "\n") {
		state.inComment = false;
		state.atWordStart = true;
	}
	return character;
}

function consumeBashQuotedCharacter(
	source: string,
	index: number,
	state: BashMaskState,
): BashMaskConsumption {
	const character = source[index];
	if (state.quote === "'") {
		if (character === "'") {
			state.quote = undefined;
		}
		return { text: character, nextIndex: index };
	}

	if (character === "\\" && source[index + 1] !== undefined) {
		return { text: character + source[index + 1], nextIndex: index + 1 };
	}
	if (character === '"') {
		state.quote = undefined;
	}
	return { text: character, nextIndex: index };
}

function consumeBashEscapedCharacter(
	source: string,
	index: number,
	state: BashMaskState,
	placeholder: string,
): BashMaskConsumption {
	const escaped = source[index + 1];
	if (escaped === undefined) {
		return { text: source[index], nextIndex: index };
	}

	if (escaped !== "\n") {
		state.atWordStart = false;
	}
	return {
		text: `${source[index]}${escaped === "#" ? placeholder : escaped}`,
		nextIndex: index + 1,
	};
}

function consumeBashHash(state: BashMaskState, placeholder: string): string {
	const startsComment = state.atWordStart;
	state.atWordStart = false;
	if (startsComment) {
		state.inComment = true;
	}
	return startsComment ? "#" : placeholder;
}

// Keep embedded hashes out of the Bash highlighter's comment rule, then restore them.
export function maskNonCommentHashes(source: string): {
	source: string;
	placeholder: string;
} {
	let placeholder = BASH_HASH_PLACEHOLDER;
	while (source.includes(placeholder)) {
		placeholder = `_${placeholder}`;
	}

	const state: BashMaskState = {
		quote: undefined,
		inComment: false,
		atWordStart: true,
	};
	let maskedSource = "";

	for (let index = 0; index < source.length; index += 1) {
		const character = source[index];

		if (state.inComment) {
			maskedSource += consumeBashCommentCharacter(state, character);
			continue;
		}

		if (state.quote) {
			const consumed = consumeBashQuotedCharacter(source, index, state);
			maskedSource += consumed.text;
			index = consumed.nextIndex;
			continue;
		}

		if (character === "\\") {
			const consumed = consumeBashEscapedCharacter(
				source,
				index,
				state,
				placeholder,
			);
			maskedSource += consumed.text;
			index = consumed.nextIndex;
			continue;
		}

		if (character === "'" || character === '"') {
			maskedSource += character;
			state.quote = character;
			state.atWordStart = false;
			continue;
		}

		if (character === "#") {
			maskedSource += consumeBashHash(state, placeholder);
			continue;
		}

		maskedSource += character;
		state.atWordStart = isBashWordBoundary(character);
	}

	return { source: maskedSource, placeholder };
}

function renderCommand(command: string, theme: PiTextTheme): string {
	const source = command.replace(/\r\n?/g, "\n").trimEnd();
	const { source: sourceForHighlight, placeholder } =
		maskNonCommentHashes(source);
	let lines: string[];

	try {
		// highlightCode uses the active Pi theme and returns ANSI-styled lines.
		lines = highlightCode(sourceForHighlight, "bash").map((line: string) =>
			line.replaceAll(placeholder, "#"),
		);
	} catch {
		lines = source.split("\n");
	}

	if (lines.length <= 1) {
		return `${theme.fg("bashMode", "$ ")}${lines[0] ?? ""}`;
	}

	const lineNumberWidth = String(lines.length).length;
	const numberedLines = lines.map((line, index) => {
		const lineNumber = String(index + 1).padStart(lineNumberWidth, " ");
		const gutter = theme.fg("dim", `${lineNumber} │ `);
		let prompt = "  ";
		if (index === 0) {
			prompt = theme.fg("bashMode", "$ ");
		}
		return `${gutter}${prompt}${line}`;
	});

	const header =
		theme.fg("bashMode", theme.bold("bash")) +
		theme.fg("dim", ` · ${lines.length} lines`);

	return `${header}\n${numberedLines.join("\n")}`;
}

function renderToolTitle(
	toolName: string,
	details: string,
	theme: PiTextTheme,
): string {
	const title = theme.fg("toolTitle", theme.bold(toolName));
	return details ? `${title} ${theme.fg("toolOutput", details)}` : title;
}

function renderPathToolCall(
	toolName: string,
	args: PathArguments,
	theme: PiTextTheme,
): string {
	const rawPath = args.file_path ?? args.path ?? "";
	return renderToolTitle(toolName, rawPath, theme);
}

function renderSearchToolCall(
	toolName: string,
	args: Record<string, unknown>,
	theme: PiTextTheme,
): string {
	const pattern = typeof args.pattern === "string" ? args.pattern : "";
	let path = "";
	if (typeof args.path === "string") {
		path = args.path;
	} else if (toolName === "ls") {
		path = ".";
	}

	const details: string[] = [];
	if (pattern) {
		if (toolName === "grep") {
			details.push(`/${pattern}/`);
		} else {
			details.push(pattern);
		}
	}
	if (path) {
		details.push(`in ${path}`);
	}
	if (typeof args.glob === "string" && args.glob) {
		details.push(`(${args.glob})`);
	}
	if (typeof args.limit === "number") {
		details.push(`limit ${args.limit}`);
	}

	return renderToolTitle(toolName, details.join(" "), theme);
}

function renderReadCall(args: ReadArguments, theme: PiTextTheme): string {
	const rawPath = args.file_path ?? args.path ?? "";
	const language = getLanguageFromPath(rawPath);
	const startLine = args.offset ?? 1;
	let endLine = "";
	if (args.limit !== undefined) {
		endLine = String(startLine + args.limit - 1);
	}

	let range = "";
	if (args.offset !== undefined || args.limit !== undefined) {
		range = theme.fg("warning", `:${startLine}${endLine ? `-${endLine}` : ""}`);
	}

	let languageLabel = "";
	if (language) {
		languageLabel = theme.fg("dim", ` · ${language}`);
	}

	return renderToolTitle("read", rawPath, theme) + range + languageLabel;
}

function renderToolCall(
	toolName: string,
	args: Record<string, unknown>,
	theme: PiTextTheme,
): string {
	if (toolName === "bash") {
		const command = typeof args.command === "string" ? args.command : "";
		return renderCommand(command, theme);
	}
	if (toolName === "read") {
		return renderReadCall(args as ReadArguments, theme);
	}
	if (toolName === "edit" || toolName === "write") {
		return renderPathToolCall(toolName, args as PathArguments, theme);
	}
	return renderSearchToolCall(toolName, args, theme);
}

export default function (pi: ExtensionAPI) {
	const cwd = currentWorkingDirectory();
	const originalTools = new Map(
		[...createCodingTools(cwd), ...createReadOnlyTools(cwd)].map((tool) => [
			tool.name,
			tool,
		]),
	);

	// Keep execution, schemas, prompt guidance, and result rendering from Pi;
	// replace only the call-row presentation for every built-in tool.
	for (const originalTool of originalTools.values()) {
		pi.registerTool({
			...originalTool,
			renderCall(args: Record<string, unknown>, theme: PiTextTheme) {
				return new Text(renderToolCall(originalTool.name, args, theme), 0, 0);
			},
		});
	}
}
