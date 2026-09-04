import { join } from "node:path";
import { pathToFileURL } from "node:url";
import {
	createCodingTools,
	createReadOnlyTools,
	getAgentDir,
	getLanguageFromPath,
	getMarkdownTheme,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import {
	createCodeHighlighter,
	normalizeLumisLanguage,
	registerLumisLanguages,
	type CodeHighlighter,
	type LumisHighlighter,
} from "./lib/code-highlighter.ts";
import type {
	PiNamedThemeColor,
	PiTextTheme,
	PiTheme,
} from "./lib/pi-theme.ts";
import { PI_THEME_COLORS } from "./lib/pi-theme.ts";

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

type RenderOptions = {
	expanded?: boolean;
	isPartial?: boolean;
};

type RenderContext = {
	args?: unknown;
	expanded?: boolean;
	isError?: boolean;
};

type RenderResult = (
	result: unknown,
	options: unknown,
	theme: PiTheme,
	context: unknown,
) => Text;

const MARKDOWN_HIGHLIGHT_SUPPRESSOR = "\u200b";

function currentWorkingDirectory(): string {
	const processLike = (
		globalThis as typeof globalThis & {
			process?: { cwd?: () => string };
		}
	).process;
	return processLike?.cwd?.() ?? ".";
}

// Home Manager exposes this extension through a read-only Nix-store symlink.
// Resolve its runtime dependencies from Pi's writable managed npm root instead
// of trying to create node_modules beside the extension. Bun's compiled Pi
// loader does not honor Node's require.resolve() search paths here, so these
// package entry points are intentionally resolved as absolute files.
async function loadManagedModule<T>(specifier: string): Promise<T> {
	const managedNodeModules = join(getAgentDir(), "npm", "node_modules");
	const relativePath =
		specifier === "@lumis-sh/lumis"
			? "@lumis-sh/lumis/dist/index.js"
			: specifier === "@lumis-sh/lumis/bundles/full"
				? "@lumis-sh/lumis/dist/bundles/full.js"
				: undefined;
	if (!relativePath) {
		throw new Error(`Unsupported managed module: ${specifier}`);
	}
	return (await import(
		pathToFileURL(join(managedNodeModules, relativePath)).href
	)) as T;
}

/**
 * Common source languages plus data, configuration, and injected utility
 * grammars. Keep this list curated: every loaded parser stays resident in Pi.
 */
const LUMIS_LANGUAGE_PROFILE = [
	// Shells and general-purpose languages.
	"bash",
	"fish",
	"powershell",
	"zsh",
	"c",
	"cpp",
	"csharp",
	"dart",
	"elixir",
	"go",
	"java",
	"javascript",
	"kotlin",
	"lua",
	"nix",
	"php",
	"python",
	"r",
	"ruby",
	"rust",
	"scala",
	"swift",
	"typescript",
	"tsx",
	"vim",
	// Web languages and templates.
	"css",
	"html",
	"scss",
	"svelte",
	"vue",
	// Data, configuration, documentation, and injection utilities.
	"comment",
	"csv",
	"diff",
	"dockerfile",
	"graphql",
	"hcl",
	"ini",
	"jq",
	"json",
	"json5",
	"markdown",
	"markdown_inline",
	"make",
	"wasm",
	"protobuf",
	"regex",
	"sql",
	"terraform",
	"toml",
	"yaml",
	"xml",
] as const;

async function loadCodeHighlighter(): Promise<CodeHighlighter> {
	const { createHighlighter } = await loadManagedModule<{
		createHighlighter: (options: {
			languages: unknown[];
		}) => Promise<LumisHighlighter>;
	}>("@lumis-sh/lumis");
	const { bundledLanguages } = await loadManagedModule<{
		bundledLanguages: Record<string, unknown>;
	}>("@lumis-sh/lumis/bundles/full");

	// Register the selected profile lazily, then load one parser at a time.
	// Passing all handles as individual languages makes Lumis instantiate every
	// WASM module concurrently and can exceed the runtime's memory limit.
	const profileLanguages: Record<string, unknown> = {};
	for (const name of LUMIS_LANGUAGE_PROFILE) {
		const language = bundledLanguages[name];
		if (language) {
			profileLanguages[name] = language;
		}
	}
	const lumis = await createHighlighter({ languages: [profileLanguages] });
	const languages: Record<string, unknown> = {};
	for (const [name, language] of Object.entries(profileLanguages)) {
		try {
			await lumis.loadLanguage(language);
			languages[name] = language;
		} catch {
			// Keep a parser that the active runtime cannot load as plain text.
		}
	}
	registerLumisLanguages(languages);
	return createCodeHighlighter(lumis, languages);
}

function asRecord(value: unknown): Record<string, unknown> {
	return value && typeof value === "object"
		? (value as Record<string, unknown>)
		: {};
}

function textContent(result: unknown): string {
	const content = asRecord(result).content;
	if (!Array.isArray(content)) {
		return "";
	}
	return content
		.flatMap((item) => {
			const record = asRecord(item);
			return record.type === "text" ? [String(record.text ?? "")] : [];
		})
		.join("\n")
		.replace(/\r/g, "");
}

function pathArgument(args: Record<string, unknown>): string {
	if (typeof args.file_path === "string") {
		return args.file_path;
	}
	if (typeof args.path === "string") {
		return args.path;
	}
	return "";
}

function replaceTabs(text: string): string {
	return text.replace(/\t/g, "   ");
}

function trimTrailingEmptyLines(lines: string[]): string[] {
	let end = lines.length;
	while (end > 0 && lines[end - 1] === "") {
		end -= 1;
	}
	return lines.slice(0, end);
}

function lumisLanguageForPath(rawPath: string): string | undefined {
	const fromPi = normalizeLumisLanguage(getLanguageFromPath(rawPath));
	if (fromPi) {
		return fromPi;
	}

	const basename = rawPath.split(/[\\/]/).pop()?.toLowerCase() ?? "";
	const extension = basename.split(".").pop();
	if (extension === "nix") {
		return "nix";
	}
	if (extension === "kts") {
		return "kotlin";
	}
	return undefined;
}

function highlightedLines(
	source: string,
	language: string | undefined,
	theme: PiTextTheme,
	highlighter: CodeHighlighter,
): string[] {
	const normalized = replaceTabs(source.replace(/\r/g, ""));
	if (!language) {
		return trimTrailingEmptyLines(
			normalized
				.split("\n")
				.map((line) => theme.fg(PI_THEME_COLORS.toolOutput, line)),
		);
	}
	return trimTrailingEmptyLines(
		highlighter(normalized, language, theme).split("\n"),
	);
}

function renderCommand(
	command: string,
	theme: PiTextTheme,
	highlighter: CodeHighlighter,
): string {
	const source = command.replace(/\r\n?/g, "\n").trimEnd();
	const lines = highlighter(source, "bash", theme).split("\n");

	if (lines.length <= 1) {
		return `${theme.fg(PI_THEME_COLORS.bashMode, "$ ")}${lines[0] ?? ""}`;
	}

	const lineNumberWidth = String(lines.length).length;
	const numberedLines = lines.map((line, index) => {
		const lineNumber = String(index + 1).padStart(lineNumberWidth, " ");
		const gutter = theme.fg(PI_THEME_COLORS.dim, `${lineNumber} │ `);
		let prompt = "  ";
		if (index === 0) {
			prompt = theme.fg(PI_THEME_COLORS.bashMode, "$ ");
		}
		return `${gutter}${prompt}${line}`;
	});

	const header =
		theme.fg(PI_THEME_COLORS.bashMode, theme.bold("bash")) +
		theme.fg(PI_THEME_COLORS.dim, ` · ${lines.length} lines`);

	return `${header}\n${numberedLines.join("\n")}`;
}

function renderToolTitle(
	toolName: string,
	details: string,
	theme: PiTextTheme,
): string {
	const title = theme.fg(PI_THEME_COLORS.toolTitle, theme.bold(toolName));
	return details
		? `${title} ${theme.fg(PI_THEME_COLORS.toolOutput, details)}`
		: title;
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
	const language = lumisLanguageForPath(rawPath);
	const startLine = args.offset ?? 1;
	let endLine = "";
	if (args.limit !== undefined) {
		endLine = String(startLine + args.limit - 1);
	}

	let range = "";
	if (args.offset !== undefined || args.limit !== undefined) {
		range = theme.fg(
			PI_THEME_COLORS.warning,
			`:${startLine}${endLine ? `-${endLine}` : ""}`,
		);
	}

	let languageLabel = "";
	if (language) {
		languageLabel = theme.fg(PI_THEME_COLORS.dim, ` · ${language}`);
	}

	return renderToolTitle("read", rawPath, theme) + range + languageLabel;
}

function renderWriteCall(
	args: Record<string, unknown>,
	theme: PiTextTheme,
	highlighter: CodeHighlighter,
	expanded: boolean,
): string {
	const rawPath = pathArgument(args);
	const content = typeof args.content === "string" ? args.content : undefined;
	let text = renderToolTitle("write", rawPath, theme);

	if (content === undefined) {
		if (args.content !== undefined) {
			text += `\n\n${theme.fg(PI_THEME_COLORS.error, "[invalid content arg - expected string]")}`;
		}
		return text;
	}

	const language = lumisLanguageForPath(rawPath);
	const lines = highlightedLines(content, language, theme, highlighter);
	const maxLines = expanded ? lines.length : 10;
	const displayLines = lines.slice(0, maxLines);
	const remaining = lines.length - displayLines.length;
	if (displayLines.length > 0) {
		text += `\n\n${displayLines.join("\n")}`;
	}
	if (remaining > 0) {
		text += theme.fg(
			PI_THEME_COLORS.muted,
			`\n... (${remaining} more lines, expand to show)`,
		);
	}
	return text;
}

function renderToolCall(
	toolName: string,
	args: Record<string, unknown>,
	theme: PiTextTheme,
	highlighter: CodeHighlighter,
	expanded: boolean,
): string {
	if (toolName === "bash") {
		const command = typeof args.command === "string" ? args.command : "";
		return renderCommand(command, theme, highlighter);
	}
	if (toolName === "read") {
		return renderReadCall(args as ReadArguments, theme);
	}
	if (toolName === "write") {
		return renderWriteCall(args, theme, highlighter, expanded);
	}
	if (toolName === "edit") {
		return renderPathToolCall(toolName, args as PathArguments, theme);
	}
	return renderSearchToolCall(toolName, args, theme);
}

function truncationRecord(result: unknown): Record<string, unknown> {
	const details = asRecord(asRecord(result).details);
	return asRecord(details.truncation);
}

function formatSize(value: unknown): string {
	if (typeof value !== "number" || !Number.isFinite(value)) {
		return "size limit";
	}
	if (value >= 1024 * 1024) {
		return `${(value / (1024 * 1024)).toFixed(1)}MB`;
	}
	if (value >= 1024) {
		return `${Math.round(value / 1024)}KB`;
	}
	return `${value}B`;
}

function appendReadTruncation(
	text: string,
	result: unknown,
	theme: PiTextTheme,
): string {
	const truncation = truncationRecord(result);
	if (truncation.truncated !== true) {
		return text;
	}

	let notice: string;
	if (truncation.firstLineExceedsLimit === true) {
		notice = `[First line exceeds ${formatSize(truncation.maxBytes)} limit]`;
	} else if (truncation.truncatedBy === "lines") {
		notice = `[Truncated: showing ${String(truncation.outputLines ?? "some")} of ${String(truncation.totalLines ?? "many")} lines (${String(truncation.maxLines ?? "configured")} line limit)]`;
	} else {
		notice = `[Truncated: ${String(truncation.outputLines ?? "some")} lines shown (${formatSize(truncation.maxBytes)} limit)]`;
	}
	return `${text}\n${theme.fg(PI_THEME_COLORS.warning, notice)}`;
}

function renderReadResult(
	result: unknown,
	options: unknown,
	theme: PiTextTheme,
	context: unknown,
	highlighter: CodeHighlighter,
): Text {
	const renderOptions = asRecord(options) as RenderOptions;
	const renderContext = asRecord(context) as RenderContext;
	const isError = renderContext.isError === true;
	const output = textContent(result);

	if (!renderOptions.expanded && !isError) {
		return new Text("", 0, 0);
	}
	if (isError) {
		return new Text(
			output ? `\n${theme.fg(PI_THEME_COLORS.error, output)}` : "",
			0,
			0,
		);
	}

	const args = asRecord(renderContext.args);
	const rawPath = pathArgument(args);
	const lines = highlightedLines(
		output,
		lumisLanguageForPath(rawPath),
		theme,
		highlighter,
	);
	let text = lines.length > 0 ? `\n${lines.join("\n")}` : "";
	text = appendReadTruncation(text, result, theme);
	return new Text(text, 0, 0);
}

type ParsedDiffLine = {
	prefix: string;
	lineNum: string;
	content: string;
};

function parseDiffLine(line: string): ParsedDiffLine | undefined {
	const match = line.match(/^([+-\s])(\s*\d*)\s(.*)$/);
	return match
		? { prefix: match[1], lineNum: match[2], content: match[3] }
		: undefined;
}

function trimDiffElisionMarkers(diff: string): string {
	const lines = diff.split("\n");
	if (lines[0]?.trim() === "...") lines.shift();
	if (lines.at(-1)?.trim() === "...") lines.pop();
	return lines.join("\n");
}

function backgroundAnsi(theme: PiTheme, color: PiNamedThemeColor): string {
	return theme.getFgAnsi(color).replace("\x1b[38;", "\x1b[48;");
}

function blendedBackgroundAnsi(
	theme: PiTheme,
	lineColor: PiNamedThemeColor,
	highlightColor: PiNamedThemeColor,
): string {
	const rgb = (
		color: PiNamedThemeColor,
	): [number, number, number] | undefined => {
		const match = theme.getFgAnsi(color).match(/^\x1b\[38;2;(\d+);(\d+);(\d+)m$/);
		return match
			? [Number(match[1]), Number(match[2]), Number(match[3])]
			: undefined;
	};
	const lineRgb = rgb(lineColor);
	const highlightRgb = rgb(highlightColor);
	if (!lineRgb || !highlightRgb) return backgroundAnsi(theme, lineColor);

	const blend = 0.2;
	const channels = lineRgb.map((channel, index) =>
		Math.round(channel + (highlightRgb[index] - channel) * blend),
	);
	return `\x1b[48;2;${channels.join(";")}m`;
}

type DiffHighlight = {
	start: number;
	end: number;
};

function changedRange(
	before: string,
	after: string,
): DiffHighlight | undefined {
	let start = 0;
	while (
		start < before.length &&
		start < after.length &&
		before[start] === after[start]
	) {
		start += 1;
	}

	let beforeEnd = before.length;
	let afterEnd = after.length;
	while (
		beforeEnd > start &&
		afterEnd > start &&
		before[beforeEnd - 1] === after[afterEnd - 1]
	) {
		beforeEnd -= 1;
		afterEnd -= 1;
	}

	return start === beforeEnd ? undefined : { start, end: beforeEnd };
}

function inlineDiffHighlights(lines: string[]): Map<number, DiffHighlight> {
	const highlights = new Map<number, DiffHighlight>();

	for (let index = 0; index < lines.length; ) {
		const removed: Array<{ index: number; content: string }> = [];
		while (parseDiffLine(lines[index] ?? "")?.prefix === "-") {
			removed.push({
				index,
				content: replaceTabs(parseDiffLine(lines[index] ?? "")?.content ?? ""),
			});
			index += 1;
		}

		if (removed.length === 0) {
			index += 1;
			continue;
		}

		const added: Array<{ index: number; content: string }> = [];
		while (parseDiffLine(lines[index] ?? "")?.prefix === "+") {
			added.push({
				index,
				content: replaceTabs(parseDiffLine(lines[index] ?? "")?.content ?? ""),
			});
			index += 1;
		}

		for (
			let pairIndex = 0;
			pairIndex < Math.min(removed.length, added.length);
			pairIndex += 1
		) {
			const removedLine = removed[pairIndex];
			const addedLine = added[pairIndex];
			const removedHighlight = changedRange(
				removedLine.content,
				addedLine.content,
			);
			const addedHighlight = changedRange(addedLine.content, removedLine.content);
			if (removedHighlight) highlights.set(removedLine.index, removedHighlight);
			if (addedHighlight) highlights.set(addedLine.index, addedHighlight);
		}
	}

	return highlights;
}

function highlightAnsiRange(
	text: string,
	highlight: DiffHighlight | undefined,
	background: string,
	lineBackground: string,
): string {
	if (!highlight) return text;

	let visibleIndex = 0;
	let result = "";
	for (let index = 0; index < text.length; ) {
		const ansi = text.slice(index).match(/^\x1b\[[0-?]*[ -/]*[@-~]/)?.[0];
		if (ansi) {
			result += ansi;
			index += ansi.length;
			continue;
		}
		if (visibleIndex === highlight.start) result += background;
		result += text[index];
		visibleIndex += 1;
		index += 1;
		if (visibleIndex === highlight.end) result += lineBackground;
	}
	return result;
}

function renderLumisDiff(
	diff: string,
	language: string | undefined,
	theme: PiTheme,
	highlighter: CodeHighlighter,
): string {
	const lines = trimDiffElisionMarkers(diff).split("\n");
	const highlights = inlineDiffHighlights(lines);

	return lines
		.map((line, index) => {
			const parsed = parseDiffLine(line);
			if (!parsed) {
				return theme.fg(PI_THEME_COLORS.toolDiffContext, line);
			}

			const code = language
				? highlighter(replaceTabs(parsed.content), language, theme)
				: theme.fg(PI_THEME_COLORS.toolOutput, replaceTabs(parsed.content));
			if (parsed.prefix === "+" || parsed.prefix === "-") {
				const lineColor =
					parsed.prefix === "+"
						? PI_THEME_COLORS.toolDiffAdded
						: PI_THEME_COLORS.toolDiffRemoved;
				const highlightColor =
					parsed.prefix === "+" ? PI_THEME_COLORS.success : PI_THEME_COLORS.error;
				const prefix = `${theme.fg(lineColor, parsed.prefix)}${theme.fg(
					PI_THEME_COLORS.toolDiffContext,
					`${parsed.lineNum} `,
				)}`;
				const lineBackground = backgroundAnsi(theme, lineColor);
				const renderedCode = highlightAnsiRange(
					code,
					highlights.get(index),
					blendedBackgroundAnsi(theme, lineColor, highlightColor),
					lineBackground,
				);
				// CSI K erases the remaining terminal cells with the active background.
				return `${prefix}${lineBackground}${renderedCode}\x1b[K\x1b[49m`;
			}
			return `${theme.fg(PI_THEME_COLORS.toolDiffContext, `${parsed.prefix}${parsed.lineNum} `)}${code}`;
		})
		.join("\n");
}

function renderEditResult(
	result: unknown,
	_themeOptions: unknown,
	theme: PiTheme,
	context: unknown,
	highlighter: CodeHighlighter,
): Text {
	const renderContext = asRecord(context) as RenderContext;
	if (renderContext.isError === true) {
		const output = textContent(result);
		return new Text(output ? theme.fg(PI_THEME_COLORS.error, output) : "", 0, 0);
	}

	const details = asRecord(asRecord(result).details);
	const diff = typeof details.diff === "string" ? details.diff : "";
	if (!diff) {
		return new Text("", 0, 0);
	}

	const args = asRecord(renderContext.args);
	const rawPath = pathArgument(args);
	return new Text(
		`\n${renderLumisDiff(diff, lumisLanguageForPath(rawPath), theme, highlighter)}`,
		0,
		0,
	);
}

function markdownSyntaxTheme(activeTheme?: PiTextTheme): PiTextTheme {
	if (activeTheme) {
		return activeTheme;
	}

	const markdownTheme = getMarkdownTheme();
	return {
		fg(color: PiNamedThemeColor, text: string) {
			switch (color) {
				case PI_THEME_COLORS.syntaxComment:
					return markdownTheme.quote(text);
				case PI_THEME_COLORS.syntaxKeyword:
					return markdownTheme.listBullet(text);
				case PI_THEME_COLORS.syntaxFunction:
					return markdownTheme.link(text);
				case PI_THEME_COLORS.syntaxVariable:
					return markdownTheme.heading(text);
				case PI_THEME_COLORS.syntaxString:
					return markdownTheme.code(text);
				case PI_THEME_COLORS.syntaxNumber:
					return markdownTheme.heading(text);
				case PI_THEME_COLORS.syntaxType:
					return markdownTheme.code(text);
				case PI_THEME_COLORS.syntaxOperator:
					return markdownTheme.listBullet(text);
				default:
					return markdownTheme.codeBlock(text);
			}
		},
		bold: markdownTheme.bold,
	};
}

type MarkdownFence = {
	indent: string;
	marker: string;
	info: string;
	body: string[];
};

function parseMarkdownFence(line: string): MarkdownFence | undefined {
	const match = line.match(/^([ \t]{0,3})(`{3,}|~{3,})(.*)$/);
	if (!match) {
		return undefined;
	}
	const info = match[3].trim();
	if (match[2][0] === "`" && info.includes("`")) {
		return undefined;
	}
	return { indent: match[1], marker: match[2], info, body: [] };
}

function isMarkdownFenceClose(line: string, fence: MarkdownFence): boolean {
	const candidate = line.replace(/^[ \\t]{0,3}/, "");
	if (!candidate || candidate[0] !== fence.marker[0]) {
		return false;
	}

	let markerLength = 0;
	while (candidate[markerLength] === fence.marker[0]) {
		markerLength += 1;
	}
	return (
		markerLength >= fence.marker.length &&
		candidate.slice(markerLength).trim().length === 0
	);
}

function transformMarkdownFence(
	fence: MarkdownFence,
	closingLine: string | undefined,
	theme: PiTextTheme,
	highlighter: CodeHighlighter,
): string[] {
	const languageToken = fence.info.split(/[ \t]+/, 1)[0] ?? "";
	const language = normalizeLumisLanguage(
		languageToken.replace(/^\{\.?/, "").replace(/\}?$/, ""),
	);
	const sourceLines = fence.body.map((line) =>
		line.startsWith(fence.indent) ? line.slice(fence.indent.length) : line,
	);
	const body = language
		? highlighter(sourceLines.join("\n"), language, theme)
				.split("\n")
				.map((line) => `${fence.indent}${line}`)
		: fence.body;

	let opening = `${fence.indent}${fence.marker}`;
	if (fence.info) {
		opening += ` ${fence.info}${MARKDOWN_HIGHLIGHT_SUPPRESSOR}`;
	}

	return [opening, ...body, ...(closingLine ? [closingLine] : [])];
}

function highlightMarkdownCodeBlocks(
	markdown: string,
	highlighter: CodeHighlighter,
	activeTheme: PiTextTheme | undefined,
): string {
	const output: string[] = [];
	const theme = markdownSyntaxTheme(activeTheme);
	let fence: MarkdownFence | undefined;

	for (const line of markdown.split("\n")) {
		if (!fence) {
			const opening = parseMarkdownFence(line);
			if (opening) {
				fence = opening;
			} else {
				output.push(line);
			}
			continue;
		}

		if (isMarkdownFenceClose(line, fence)) {
			output.push(...transformMarkdownFence(fence, line, theme, highlighter));
			fence = undefined;
		} else {
			fence.body.push(line);
		}
	}

	if (fence) {
		output.push(...transformMarkdownFence(fence, undefined, theme, highlighter));
	}

	return output.join("\n");
}

export default async function (pi: ExtensionAPI) {
	const highlighter = await loadCodeHighlighter();
	const cwd = currentWorkingDirectory();
	let activeTheme: PiTextTheme | undefined;
	const originalTools = new Map(
		[...createCodingTools(cwd), ...createReadOnlyTools(cwd)].map((tool) => [
			tool.name,
			tool,
		]),
	);

	// Markdown transformers are display-only. They disable Pi's text highlighter
	// for fenced blocks, then replace supported blocks with Lumis ANSI tokens.
	pi.registerMarkdownTransformer((markdown: string) =>
		highlightMarkdownCodeBlocks(markdown, highlighter, activeTheme),
	);

	// Keep execution, schemas, prompt guidance, and result handling from Pi;
	// replace only the presentation of built-in tools.
	for (const originalTool of originalTools.values()) {
		const renderResultOverrides: Record<string, RenderResult> = {};
		if (originalTool.name === "read") {
			renderResultOverrides.read = (result, options, theme, context) =>
				renderReadResult(result, options, theme, context, highlighter);
		}
		if (originalTool.name === "edit") {
			renderResultOverrides.edit = (result, options, theme, context) =>
				renderEditResult(result, options, theme, context, highlighter);
		}

		const registeredTool = {
			...originalTool,
			...(originalTool.name === "edit" ? { renderShell: "self" as const } : {}),
			renderCall(args: unknown, theme: PiTextTheme, context: unknown) {
				activeTheme = theme;
				const renderContext = asRecord(context);
				return new Text(
					renderToolCall(
						originalTool.name,
						asRecord(args),
						theme,
						highlighter,
						renderContext.expanded === true,
					),
					0,
					0,
				);
			},
			...(renderResultOverrides[originalTool.name]
				? { renderResult: renderResultOverrides[originalTool.name] }
				: {}),
		};
		pi.registerTool(registeredTool);
	}
}
