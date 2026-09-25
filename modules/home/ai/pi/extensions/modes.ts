import { readFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve, sep } from "node:path";
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
  instructions?: string;
  content?: string;
  feedback?: string;
  revisionAuthorized?: boolean;
  reminded?: boolean;
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
    planToolBaseline ??= activeTools.filter((tool) => tool !== "plan_ready");
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
  const syncPlanReadyTool = () => {
    const activeTools = pi.getActiveTools();
    const planIsActive = state.mode === "plan" && state.plan !== undefined;
    if (activeTools.includes("plan_ready") === planIsActive) return;
    pi.setActiveTools(
      planIsActive
        ? [...activeTools, "plan_ready"]
        : activeTools.filter((tool) => tool !== "plan_ready"),
    );
  };
  const syncGoalCompleteTool = () => {
    const activeTools = pi.getActiveTools();
    const goalIsActive = state.mode === "goal" && state.goal !== undefined;
    const goalToolIsActive = activeTools.includes("goal_complete");
    if (goalIsActive === goalToolIsActive) return;
    pi.setActiveTools(
      goalIsActive
        ? [...activeTools, "goal_complete"]
        : activeTools.filter((tool) => tool !== "goal_complete"),
    );
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
    syncPlanReadyTool();
    syncGoalCompleteTool();
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
    syncGoalCompleteTool();
    if (state.mode === "plan") restrictPlanTools();
    syncPlanReadyTool();
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
        ? `\nLatest user feedback:\n${state.plan.feedback}\nRevise the plan and submit it with plan_ready. The extension handles any user authorization to implement.`
        : "";
      return {
        systemPrompt: `${event.systemPrompt}\n\n<plan_mode>\nObjective: ${state.plan.objective}\n${state.plan.instructions ?? "Plan this objective without modifying files. Present the complete plan in ordinary assistant Markdown, then call plan_ready with the same plan."}\nBefore calling plan_ready, present the complete implementation plan in ordinary assistant Markdown so the user can read it before any approval UI appears. Never use plan_ready in a tool-only response. Do not attempt file changes or shell commands.${feedback}\n</plan_mode>`,
      };
    }
  });

  // Old sessions included instructions in the kickoff user message. Custom
  // state is not model context; only the legacy message needs filtering.
  pi.on("context", (event) => {
    if (state.mode === "plan") return;
    return {
      messages: event.messages.map((message) => {
        if (message.role !== "user") return message;
        const strip = (text: string) =>
          text.startsWith("Plan this work without modifying files: ")
            ? text.replace(/\n\n<personal_plan_instructions>\n[\s\S]*?\n<\/personal_plan_instructions>/, "")
            : text;
        return {
          ...message,
          content: typeof message.content === "string"
            ? strip(message.content)
            : message.content.map((part: { type: string; text?: string }) =>
                part.type === "text" ? { ...part, text: strip(part.text ?? "") } : part,
              ),
        };
      }),
    };
  });

  pi.on("tool_call", (event, ctx) => {
    if (isProtectedPromptRequest(event.toolName, event.input, ctx.cwd)) {
      return {
        block: true,
        reason: "Plan instructions are loaded only by the user-invoked /plan command; model file access is blocked.",
      };
    }
    if (event.toolName === "plan_ready") {
      if (state.mode !== "plan" || !state.plan) {
        return {
          block: true,
          reason: "plan_ready is only available while Plan mode is active.",
        };
      }
      if (!hasVisiblePlan(ctx, isRecord(event.input) ? event.input.plan : undefined)) {
        return {
          block: true,
          reason: "Present the complete plan in assistant text before calling plan_ready with that same plan.",
        };
      }
    }
    if (
      event.toolName === "goal_complete" &&
      (state.mode !== "goal" || !state.goal)
    ) {
      return {
        block: true,
        reason: "goal_complete is only available while a goal is active.",
      };
    }
    if (state.mode !== "plan") return;
    if (PLAN_READ_ONLY_TOOLS.has(event.toolName)) return;
    return {
      block: true,
      reason: `Plan mode is read-only; ${event.toolName} is unavailable. Call plan_ready when the plan is ready, then approve implementation.`,
    };
  });

  pi.on("tool_result", (event, ctx) => {
    if (!["grep", "bash", "powershell", "ast_grep_search"].includes(event.toolName)) return;
    const text = event.content
      .filter((part: { type: string }) => part.type === "text")
      .map((part: { text: string }) => part.text)
      .join("\n");
    const filenameFreeSearch = ["grep", "ast_grep_search"].includes(event.toolName)
      && text.length > 0
      && searchScopeIncludesPrompt(event.input, ctx.cwd)
      && !/^No (?:matches|results) found\.?$/i.test(text.trim())
      && !hasSearchResultFilenames(text);
    if (!containsProtectedPromptPath(text) && !filenameFreeSearch) return;
    return {
      content: [{ type: "text", text: "Search results that may expose the protected Plan prompt were withheld. Narrow the search to other files." }],
      details: { redacted: true },
    };
  });

  pi.on("input", (event, ctx) => {
    if (state.mode !== "plan" || !state.plan || !state.plan.content) return;
    if (event.source !== "interactive" && event.source !== "rpc") return;
    if (isDirectApproval(event.text)) {
      startImplementation(ctx, state.plan.content);
      return { action: "handled" };
    }
    // Ordinary typed feedback is genuine user input; extension messages are not.
    setState({ ...state, plan: {
      ...state.plan,
      feedback: event.text,
      revisionAuthorized: authorizesRevision(event.text),
      reminded: false,
    } });
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (state.mode === "plan" && state.plan) {
      const text = latestFinalAssistantText(ctx);
      if (!text || text === state.plan.content) return;
      if (looksLikeFinishedPlan(text)) {
        const result = await offerPlan(ctx, text);
        if (result.action === "feedback") {
          pi.sendUserMessage(`Revise the plan according to this user feedback: ${result.feedback}`, { deliverAs: "followUp" });
        }
      } else if (!state.plan.reminded && !text.endsWith("?")) {
        setState({ ...state, plan: { ...state.plan, reminded: true } });
        pi.sendUserMessage("If the plan is ready, present it in ordinary assistant text and call plan_ready with the same plan. If you need clarification, ask the user and stop.", { deliverAs: "followUp" });
      }
      return;
    }
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
    promptSnippet: "Submit a fully presented Plan-mode plan for user approval; unavailable outside Plan mode",
    promptGuidelines: ["In Plan mode, show the complete plan in ordinary assistant text, then call plan_ready with that same plan."],
    parameters: Type.Object({
      plan: Type.String({ minLength: 1, maxLength: MAX_PLAN_LENGTH }),
    }),
    async execute(_id, params, _signal, _update, ctx) {
      if (state.mode !== "plan" || !state.plan) {
        throw new Error(
          "plan_ready is only available while plan mode is active",
        );
      }
      if (!hasVisiblePlan(ctx, params.plan)) {
        throw new Error("Present the complete plan in assistant text before calling plan_ready.");
      }
      const decision = await offerPlan(ctx, params.plan.trim());
      if (decision.action === "implement") {
        return {
          content: [{ type: "text", text: "Plan approved. Switched to build mode." }],
          details: { approved: true },
          terminate: true,
        };
      }
      if (decision.action === "feedback") {
        return {
          content: [{ type: "text", text: `User feedback:\n${decision.feedback}\n\nRevise the plan while remaining in Plan mode. Present the revision, then call plan_ready again.` }],
          details: { approved: false, feedback: decision.feedback },
        };
      }
      return {
        content: [{ type: "text", text: "Plan saved. Use /plan implement when you are ready to build it." }],
        details: { approved: false },
        terminate: true,
      };
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
    // Only the user-invoked command enters here. Keep these instructions out of
    // user messages, which remain in context after returning to Build mode.
    setState({ version: 1, mode: "plan", plan: {
      objective,
      instructions: readModePrompt("plan"),
    } });
    pi.sendUserMessage(`Plan this work without modifying files: ${objective}`);
  }

  async function offerPlan(ctx: ExtensionContext, plan: string): Promise<
    { action: "implement" | "saved" } | { action: "feedback"; feedback: string }
  > {
    if (state.mode !== "plan" || !state.plan) return { action: "saved" };
    const previous = state.plan;
    setState({ ...state, plan: { ...previous, content: plan } });
    if (previous.revisionAuthorized && previous.content && previous.content !== plan) {
      startImplementation(ctx, plan);
      return { action: "implement" };
    }
    if (!ctx.hasUI) return { action: "saved" };
    const choice = await ctx.ui.select("Plan ready", ["Implement", "Type your answer"]);
    if (choice === "Implement") {
      startImplementation(ctx, plan);
      return { action: "implement" };
    }
    if (choice !== "Type your answer") return { action: "saved" };
    const feedback = (await ctx.ui.input("Plan feedback", "What should change?"))?.trim();
    if (!feedback) return { action: "saved" };
    if (isDirectApproval(feedback)) {
      startImplementation(ctx, plan);
      return { action: "implement" };
    }
    setState({ ...state, plan: {
      ...state.plan!,
      feedback,
      revisionAuthorized: authorizesRevision(feedback),
      reminded: false,
    } });
    return { action: "feedback", feedback };
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
        instructions: typeof value.plan.instructions === "string" ? value.plan.instructions : undefined,
        revisionAuthorized: value.plan.revisionAuthorized === true,
        reminded: value.plan.reminded === true,
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

function withModePrompt(mode: "goal", kickoff: string): string {
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

function latestFinalAssistantText(ctx: ExtensionContext): string | undefined {
  for (const entry of [...ctx.sessionManager.getBranch()].reverse()) {
    if (entry.type !== "message" || entry.message.role !== "assistant") continue;
    if (entry.message.stopReason !== "stop") return undefined;
    return entry.message.content
      .filter((part: { type: string }) => part.type === "text")
      .map((part: { text: string }) => part.text)
      .join("\n")
      .trim();
  }
  return undefined;
}

function looksLikeFinishedPlan(text: string): boolean {
  return text.length >= 120 && /(?:^|\n)#{1,4}\s+.*\bplan\b/i.test(text)
    && (text.match(/(?:^|\n)\s*\d+[.)]\s+\S/g) ?? []).length >= 2
    && !text.endsWith("?");
}

function isDirectApproval(text: string): boolean {
  const answer = text.trim();
  return /^(?:(?:yes|looks good)[,.! ]*)?(?:(?:go ahead(?: and)?|please)\s+)?(?:implement|build|apply)(?:\s+(?:it|this|the(?:\s+(?:approved|current))?\s+plan))?[.! ]*$/i.test(answer)
    || /^(?:yes[,! ]*)?go ahead[.! ]*$/i.test(answer)
    || /^(?:yes[,! ]*)?(?:i (?:want you to|would like you to)|you can)\s+(?:go ahead and\s+)?(?:implement|build|apply)(?:\s+(?:it|this|the(?:\s+(?:approved|current))?\s+plan))?[.! ]*$/i.test(answer);
}

function authorizesRevision(text: string): boolean {
  return /\b(?:revise|change|update|adjust|fix|make)\b/i.test(text)
    && /\b(?:then|after(?:ward|wards)?(?:\s+that)?)\s+(?:please\s+)?(?:implement|build|apply)\b/i.test(text);
}

function containsProtectedPromptPath(text: string): boolean {
  return /(?:^|[^\w.])plan-mode\.md\b|(?:^|[/\\])modes[/\\]plan\.md\b/i.test(text);
}

function hasVisiblePlan(ctx: ExtensionContext, plan: unknown): boolean {
  if (typeof plan !== "string" || !plan.trim()) return false;
  const latest = [...ctx.sessionManager.getBranch()].reverse().find(
    (entry) => entry.type === "message" && entry.message.role === "assistant",
  );
  if (!latest || latest.type !== "message" || latest.message.role !== "assistant") return false;
  const visible = latest.message.content
    .filter((part: { type: string }) => part.type === "text")
    .map((part: { text: string }) => part.text)
    .join("\n");
  return visible.includes(plan.trim());
}

function searchScopeIncludesPrompt(input: unknown, cwd: string): boolean {
  if (!isRecord(input)) return false;
  const scopes = Array.isArray(input.paths) ? input.paths : [input.path ?? cwd];
  const protectedPaths = [
    resolve(homedir(), ".dotfiles/modules/home/ai/pi/prompts/plan-mode.md"),
    resolve(getAgentDir(), "modes/plan.md"),
  ];
  return scopes.some((scope) => {
    if (typeof scope !== "string") return false;
    const raw = scope.replace(/^@/, "");
    const absolute = raw.startsWith("~/") ? resolve(homedir(), raw.slice(2)) : resolve(cwd, raw);
    let canonical = absolute;
    try { canonical = realpathSync(absolute); } catch { /* Missing paths cannot contain the prompt. */ }
    return protectedPaths.some((protectedPath) => {
      let target = protectedPath;
      try { target = realpathSync(protectedPath); } catch { /* Use the configured path. */ }
      return target === canonical || target.startsWith(canonical + sep);
    });
  });
}

function hasSearchResultFilenames(text: string): boolean {
  // Directory-scoped grep normally identifies each matching file. A custom
  // search that omits filenames is withheld if its scope includes the prompt.
  return /(?:^|\n)\s*(?:>\s*)?\S+\.\w+(?::\d+|\s+\(\d+\s+matches?\))/m.test(text);
}

function isProtectedPromptRequest(toolName: string, input: unknown, cwd: string): boolean {
  if (!isRecord(input)) return false;
  const protectedPaths = [
    resolve(getAgentDir(), "modes", "plan.md"),
    resolve(homedir(), ".dotfiles", "modules/home/ai/pi/prompts/plan-mode.md"),
  ];
  const isProtected = (value: unknown): boolean => {
    if (typeof value !== "string") return false;
    const raw = value.replace(/^@/, "");
    const path = raw.startsWith("~/")
      ? resolve(homedir(), raw.slice(2))
      : resolve(cwd, raw);
    if (protectedPaths.includes(path) || path.endsWith("/modules/home/ai/pi/prompts/plan-mode.md")) return true;
    try {
      const actual = realpathSync(path);
      return protectedPaths.some((protectedPath) => {
        try { return actual === realpathSync(protectedPath); }
        catch { return false; }
      });
    } catch {
      return false;
    }
  };
  if (["read", "head", "tail", "grep", "find", "ls", "read_symbol", "read_enclosing", "ast_grep_search"].includes(toolName)) {
    if (isProtected(input.path) || isProtected(input.file)) return true;
    if (Array.isArray(input.paths) && input.paths.some(isProtected)) return true;
  }
  // Direct shell requests are covered, but arbitrary shell indirection needs
  // a sandbox rather than an extension-level path check.
  return ["bash", "powershell"].includes(toolName)
    && typeof input.command === "string"
    && containsProtectedPromptPath(input.command);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
