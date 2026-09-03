# Hermes + Pi + Herdr orchestration study

## Executive conclusion

Use Hermes as the reasoning, planning, arbitration, and acceptance authority. Use Pi as a coding executor. Use Herdr as the persistent process/terminal runtime and operational visibility layer. Use Hermes Kanban as the durable task graph, lifecycle, handoff, and audit layer.

Do not make Herdr the task database, and do not make Pi a second top-level supervisor. The clean separation is:

```text
Hermes brain
  -> Kanban task graph and acceptance gates
  -> worker adapter
       -> Pi in a Herdr pane/worktree
       -> Hermes leaf worker
       -> deterministic script / test runner
  <- structured receipt, Git state, tests, lifecycle events
```

A skill is useful for teaching Hermes this policy, but a skill alone is not enforcement. The reliable implementation should eventually add a small Hermes plugin/adapter with a structured `pi` worker tool. The first version should use `pi -p` or Pi JSON mode; RPC and a native Kanban worker lane can follow after the protocol is proven.

## Verified local baseline

- Hermes: `0.21.0`, installed at `/Users/olisikh/.hermes/hermes-agent`.
- Hermes default profile: `gpt-5.6-luna-900k` via `openai-codex`.
- Current Hermes delegation settings: `model=gpt-5.6-luna`, `provider=openai-codex`, `max_concurrent_children=2`, `max_spawn_depth=1`, `max_iterations=15`, `child_timeout_seconds=600`, `worktree_isolation` absent/false, `orchestrator_enabled=true`.
- Pi: `0.84.4`, installed through `/etc/profiles/per-user/olisikh/bin/pi`.
- Pi packages include `pi-subagents`, `pi-context`, `pi-lens`, `@gaodes/pi-graphify`, and other local extensions.
- Pi's model catalog exposes `gpt-5.6-sol-900k`, `gpt-5.6-terra-900k`, and `gpt-5.6-luna-900k` at 900K context for `openai-codex`.
- Pi's Nix configuration currently defaults to `gpt-5.6-luna` and enforces an allowlist containing only `openai-codex/gpt-5.6-luna` for subagents.
- Herdr: `0.8.2`, protocol `20`, running as a persistent server at `/Users/olisikh/.config/herdr/herdr.sock`.
- Herdr exposes workspace, tab, pane, agent, worktree, wait, event, and socket-API primitives. It officially recognizes both Pi and Hermes.
- Herdr's native integrations are currently not installed for Pi or Hermes; current operation relies on process/screen detection rather than native lifecycle/session hooks.
- The dotfiles tree is clean at the time of this study.

## What Hermes already does well

Hermes `delegate_task` is appropriate for short-lived reasoning fanout:

- fresh isolated child context;
- separate child terminal session;
- concurrent batches;
- optional nested orchestrator role;
- configurable concurrency, depth, iteration, timeout, and worktree isolation;
- progress/stall monitoring and live child control;
- only the final summary returns to the parent context.

The important limitations for the desired swarm are structural:

- the native delegation model/provider is global for the delegation surface;
- a normal `delegate_task` call has no per-task model/provider selector;
- child toolsets are inherited rather than selected per call;
- flat delegation is the default;
- in-progress delegation is process/session-local, not durable execution;
- worktree isolation is opt-in;
- the installed configuration is conservative: two concurrent children, 15 iterations, and a 600-second child cap.

Therefore native delegation should remain the cheap, ephemeral reasoning lane. It should not become the durable heterogeneous executor fleet.

## What Pi already provides

Pi is a good executor because it has a small core and explicit integration surfaces:

- `pi -p` for bounded non-interactive jobs;
- `--mode json` for machine-readable event streams;
- `--mode rpc` for a long-lived process client;
- an SDK for embedding when subprocess isolation is not wanted;
- extensions, skills, prompt templates, packages, and custom providers;
- existing Graphify, context-management, lens, and subagent packages in this setup.

The installed `pi-subagents` package is Pi-to-Pi orchestration. It is not a Hermes bridge. It does, however, provide useful patterns for roles, worktrees, async runs, receipts, and controlled fanout.

Pi's own docs explicitly describe it as intentionally minimal and recommend extensions/packages for subagents, workflows, and background execution. That makes Pi a good worker runtime but a poor place to put the global authority policy if Hermes is meant to remain the brain.

## What Herdr adds

Herdr is a process and terminal runtime, not an agent brain:

- persistent server-owned panes survive client closure and SSH disconnects;
- workspaces and worktree-backed workspaces are addressable;
- agents can be started, prompted, read, waited on, and inspected;
- events and the Unix socket API support scripted control;
- agent status can be `working`, `blocked`, `done`, `idle`, or `unknown`;
- Pi and Hermes are supported agent kinds;
- the server exposes `agent.start`, `agent.prompt`, `agent.wait`, `agent.read`, `worktree.create`, and event-subscription primitives.

Use Herdr selectively for workers that should outlive the current Telegram/CLI turn. Keep WezTerm/tmux as the preferred human terminal surface. There is no need to replace the human-facing terminal workflow with Herdr.

