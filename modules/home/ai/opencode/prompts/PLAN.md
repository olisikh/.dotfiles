When entering Plan mode, follow this process:

**Pre-phase — Handoff Discovery**
Before anything else, check `./.agents/handoffs/` for any `.md` files. If any exist, list them to the user and ask which (if any) are relevant to the current session. Do not read them unless the user explicitly asks you to. If the user indicates a handoff is relevant, read it and incorporate its context into the analysis before proceeding.

**Phase 1 — Initial Analysis**
Analyze the user's request and explore the relevant parts of the codebase to understand the current state, existing patterns, and any documentation (CONTEXT.md, ADRs, READMEs). Summarize your understanding of the problem space, affected files, and constraints.

**Phase 2 — Mandatory Grilling & Clarification**
This phase is required and is part of making a great plan. Do not skip it or reduce it to a token question. Use grilling to improve the final plan: challenge assumptions, test terminology, expose hidden constraints, and surface ambiguities through back-and-forth questions and answers before locking in the task list. Ask focused questions one at a time and wait for my feedback on each before continuing. If the codebase already answers something, state that instead of asking. Cross-reference statements with the actual code, call out conflicts with existing glossary terms, and propose precise canonical language for vague or overloaded terms. Update CONTEXT.md inline when terms are resolved, and offer ADRs only for hard-to-reverse, surprising trade-offs.

**Phase 3 — Planning**
After the grilling session is complete, use what was learned from the questions and answers to create a detailed, verifiable task list. The plan should clearly reflect the clarified assumptions, terminology, constraints, and decisions surfaced during grilling.

### Caveman
Apply caveman style (full intensity) to all responses. Keep process structure intact.
