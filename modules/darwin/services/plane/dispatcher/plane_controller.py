"""Plane automation controller: script-owned read and write protocol.

The controller re-fetches Plane state, validates author identity, drives the
Hermes worker for ask/triage reasoning, and performs every Plane mutation itself.
The worker never writes to Plane.
"""
from __future__ import annotations

import time
from typing import Any, Callable

from hermes_worker import HermesWorker, WorkerResult
from plane_client import PlaneClient
from plane_invocation import Invocation, InvocationError, InvocationOperation
from plane_runs import Run, RunLedger, RunState


HELP_MESSAGES: dict[str, str] = {
    "empty_body": "@Hermes needs a question or instruction after the mention.",
    "malformed_quoting": "Quoting looks broken; use plain text or balanced quotes.",
    "duplicate_flag": "Duplicate flag `{flag}`.",
    "unknown_flag": "Unknown flag `{flag}`. Use `--op ask|triage|go` or `--model <selector>`.",
    "missing_flag_value": "Flag `{flag}` needs a value.",
    "invalid_op_value": "`{value}` is not a supported operation. Use ask, triage, or go.",
    "unknown_command": "Unknown command `{command}`. Use `--op` flags or a plain question.",
}


class PlaneAutomationController:
    """Deterministic orchestrator for one automation run."""

    def __init__(
        self,
        *,
        plane_client: PlaneClient,
        worker_factory: Callable[[Run], HermesWorker] | None = None,
        hermes_user_id: str | None = None,
    ) -> None:
        self.plane_client = plane_client
        self._plane = plane_client
        self._worker_factory = worker_factory or (lambda _run: HermesWorker())
        self._hermes_user_id = hermes_user_id

    def process_run(
        self,
        run: Run,
        ledger: RunLedger,
        *,
        parse_error: InvocationError | None = None,
        actor_comment_id: str | None = None,
    ) -> bool:
        """Execute one run to completion and return True if it is now terminal.

        For ask/triage this fetches the ticket, invokes the worker, and posts the
        final comment. For parse errors it posts a deterministic help comment.
        """
        if RunState(run.state) in {RunState.COMPLETED, RunState.FAILED, RunState.CANCELLED}:
            return True

        if actor_comment_id and self._is_self_authored(run.project_id, actor_comment_id):
            ledger.transition(run.run_id, RunState.CANCELLED)
            return True

        if parse_error is not None:
            return self._handle_parse_error(run, ledger, parse_error)

        if run.operation in {InvocationOperation.ASK, InvocationOperation.TRIAGE}:
            return self._handle_ask_or_triage(run, ledger)

        # Phase 4 will handle GO. For Phase 3 we mark it blocked so it is not retried.
        return self._transition(run, ledger, RunState.BLOCKED)

    def _is_self_authored(self, project_id: str, comment_id: str) -> bool:
        if not self._hermes_user_id:
            return False
        try:
            comment = self._plane.get_comment(project_id, comment_id)
        except Exception:  # noqa: BLE001 - defensive guard, Plane fetch may fail
            return False
        actor = comment.get("actor", "") or comment.get("created_by", "") or ""
        if isinstance(actor, dict):
            actor = actor.get("id", "")
        return str(actor) == self._hermes_user_id

    def _handle_parse_error(self, run: Run, ledger: RunLedger, error: InvocationError) -> bool:
        template = HELP_MESSAGES.get(error.reason, "@Hermes could not understand that request.")
        # Render any detail tokens in the template. Keep it simple and safe.
        html = self._format_help(template, error.detail)
        comment = self._plane.create_comment(run.project_id, run.work_item_id, html)
        ledger.set_final_comment(run.run_id, comment.get("id", ""))
        return self._transition(run, ledger, RunState.COMPLETED)

    def _format_help(self, template: str, detail: str) -> str:
        if "{flag}" in template:
            return template.replace("{flag}", detail)
        if "{value}" in template:
            return template.replace("{value}", detail)
        if "{command}" in template:
            return template.replace("{command}", detail)
        return template

    def _handle_ask_or_triage(self, run: Run, ledger: RunLedger) -> bool:
        try:
            work_item = self._plane.get_work_item(run.project_id, run.work_item_id)
        except Exception as exc:  # noqa: BLE001
            ledger.transition(run.run_id, RunState.FAILED)
            return False

        worker = self._worker_factory(run)
        result = worker.invoke(run, work_item)

        status_prefix = self._status_prefix(result.status)
        html = f"{status_prefix}{result.final_comment_markdown}"
        try:
            comment = self._plane.create_comment(run.project_id, run.work_item_id, html)
        except Exception as exc:  # noqa: BLE001
            ledger.transition(run.run_id, RunState.FAILED)
            return False

        ledger.set_final_comment(run.run_id, comment.get("id", ""))
        terminal = RunState.FAILED if result.status == "failure" else RunState.COMPLETED
        return self._transition(run, ledger, terminal)

    def _status_prefix(self, status: str) -> str:
        if status == "clarification_needed":
            return "❓ **Clarification needed**\n\n"
        if status == "blocked":
            return "🚫 **Blocked**\n\n"
        if status == "failure":
            return "⚠️ **Failed**\n\n"
        return ""

    def _transition(self, run: Run, ledger: RunLedger, state: RunState) -> bool:
        try:
            ledger.transition(run.run_id, state)
        except Exception:  # noqa: BLE001
            return False
        return True