Herdr should report operational state; it should not decide that a coding task satisfies its acceptance criteria. Hermes/Kanban should own that decision.

## Recommended architecture

### Layer 1: Hermes brain

Run Hermes' main profile on a frontier reasoning model, probably a 900K Sol or Terra variant. The choice should be measured rather than inferred from the name:

- **Sol**: candidate for highest-quality architecture, arbitration, and difficult debugging.
- **Terra**: candidate for a strong but less expensive everyday orchestrator.
- **Luna**: worker/default reasoning tier, especially for clear implementation briefs.
- **DeepSeek Flash**: cheap scanning, classification, extraction, test-output triage, and bounded mechanical reasoning.

No public benchmark was found that establishes the relative quality of the Sol/Terra/Luna deployment variants. Run a small local bakeoff on representative architecture, decomposition, failure-analysis, and review tasks before choosing the permanent brain model.

Hermes should own:

- user-intent interpretation;
- specification and decomposition;
- model/executor selection;
- dependency ordering;
- approval boundaries;
- conflict arbitration;
- acceptance and final reporting.

### Layer 2: durable task graph

Use Hermes Kanban for work that must survive session closure, gateway restart, worker failure, human input, or multi-stage review.

A task should contain at least:

- objective and acceptance criteria;
- repository and exact workspace policy;
- executor lane (`pi`, Hermes profile, deterministic runner);
- model policy;
- parent/dependency IDs;
- maximum runtime and retry policy;
- structured result/changed-files/test metadata.

Kanban is a better fit than `delegate_task` for a swarm because it provides durable rows, task dependencies, comments/handoffs, retries, blocked states, review states, and named worker identities.

### Layer 3: worker lanes

Recommended initial lanes:

- `pi-coder`: implementation/refactoring/debugging in an isolated worktree;
- `hermes-researcher`: reasoning-heavy research or analysis;
- `flash-scanner`: cheap classification, log/test triage, and bounded scans;
- `reviewer`: read-only or review-only validation on a fresh context;
- `deterministic`: tests, formatters, builds, schema checks, and repository snapshots without an LLM.

The parent should not run every implementation itself. It should create precise work packets, supervise progress, and verify receipts.

### Layer 4: Herdr runtime

For a Pi lane, the adapter should:

1. create or open a Herdr worktree-backed workspace;
2. start Pi in a real Herdr pane;
3. pass the exact worktree and task packet;
4. wait on Pi lifecycle/output events rather than polling raw terminal text when possible;
5. persist bounded logs and the full receipt outside the conversation context;
6. return a structured completion, blocked, failed, or unknown result to Hermes/Kanban.

A Herdr pane can remain alive if Hermes, Telegram, or the terminal client closes. That gives the desired durability without making Hermes responsible for holding a child process open inside its own request loop.

## Skill versus plugin

### Skill: necessary policy layer

Create a Hermes-only skill, centrally sourced under:

```text
~/.llm-harness/harness/hermes/skills/hermes-swarm-orchestration/
```

It should teach:

- when to keep work in Hermes;
- when to use native `delegate_task`;
- when to create a Kanban task;
- when to use Pi versus a Hermes worker;
- when to use Herdr;
- the worker-packet schema;
- worktree and one-writer rules;
- receipt and independent-verification requirements;
- escalation/retry rules;
- cost and concurrency ceilings.

Keep only a compact summary in `SOUL.md`: Hermes is the chief orchestrator; coding execution is delegated by default when the task is sufficiently specified; Hermes verifies every mutation-capable worker result.

### Plugin: necessary mechanical layer

A later Hermes plugin should expose a small structured interface such as:

```text
pi_worker_run(
  repository,
  objective,
  acceptance_criteria,
  worktree=true,
  model=..., 
  timeout=...
)
```

The plugin should:

- allow only configured executor kinds;
- resolve and validate the repository root;
- use direct argv/process execution, not interpolated shell strings;
- default write tasks to isolated worktrees;
- forbid push, merge, destructive cleanup, and privilege escalation;
- enforce concurrency and runtime limits;
- store full logs in an artifact directory;
- return a typed receipt;
- preserve the original Hermes result if the worker/maintenance path fails.

This is a personal Hermes plugin, not a Hermes core patch. Hermes' official plugin system is intended for custom tools and hooks, and the documentation recommends plugins over modifying core for personal integrations.

### Why not MCP first

Herdr has a socket API and MCP adapters are possible, but an MCP-first design would add another protocol layer while still leaving task lifecycle, worktrees, receipts, and acceptance to be designed. A small Hermes plugin can call Herdr's CLI/socket API and integrate directly with Hermes approvals and Kanban. Add MCP later if the same Herdr control surface should be shared with Pi, OpenCode, or external clients.

## Important Hermes Kanban finding

Hermes' current documentation explicitly defines a pluggable `spawn_fn` for non-Hermes worker lanes, but also says that a non-Hermes CLI lane is not yet a paved path. The missing work includes:

