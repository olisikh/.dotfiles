import {
	createBashTool,
	createReadTool,
	getLanguageFromPath,
	highlightCode,
	// @ts-expect-error Pi provides this virtual module to extensions at runtime.
} from "@earendil-works/pi-coding-agent";
/* @ts-expect-error Pi provides these modules to extensions at runtime. */
import { Text } from "@earendil-works/pi-tui";

type PiExtensionAPI = {
	registerTool: (definition: unknown) => void;
};

type PiTheme = {
	fg: (color: string, text: string) => string;
	bold: (text: string) => string;
};

type BashArguments = {
	command?: string;
};

type ReadArguments = {
	path?: string;
	file_path?: string;
	offset?: number;
	limit?: number;
};

function currentWorkingDirectory(): string {
	const processLike = (
		globalThis as typeof globalThis & {
			process?: { cwd?: () => string };
		}
	).process;
	return processLike?.cwd?.() ?? ".";
}

function renderCommand(command: string, theme: PiTheme): string {
	const source = command.replace(/\r\n?/g, "\n").trimEnd();
	let lines: string[];

	try {
		// highlightCode uses the active Pi theme and returns ANSI-styled lines.
		lines = highlightCode(source, "bash", theme);
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

function renderReadCall(args: ReadArguments, theme: PiTheme): string {
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

	return (
		theme.fg("bashMode", theme.bold("read")) +
		" " +
		theme.fg("syntaxFunction", rawPath) +
		range +
		languageLabel
	);
}

export default function (pi: PiExtensionAPI) {
	const cwd = currentWorkingDirectory();
	const originalBash = createBashTool(cwd);
	const originalRead = createReadTool(cwd);

	// Keep execution, schemas, prompt guidance, and result rendering from Pi;
	// replace only the call-row presentation.
	pi.registerTool({
		...originalBash,
		renderCall(args: BashArguments, theme: PiTheme) {
			return new Text(renderCommand(args.command ?? "", theme), 0, 0);
		},
	});

	pi.registerTool({
		...originalRead,
		renderCall(args: ReadArguments, theme: PiTheme) {
			return new Text(renderReadCall(args, theme), 0, 0);
		},
	});
}
