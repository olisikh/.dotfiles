import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { PI_STATUS_KEYS } from "./lib/pi-constants.ts";

const MODE_STATE_ENTRY = "olisikh:modes";
const MODE_STATUS_KEY = PI_STATUS_KEYS.modes;
const MAX_AUTOMATIC_GOAL_RUNS = 25;
const MAX_PLAN_LENGTH = 24_000;

const PLAN_READ_ONLY_TOOLS = new Set([
  "read",
  "grep",
  "find",
  "ls",
  "head",
  "tail",
  "symbol_search",
  "project_report",
  "module_report",
  "read_symbol",
  "read_enclosing",
  "lsp_diagnostics",
  "lens_diagnostics",
  "ast_grep_search",
  "ask_user_question",
  "plan_ready",
]);

type Mode = "build" | "plan" | "goal";

type GoalState = {
  objective: string;
  runs: number;
  paused: boolean;
};

type PlanState = {
  objective: string;
  content?: string;
  feedback?: string;
};

type ModeState = {
  version: 1;
  mode: Mode;
  goal?: GoalState;
  plan?: PlanState;
};

const initialState = (): ModeState => ({ version: 1, mode: "build" });

export default function modes(pi: ExtensionAPI) {
  let state = initialState();
  let context: ExtensionContext | undefined;
  let planToolBaseline: string[] | undefined;

  const restrictPlanTools = () => {
    const activeTools = pi.getActiveTools();
    planToolBaseline ??= activeTools;
    const permitted = activeTools.filter((tool) =>
      PLAN_READ_ONLY_TOOLS.has(tool),
    );
    if (!permitted.includes("plan_ready")) permitted.push("plan_ready");
    pi.setActiveTools(permitted);
  };
  const restorePlanTools = () => {
    if (!planToolBaseline) return;
    pi.setActiveTools(planToolBaseline);
    planToolBaseline = undefined;
  };
  const persist = () => pi.appendEntry(MODE_STATE_ENTRY, state);
  const publishMode = (mode: Mode, modeState: string, active: boolean) => {
    pi.events.emit("pi:mode-changed", {
      version: 1,
      source: "olisikh:modes",
      mode,
      state: modeState,
      active,
    });
  };
  const refresh = () => {
    if (!context) return;
    const label =
      state.mode === "goal"
        ? `GOAL: ${state.goal?.objective ?? ""}`
        : state.mode === "plan"
          ? "PLAN"
          : undefined;
    context.ui.setStatus(MODE_STATUS_KEY, label);
    publishMode(
      state.mode,
      state.mode === "build"
        ? "off"
        : state.mode === "goal" && state.goal?.paused
          ? "paused"
          : "active",
      state.mode !== "build",
    );
  };
  const setState = (next: ModeState) => {
    const previousMode = state.mode;
    if (previousMode !== "plan" && next.mode === "plan") restrictPlanTools();
    if (previousMode === "plan" && next.mode !== "plan") restorePlanTools();
    state = next;
    persist();
    if (previousMode !== "build" && previousMode !== next.mode) {
      publishMode(previousMode, "off", false);
    }
    refresh();
  };
  const enterBuild = (ctx: ExtensionContext, message?: string) => {
    setState(initialState());
    if (message) ctx.ui.notify(message, "info");
  };

  pi.on("session_start", (_event, ctx) => {
    context = ctx;
    state = restoreState(ctx) ?? initialState();
    if (state.mode === "plan") restrictPlanTools();
    refresh();
  });

  pi.on("session_shutdown", () => {
    restorePlanTools();
    context?.ui.setStatus(MODE_STATUS_KEY, undefined);
    context = undefined;
  });

  pi.on("before_agent_start", (event) => {
    if (state.mode === "build") return;
    if (state.mode === "goal" && state.goal && !state.goal.paused) {
      return {
        systemPrompt: `${event.systemPrompt}\n\n<active_goal>\nObjective: ${state.goal.objective}\nKeep working toward this objective. Do not treat a partial result, a plan, a failed check, or a request for clarification as completion. Call goal_complete only after the objective is fully complete and verified, with concrete evidence. After calling goal_complete, send its returned report to the user as a normal assistant response.\n</active_goal>`,
      };
    }
    if (state.mode === "plan" && state.plan) {
      const feedback = state.plan.feedback
        ? `\nLatest user feedback:\n${state.plan.feedback}\nUse plan_ready with implement: true only when you are 100% certain this feedback explicitly authorizes implementation after revision. If there is any ambiguity, revise the plan and call plan_ready without implement so the user receives the two choices again.`
        : "";
      return {
        systemPrompt: `${event.systemPrompt}\n\n<plan_mode>\nObjective: ${state.plan.objective}\nYou are in read-only planning mode. Explore and ask questions when needed. Before calling plan_ready, present the complete implementation plan in ordinary assistant Markdown so the user can read it before any approval UI appears; never use plan_ready in a tool-only response. Then call plan_ready with that same concrete plan. Do not attempt file changes or shell commands.${feedback}\n</plan_mode>`,
      };
    }
  });

  pi.on("tool_call", (event) => {
    if (state.mode !== "plan") return;
    if (PLAN_READ_ONLY_TOOLS.has(event.toolName)) return;
    return {
      block: true,
      reason: `Plan mode is read-only; ${event.toolName} is unavailable. Call plan_ready when the plan is ready, then approve implementation.`,
    };
  });

  pi.on("agent_settled", (_event, ctx) => {
    if (state.mode !== "goal" || !state.goal || state.goal.paused) return;
    const providerError = latestAssistantProviderError(ctx);
    if (providerError) {
      setState({ ...state, goal: { ...state.goal, paused: true } });
      ctx.ui.notify(
        `Goal paused after a provider error: ${providerError}. Resolve it, then use /goal continue.`,
        "warning",
      );
      return;
    }
    if (state.goal.runs >= MAX_AUTOMATIC_GOAL_RUNS) {
      setState({
        ...state,
        goal: { ...state.goal, paused: true },
      });
      context?.ui.notify(
        `Goal paused after ${MAX_AUTOMATIC_GOAL_RUNS} automatic runs. Use /goal continue to resume.`,
        "warning",
      );
      return;
    }

    setState({
      ...state,
      goal: { ...state.goal, runs: state.goal.runs + 1 },
    });
    pi.sendUserMessage(
      "Continue the active goal. Do not stop at a plan, partial result, failed check, or ordinary clarification. Keep working until the objective is complete and verified, then call goal_complete with concrete evidence.",
      { deliverAs: "followUp" },
    );
  });

  pi.registerTool({
    name: "goal_complete",
    label: "Goal Complete",
    description:
      "Finish the active goal after all requested work is implemented and verified. The returned report is passed to the model so it can send the report to the user as a normal assistant response.",
    parameters: Type.Object({
      summary: Type.String({ minLength: 1, maxLength: 4_000 }),
      evidence: Type.String({ minLength: 1, maxLength: 4_000 }),
    }),
    async execute(_id, params, _signal, _update, ctx) {
      if (state.mode !== "goal" || !state.goal) {
        throw new Error(
          "goal_complete is only available while a goal is active",
        );
      }
      const objective = state.goal.objective;
      const report = [
        `Goal complete: ${objective}`,
        "",
        "Summary:",
        params.summary,
        "",
        "Evidence:",
        params.evidence,
      ].join("\n");
      enterBuild(ctx, `Goal complete: ${params.summary}`);
      // Keep the turn open so Pi can give the report to the model for a normal
      // assistant response instead of ending on the tool result.
      return {
        content: [{ type: "text", text: report }],
        details: { summary: params.summary, evidence: params.evidence },
      };
    },
  });

  pi.registerTool({
    name: "plan_ready",
    label: "Plan Ready",
    description:
      "After presenting the complete plan in ordinary assistant text, submit that same plan for user approval before switching to build mode.",
    parameters: Type.Object({
      plan: Type.String({ minLength: 1, maxLength: MAX_PLAN_LENGTH }),
      implement: Type.Optional(
        Type.Boolean({
          description:
            "Set true only when typed user feedback unambiguously authorizes implementation after revision. If there is any doubt, omit it so plan_ready asks the user again.",
        }),
      ),
    }),
    async execute(_id, params, _signal, _update, ctx) {
      if (state.mode !== "plan" || !state.plan) {
        throw new Error(
          "plan_ready is only available while plan mode is active",
        );
      }
      const plan = params.plan.trim();
      setState({ ...state, plan: { ...state.plan, content: plan } });
      if (params.implement) {
        const feedback = state.plan?.feedback;
        if (!feedback) {
          throw new Error(
            "plan_ready with implement: true requires typed user feedback authorizing implementation",
          );
        }
        startImplementation(ctx, plan);
        return {
          content: [
            { type: "text", text: "Plan revised and switched to build mode." },
          ],
          details: { approved: true, feedback },
          terminate: true,
        };
      }
      if (!ctx.hasUI) {
        return savedPlanResult();
      }
      const choice = await ctx.ui.select("Plan ready", [
        "Implement",
        "Type your answer",
      ]);
      if (choice === "Implement") {
        startImplementation(ctx, plan);
        return {
          content: [
            { type: "text", text: "Plan approved. Switched to build mode." },
          ],
          details: { approved: true },
          terminate: true,
        };
      }
      if (choice !== "Type your answer") return savedPlanResult();

      const feedback = await ctx.ui.input(
        "Plan feedback",
        "What should change?",
      );
      if (!feedback?.trim()) return savedPlanResult();
      setState({
        ...state,
        plan: { ...state.plan, feedback: feedback.trim() },
      });
      return {
        content: [
          {
            type: "text",
            text: `User feedback:\n${feedback.trim()}\n\nRevise the plan while remaining in Plan mode. Call plan_ready with implement: true only when you are 100% certain this feedback explicitly authorizes implementation after revision. If you have any doubt, call plan_ready without implement so the user receives the two choices again.`,
          },
        ],
        details: { approved: false, feedback: feedback.trim() },
      };

      function savedPlanResult() {
        return {
          content: [
            {
              type: "text",
              text: "Plan saved. Use /plan implement when you are ready to build it.",
            },
          ],
          details: { approved: false },
          terminate: true,
        };
      }
    },
  });

  pi.registerCommand("goal", {
    description:
      "Set an autonomous goal: /goal <objective>; pause, continue, or clear it",
    handler: async (args, ctx) => {
      const input = args.trim();
      if (input === "pause") {
        if (state.mode !== "goal" || !state.goal)
          return ctx.ui.notify("No active goal.", "warning");
        setState({ ...state, goal: { ...state.goal, paused: true } });
        ctx.ui.notify("Goal paused. Use /goal continue to resume.", "info");
        return;
      }
      if (input === "continue") {
        if (state.mode !== "goal" || !state.goal?.paused)
          return ctx.ui.notify("No paused goal.", "warning");
        setState({ ...state, goal: { ...state.goal, paused: false } });
        pi.sendUserMessage("Resume the active goal and continue working.");
        return;
      }
      if (input === "clear") return enterBuild(ctx, "Goal cleared.");
      if (!input) {
        ctx.ui.notify(
          "Usage: /goal <objective>, /goal pause, /goal continue, or /goal clear",
          "warning",
        );
        return;
      }
      startGoal(input);
    },
  });

  pi.registerCommand("plan", {
    description:
      "Manage read-only planning: /plan <objective>, show, implement, or exit",
    handler: async (args, ctx) => {
      const input = args.trim();
      if (!input) {
        ctx.ui.notify(
          "Usage: /plan <objective>, /plan show, /plan implement, or /plan exit.",
          "warning",
        );
        return;
      }
      if (input === "show") {
        if (state.mode !== "plan" || !state.plan) {
          ctx.ui.notify("No active plan.", "warning");
          return;
        }
        ctx.ui.notify(`Plan: ${state.plan.objective}`, "info");
        return;
      }
      if (input === "implement") {
        if (state.mode !== "plan" || !state.plan?.content) {
          ctx.ui.notify("No ready plan to implement.", "warning");
          return;
        }
        startImplementation(ctx, state.plan.content);
        return;
      }
      if (input === "exit" || input === "clear")
        return enterBuild(ctx, "Plan discarded.");
      startPlan(input);
    },
  });

  pi.registerCommand("build", {
    description:
      "Return to normal build mode and clear any active plan or goal",
    handler: async (_args, ctx) => enterBuild(ctx, "Build mode enabled."),
  });

  function startGoal(objective: string) {
    const goal: GoalState = { objective, runs: 0, paused: false };
    setState({ version: 1, mode: "goal", goal });
    pi.sendUserMessage(
      withModePrompt("goal", `Start this goal now: ${objective}`),
    );
  }

  function startPlan(objective: string) {
    setState({ version: 1, mode: "plan", plan: { objective } });
    pi.sendUserMessage(
      withModePrompt(
        "plan",
        `Plan this work without modifying files: ${objective}`,
      ),
    );
  }

  function startImplementation(ctx: ExtensionContext, plan: string) {
    enterBuild(ctx, "Plan approved. Build mode enabled.");
    pi.sendUserMessage(`Implement this approved plan now:\n\n${plan}`, {
      deliverAs: "followUp",
    });
  }
}

