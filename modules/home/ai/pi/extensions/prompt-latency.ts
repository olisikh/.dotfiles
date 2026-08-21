import type {
	ExtensionAPI,
	ExtensionCommandContext,
} from "@mariozechner/pi-coding-agent";

type Phase =
	| "input"
	| "before-agent"
	| "agent-start"
	| "provider-request"
	| "provider-response"
	| "first-update";

type Trace = {
	marks: Partial<Record<Phase, number>>;
};

type InputEvent = { source?: string };
type AssistantUpdate = {
	assistantMessageEvent?: { type?: string };
};

function now(): number {
	return performance.now();
}

function duration(start: number | undefined, end: number | undefined): string {
	if (start === undefined || end === undefined) return "n/a";
	return `${(end - start).toFixed(0)}ms`;
}

function render(trace: Trace | undefined): string {
	if (!trace) return "No interactive prompt measured yet.";
	const { marks } = trace;
	return [
		"prompt latency",
		`input → before-agent: ${duration(marks.input, marks["before-agent"])} `,
		`before-agent → agent-start: ${duration(marks["before-agent"], marks["agent-start"])} `,
		`agent-start → request: ${duration(marks["agent-start"], marks["provider-request"])} `,
		`request → response: ${duration(marks["provider-request"], marks["provider-response"])} `,
		`response → first-update: ${duration(marks["provider-response"], marks["first-update"])} `,
	].join("\n");
}

export default function (pi: ExtensionAPI): void {
	let trace: Trace | undefined;

	const mark = (phase: Phase) => {
		if (!trace || trace.marks[phase] !== undefined) return;
		trace.marks[phase] = now();
	};

	pi.on("input", (event: InputEvent) => {
		if (event.source !== "interactive") return;
		trace = { marks: { input: now() } };
	});
	pi.on("before_agent_start", () => mark("before-agent"));
	pi.on("agent_start", () => mark("agent-start"));
	pi.on("before_provider_request", () => mark("provider-request"));
	pi.on("after_provider_response", () => mark("provider-response"));
	pi.on("message_update", (event: AssistantUpdate) => {
		if (event.assistantMessageEvent?.type) mark("first-update");
	});

	pi.registerCommand("prompt-latency", {
		description: "Show the most recent interactive prompt timing trace",
		handler: async (_args: string, ctx: ExtensionCommandContext) => {
			ctx.ui.notify(render(trace), "info");
		},
	});
}