- mapping a CLI's workspace and sandbox rules;
- converting exit/results into `kanban_complete`, `kanban_request_review`, or `kanban_block` semantics;
- handling CLI authentication and policy;
- registering the lane and detecting crashes;
- preserving structured handoffs.

This makes a Pi Kanban lane feasible without patching Hermes core, but it is an integration project rather than an existing switch.

The clean target is a `pi` worker-lane plugin that supplies the external spawn adapter and writes the Kanban lifecycle result through the supported database/API interface. Until that exists, a skill plus `pi_worker_run` plugin can provide the same practical workflow without pretending Pi is a native Kanban profile.

## Suggested rollout

### Phase 0 — model and workflow bakeoff

- Compare Sol and Terra on a fixed set of architecture, decomposition, debugging, and review prompts.
- Measure quality, missed constraints, tool-call count, latency, and cost.
- Keep Luna/DeepSeek Flash tests separate from the brain benchmark.

### Phase 1 — policy only

- Author `hermes-swarm-orchestration` as a centrally managed skill.
- Add compact parent-only orchestration guidance to Hermes `SOUL.md`.
- Keep native `delegate_task` at depth 1.
- Use native delegation for ephemeral analysis and review, not durable code execution.

### Phase 2 — safe Pi runner

- Add a deterministic runner with explicit `cwd`, model, timeout, worktree, and artifact paths.
- Start with `pi -p` and a bounded final receipt.
- Add `--mode json` when progress/event parsing is needed.
- Run Pi directly first; add Herdr launch/monitoring after the runner contract works.

### Phase 3 — Herdr-backed workers

- Install or declaratively manage the official Pi/Herdr lifecycle integration rather than mutating the Nix-managed Pi tree blindly.
- Have the runner use Herdr workspaces, panes, `agent.prompt`, `agent.wait`, and event subscriptions.
- Keep full logs in Herdr/Kanban artifacts and send only compact status to Hermes.

### Phase 4 — Kanban integration

- Add `pi-coder` as a registered external worker lane.
- Route tasks by assignee and model policy.
- Use Kanban dependencies for planner → implementer → reviewer → remediation.
- Add crash detection, retry limits, blocked-task escalation, and review gates.

### Phase 5 — event-driven swarm

- Hermes reacts to Kanban and Herdr completion/blocked events instead of polling every pane.
- The brain wakes only when a task needs a decision, rework packet, approval, or final acceptance.
- Deterministic test/build workers run without consuming reasoning tokens.

## Guardrails

- One writer per worktree.
- No shared checkout mutation by parallel coding workers.
- No automatic push or merge by Pi.
- Hermes independently reads the final diff and runs/validates the required checks.
- Raw worker logs stay out of the brain context unless needed for diagnosis.
- Do not raise concurrency and nesting together; each nested level multiplies spend.
- Treat `unknown` after a supervisor/gateway crash as unknown, not success.
- Keep Herdr operational status separate from Kanban acceptance status.
- Do not install Herdr hooks directly into Nix-managed Pi paths without deciding how they will be represented in the dotfiles source.

## Primary sources

### Hermes

- Delegation: https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation
- Delegation patterns: https://hermes-agent.nousresearch.com/docs/guides/delegation-patterns
- Kanban: https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban
- Kanban worker lanes: https://hermes-agent.nousresearch.com/docs/user-guide/features/kanban-worker-lanes
- Plugins: https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins
- Plugin development: https://hermes-agent.nousresearch.com/docs/developer-guide/plugins
- Toolsets: https://hermes-agent.nousresearch.com/docs/reference/toolsets-reference

### Pi

- Usage: https://pi.dev/docs/latest/usage
- JSON mode: https://pi.dev/docs/latest/json
- RPC mode: https://pi.dev/docs/latest/rpc
- SDK: https://pi.dev/docs/latest/sdk
- Extensions: https://pi.dev/docs/latest/extensions
- Skills: https://pi.dev/docs/latest/skills

### Herdr

- Documentation index: https://herdr.dev/llms.txt
- Agent automation: https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/docs/next/website/src/content/docs/agent-automation.mdx
- Integrations: https://herdr.dev/docs/integrations
- Socket API: https://herdr.dev/docs/socket-api
- CLI reference: https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/docs/next/website/src/content/docs/cli-reference.mdx

### Local evidence

- Hermes source: `/Users/olisikh/.hermes/hermes-agent/tools/delegate_tool.py`, `/Users/olisikh/.hermes/hermes-agent/hermes_cli/kanban_db.py`
- Hermes config: `/Users/olisikh/.hermes/config.yaml`
- Pi Nix module: `/Users/olisikh/.dotfiles/modules/home/ai/pi/default.nix`
- Existing Pi Graphify integration: `/Users/olisikh/.dotfiles/modules/home/ai/pi/extensions/graphify-integration.ts`
- Herdr Nix module: `/Users/olisikh/.dotfiles/modules/home/ai/herdr/default.nix`
- Herdr config: `/Users/olisikh/.config/herdr/config.toml`
