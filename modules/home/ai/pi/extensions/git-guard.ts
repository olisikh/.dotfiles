/**
 * Git Guard Extension (local fork)
 *
 * Blocks git bash commands that are likely to open an interactive editor and hang the agent.
 * Creates stash checkpoints before each turn. Sends terminal notification when agent finishes.
 *
 * Dirty-repo warning removed.
 */

/* @ts-expect-error Pi provides this module to extensions at runtime. */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const INTERACTIVE_GIT_WARNING_PREFIX = "Interactive git command blocked";

interface InteractiveGitDetection {
	reason: string;
	suggestion: string;
}

function hasNonInteractiveEditorOverride(command: string): boolean {
	return /(\bGIT_EDITOR=\S+|\bGIT_SEQUENCE_EDITOR=\S+|-c\s+core\.editor=\S+|-c\s+sequence\.editor=\S+)/.test(command);
}

function hasExplicitCommitMessage(command: string): boolean {
	return /(^|\s)(-m|--message|-F|--file|-C|--reuse-message)(=|\s+)/.test(command);
}

function hasExplicitMergeMessage(command: string): boolean {
	return /(^|\s)(--no-edit|-m|-F|--file)\s+/.test(command) || /(^|\s)--no-edit(\s|$)/.test(command);
}

function hasExplicitTagMessage(command: string): boolean {
	return /(^|\s)(-m|--message|-F|--file)\s+/.test(command);
}

function splitShellSegments(command: string): string[] {
	return command
		.split(/&&|\|\||[;|\n]/)
		.map((segment) => segment.trim())
		.filter(Boolean);
}

function stripLeadingEnvAssignments(segment: string): string {
	let stripped = segment.trim().replace(/^\(+\s*/, "");
	while (true) {
		const next = stripped.replace(/^(?:[A-Za-z_][A-Za-z0-9_]*=(?:"[^"]*"|'[^']*'|\S+)\s+)*/, "");
		if (next === stripped) {
			return stripped;
		}
		stripped = next.trimStart();
	}
}

function detectInteractiveGitCommand(command: string): InteractiveGitDetection | null {
	for (const segment of splitShellSegments(command)) {
		const gitCommand = stripLeadingEnvAssignments(segment);
		if (!/^git\b/.test(gitCommand)) {
			continue;
		}

		if (
			/^git\s+rebase(\s|$)/.test(gitCommand) &&
			/(^|\s)--continue(\s|$)/.test(gitCommand) &&
			!hasNonInteractiveEditorOverride(segment)
		) {
			return {
				reason: "`git rebase --continue` can open an editor in agent environments.",
				suggestion:
					"Use `GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true git -c core.editor=true -c sequence.editor=true rebase --continue`.",
			};
		}

		if (
			/^git\s+commit(\s|$)/.test(gitCommand) &&
			!hasExplicitCommitMessage(gitCommand) &&
			!/(^|\s)--no-edit(\s|$)/.test(gitCommand) &&
			!hasNonInteractiveEditorOverride(segment)
		) {
			return {
				reason: "`git commit` without `-m`/`-F` can open an editor in agent environments.",
				suggestion: 'Use `git commit -m "type(scope): description"`.',
			};
		}

		if (
			/^git\s+merge(\s|$)/.test(gitCommand) &&
			!hasExplicitMergeMessage(gitCommand) &&
			!hasNonInteractiveEditorOverride(segment)
		) {
			return {
				reason: "`git merge` without `--no-edit` or an explicit message can open an editor in agent environments.",
				suggestion: "Use `git merge --no-edit <branch>` or provide `-m` explicitly.",
			};
		}

		if (
			/^git\s+tag(\s|$)/.test(gitCommand) &&
			/(^|\s)(-a|--annotate|-s|--sign)(\s|$)/.test(gitCommand) &&
			!hasExplicitTagMessage(gitCommand) &&
			!hasNonInteractiveEditorOverride(segment)
		) {
			return {
				reason: "Annotated or signed `git tag` can open an editor in agent environments.",
				suggestion: 'Use `git tag -a vX.Y.Z -m "message"`.',
			};
		}
	}

	return null;
}

function terminalNotify(title: string, body: string): void {
	if (process.env.KITTY_WINDOW_ID) {
		process.stdout.write(`\x1B]99;i=1:d=0;${title}\x1B\\`);
		process.stdout.write(`\x1B]99;i=1:p=body;${body}\u001b\\`);
	} else {
		process.stdout.write(`\u001b]777;notify;${title};${body}\u0007`);
	}
}

export default function (pi: ExtensionAPI) {
	let turnCount = 0;

	pi.on("tool_call", async (event) => {
		if (event.toolName !== "bash") {
			return;
		}
		const command = (event.input as { command?: string }).command ?? "";
		const detected = detectInteractiveGitCommand(command);
		if (!detected) {
			return;
		}
		return {
			block: true,
			reason: `${INTERACTIVE_GIT_WARNING_PREFIX}: ${detected.reason} ${detected.suggestion}`,
		};
	});

	pi.on("turn_start", async () => {
		turnCount++;
		try {
			await pi.exec("git", ["stash", "create", "-m", `oh-pi-turn-${turnCount}`]);
		} catch {
			// Not a git repo — skip silently
		}
	});

	pi.on("agent_end", () => {
		terminalNotify("oh-pi", `Done after ${turnCount} turn(s). Ready for input.`);
		turnCount = 0;
	});
}
