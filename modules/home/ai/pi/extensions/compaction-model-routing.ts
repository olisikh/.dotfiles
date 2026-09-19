// @ts-ignore Pi supplies this module to extensions at runtime.
import { uuidv7 } from "@earendil-works/pi-ai";
// @ts-ignore Pi supplies this module to extensions at runtime.
import { convertToLlm, getAgentDir, serializeConversation, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
// @ts-ignore The standalone extension directory does not include Node typings.
import { readFile } from "node:fs/promises";
// @ts-ignore The standalone extension directory does not include Node typings.
import path from "node:path";

const CONFIG_PATH = path.join(getAgentDir(), "compaction-models.json");
const FALLBACK_NOTICE = "Configured compaction models were unavailable or failed; using the active session model.";

const SUMMARIZATION_SYSTEM_PROMPT = `You are a context summarization assistant. Your task is to read a conversation between a user and an AI assistant, then produce a structured summary following the exact format specified.

Do NOT continue the conversation. Do NOT respond to any questions in the conversation. ONLY output the structured summary.`;

const SUMMARIZATION_PROMPT = `The messages above are a conversation to summarize. Create a structured context checkpoint summary that another LLM will use to continue the work.

Use this EXACT format:

## Goal
[What is the user trying to accomplish? Can be multiple items if the session covers different tasks.]

## Constraints & Preferences
- [Any constraints, preferences, or requirements mentioned by user]
- [Or "(none)" if none were mentioned]

## Progress
### Done
- [x] [Completed tasks/changes]

### In Progress
- [ ] [Current work]

### Blocked
- [Issues preventing progress, if any]

## Key Decisions
- **[Decision]**: [Brief rationale]

## Next Steps
1. [Ordered list of what should happen next]

## Critical Context
- [Any data, examples, or references needed to continue]
- [Or "(none)" if not applicable]

Keep each section concise. Preserve exact file paths, function names, and error messages.`;

const UPDATE_SUMMARIZATION_PROMPT = `The messages above are NEW conversation messages to incorporate into the existing summary provided in <previous-summary> tags.

Update the existing structured summary with new information. RULES:
- PRESERVE all existing information from the previous summary
- ADD new progress, decisions, and context from the new messages
- UPDATE the Progress section: move items from "In Progress" to "Done" when completed
- UPDATE "Next Steps" based on what was accomplished
- PRESERVE exact file paths, function names, and error messages
- If something is no longer relevant, you may remove it

Use this EXACT format:

## Goal
[Preserve existing goals, add new ones if the task expanded]

## Constraints & Preferences
- [Preserve existing, add new ones discovered]

## Progress
### Done
- [x] [Include previously done items AND newly completed items]

### In Progress
- [ ] [Current work - update based on progress]

### Blocked
- [Current blockers - remove if resolved]

## Key Decisions
- **[Decision]**: [Brief rationale] (preserve all previous, add new)

## Next Steps
1. [Update based on current state]

## Critical Context
- [Preserve important context, add new if needed]

Keep each section concise. Preserve exact file paths, function names, and error messages.`;

type CompactionModelConfig = {
  defaultModel?: string | null;
  fallbackModels?: string[];
};

type ModelReference = {
  provider: string;
  id: string;
  display: string;
};

function parseModelReference(value: string): ModelReference | undefined {
  const separator = value.indexOf("/");
  if (separator <= 0 || separator === value.length - 1) return undefined;

  return {
    provider: value.slice(0, separator),
    id: value.slice(separator + 1),
    display: value,
  };
}

export function configuredModelReferences(config: CompactionModelConfig): ModelReference[] {
  const configured = [config.defaultModel, ...(config.fallbackModels ?? [])];
  const seen = new Set<string>();

  return configured.flatMap((value) => {
    if (value == null || seen.has(value)) return [];
    seen.add(value);
    const reference = parseModelReference(value);
    return reference ? [reference] : [];
  });
}

async function loadModelReferences(): Promise<ModelReference[]> {
  try {
    const config = JSON.parse(await readFile(CONFIG_PATH, "utf8")) as CompactionModelConfig;
    return configuredModelReferences(config);
  } catch {
    return [];
  }
}

function responseText(response: { content: Array<{ type: string; text?: string }> }): string {
  return response.content
    .flatMap((content) => content.type === "text" && content.text ? [content.text] : [])
    .join("\n")
    .trim();
}

function buildSummaryRequest(
  messages: unknown[],
  previousSummary: string | undefined,
  customInstructions: string | undefined,
) {
  let prompt = `<conversation>\n${serializeConversation(convertToLlm(messages as never))}\n</conversation>\n\n`;
  if (previousSummary) prompt += `<previous-summary>\n${previousSummary}\n</previous-summary>\n\n`;
  prompt += previousSummary ? UPDATE_SUMMARIZATION_PROMPT : SUMMARIZATION_PROMPT;
  if (customInstructions) prompt += `\n\nAdditional focus: ${customInstructions}`;

  return {
    systemPrompt: SUMMARIZATION_SYSTEM_PROMPT,
    messages: [{
      role: "user" as const,
      content: [{ type: "text" as const, text: prompt }],
      timestamp: Date.now(),
    }],
  };
}

export default function compactionModelRouting(pi: ExtensionAPI): void {
  // @ts-ignore Pi's runtime declaration supplies the hook event and context types.
  pi.on("session_before_compact", async (event, ctx) => {
    const candidates = await loadModelReferences();
    if (candidates.length === 0 || event.signal.aborted) return;

    const { preparation, customInstructions, signal } = event;
    const messages = [
      ...preparation.messagesToSummarize,
      ...preparation.turnPrefixMessages,
    ];

    for (const candidate of candidates) {
      const model = ctx.modelRegistry.find(candidate.provider, candidate.id);
      if (!model) continue;

      try {
        const maxTokens = Math.min(
          Math.floor(preparation.settings.reserveTokens * 0.8),
          model.maxTokens > 0 ? model.maxTokens : Number.POSITIVE_INFINITY,
        );
        const response = await ctx.modelRegistry.complete(
          model,
          buildSummaryRequest(messages, preparation.previousSummary, customInstructions),
          {
            maxTokens,
            signal,
            cacheRetention: "none",
            sessionId: uuidv7(),
          },
        );
        if (response.stopReason === "aborted" || response.stopReason === "error") {
          if (signal.aborted) return;
          continue;
        }
        const summary = responseText(response);
        if (!summary) continue;

        return {
          compaction: {
            summary,
            firstKeptEntryId: preparation.firstKeptEntryId,
            retainedTail: preparation.retainedTail,
            tokensBefore: preparation.tokensBefore,
            usage: response.usage,
          },
        };
      } catch {
        if (signal.aborted) return;
      }
    }

    if (!signal.aborted) ctx.ui.notify(FALLBACK_NOTICE, "warning");
    // Returning undefined delegates to Pi's normal current-session-model compaction.
    return;
  });
}