function restoreState(ctx: ExtensionContext): ModeState | undefined {
  const entries = ctx.sessionManager.getBranch();
  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];
    if (entry.type !== "custom" || entry.customType !== MODE_STATE_ENTRY)
      continue;
    const state = parseState(entry.data);
    if (state) return state;
  }
  return undefined;
}

function parseState(value: unknown): ModeState | undefined {
  if (!isRecord(value) || value.version !== 1) return undefined;
  if (value.mode === "build") return initialState();
  if (
    value.mode === "goal" &&
    isRecord(value.goal) &&
    typeof value.goal.objective === "string"
  ) {
    return {
      version: 1,
      mode: "goal",
      goal: {
        objective: value.goal.objective,
        runs: typeof value.goal.runs === "number" ? value.goal.runs : 0,
        paused: value.goal.paused === true,
      },
    };
  }
  if (
    value.mode === "plan" &&
    isRecord(value.plan) &&
    typeof value.plan.objective === "string"
  ) {
    return {
      version: 1,
      mode: "plan",
      plan: {
        objective: value.plan.objective,
        content:
          typeof value.plan.content === "string"
            ? value.plan.content
            : undefined,
        feedback:
          typeof value.plan.feedback === "string"
            ? value.plan.feedback
            : undefined,
      },
    };
  }
  return undefined;
}

function latestAssistantProviderError(
  ctx: ExtensionContext,
): string | undefined {
  const entries = ctx.sessionManager.getBranch();
  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];
    if (entry.type !== "message" || entry.message.role !== "assistant")
      continue;
    if (entry.message.stopReason !== "error") return undefined;
    return (entry.message.errorMessage || "Unknown provider error").slice(
      0,
      240,
    );
  }
  return undefined;
}

function withModePrompt(mode: "goal" | "plan", kickoff: string): string {
  const instructions = readModePrompt(mode);
  if (!instructions) return kickoff;
  return `${kickoff}\n\n<personal_${mode}_instructions>\n${instructions}\n</personal_${mode}_instructions>`;
}

function readModePrompt(mode: "goal" | "plan"): string | undefined {
  try {
    const content = readFileSync(
      join(getAgentDir(), "modes", `${mode}.md`),
      "utf8",
    ).trim();
    return content ? content.slice(0, 16_000) : undefined;
  } catch {
    return undefined;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
