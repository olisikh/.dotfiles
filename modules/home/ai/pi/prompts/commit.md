---
description: Generate a conventional commit message from the staged git diff
---
Look at the staged git diff. Write a commit message in Conventional Commits format.

Rules:
- Subject: '<type>(<scope>): <imperative summary>' where type is one of feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert.
- Subject ≤50 chars when possible, hard cap 72, no trailing period, imperative mood.
- Scope optional; use it when it clarifies which module changed.
- Body only if the change's purpose is not obvious. Explain why, not what.
- Wrap body at 72 chars.
- Reference issues at the end if any: 'Closes #42'.
- No AI attribution, no emoji, no 'This commit does...', no first-person.

Output only the final commit message, nothing else. If no changes are staged, say so.
