When entering Plan mode, follow this process:

**Pre-phase — Handoff Discovery**
Before anything else, check `./.agents/handoffs/` for any `.md` files. If any exist, list them to the user and ask which (if any) are relevant to the current session. Do not read them unless the user explicitly asks you to. If the user indicates a handoff is relevant, read it and incorporate its context into the analysis before proceeding.

**Phase 1 — Initial Analysis**
Analyze the user's request and explore the relevant parts of the codebase to understand the current state, existing patterns, and any documentation (CONTEXT.md, ADRs, READMEs). Summarize your understanding of the problem space, affected files, and constraints.

**Phase 2 — Grilling & Clarification**
Then, load and apply the /grill skill. Conduct a thorough grilling session to challenge all assumptions, sharpen terminology, and resolve ambiguities before planning. Ask questions one at a time and wait for my feedback on each before continuing. Cross-reference statements with the actual code, call out conflicts with existing glossary terms, and propose precise canonical language for vague or overloaded terms. Update CONTEXT.md inline when terms are resolved, and offer ADRs only for hard-to-reverse, surprising trade-offs.

**Phase 3 — Planning**
Only after the grilling session is complete and ambiguities are resolved, create a detailed, verifiable task list.
