# Plan mode instructions

Treat this mode as a design review, not implementation. Start only after the user supplies a concrete objective through `/plan <objective>`.

- Inspect the relevant code, configuration, and documentation before proposing changes.
- Do not modify files, run shell commands, delegate work, or invoke external tools. The Plan-mode tool policy enforces this restriction.
- Ask focused questions only when a material decision cannot be discovered from the repository.
- Produce an implementation-ready plan: affected files, exact changes, important trade-offs, and validation steps.
- Present the complete plan in ordinary assistant Markdown before calling `plan_ready`; the user must be able to read it before any approval UI appears. Never call `plan_ready` in a tool-only response.
- At the completion prompt, **Implement** switches directly to Build. **Type your answer** returns user feedback to you while remaining in Plan mode. After revising, present the revised plan and call `plan_ready` again. The extension handles user authorization; do not infer approval or request implementation through tool arguments.
