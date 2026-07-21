"""Plane automation controller: script-owned read and write protocol.

The controller re-fetches Plane state, validates author identity, drives the
Hermes worker for ask/triage reasoning, and performs every Plane mutation itself.
The worker never writes to Plane.
"""
from __future__ import annotations

import time
from dataclasses import replace
from typing import Any, Callable

from hermes_worker import HermesWorker, WorkerResult
from model_policy import ModelSelectorError, ModelSelectorPolicy
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
    "invalid_variant": "`{value}` is not a supported thinking variant. Use minimal, low, medium, high, xhigh, max, or ultra.",
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
        model_policy: ModelSelectorPolicy | None = None,
    ) -> None:
        self.plane_client = plane_client
        self._plane = plane_client
        self._worker_factory = worker_factory or (lambda _run: HermesWorker())
        self._hermes_user_id = hermes_user_id
        self._model_policy = model_policy or ModelSelectorPolicy({})

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

        if actor_comment_id and self._is_self_authored(
            run.project_id, run.work_item_id, actor_comment_id
        ):
            ledger.transition(run.run_id, RunState.CANCELLED)
            return True

        if parse_error is not None:
            return self._handle_parse_error(run, ledger, parse_error)

        try:
            effective_run = replace(run, model_selector=self._model_policy.resolve(run.model_selector))
        except ModelSelectorError as exc:
            return self._handle_model_selector_error(run, ledger, exc)

        if effective_run.operation in {InvocationOperation.ASK, InvocationOperation.TRIAGE}:
            return self._handle_ask_or_triage(effective_run, ledger)
        if effective_run.operation == InvocationOperation.GO:
            return self._handle_go(effective_run, ledger)
        return self._transition(run, ledger, RunState.FAILED)

    def _is_self_authored(self, project_id: str, work_item_id: str, comment_id: str) -> bool:
        if not self._hermes_user_id:
            return False
        try:
            comment = self._plane.get_comment(project_id, work_item_id, comment_id)
        except Exception:  # noqa: BLE001 - defensive guard, Plane fetch may fail
            return False
        actor = comment.get("actor", "") or comment.get("created_by", "") or ""
        if isinstance(actor, dict):
            actor = actor.get("id", "")
        return str(actor) == self._hermes_user_id

    def _handle_model_selector_error(
        self, run: Run, ledger: RunLedger, error: ModelSelectorError
    ) -> bool:
        choices = ", ".join(error.allowed) or "none"
        comment = self._create_durable_comment(
            run,
            f"Unsupported model selector `{error.selector}`. Allowed selectors: {choices}.",
        )
        ledger.set_final_comment(run.run_id, comment.get("id", ""))
        return self._transition(run, ledger, RunState.COMPLETED)

    def _handle_parse_error(self, run: Run, ledger: RunLedger, error: InvocationError) -> bool:
        template = HELP_MESSAGES.get(error.reason, "@Hermes could not understand that request.")
        # Render any detail tokens in the template. Keep it simple and safe.
        html = self._format_help(template, error.detail)
        comment = self._create_durable_comment(run, html)
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
            comment = self._create_durable_comment(run, html)
        except Exception as exc:  # noqa: BLE001
            ledger.transition(run.run_id, RunState.FAILED)
            return False

        ledger.set_final_comment(run.run_id, comment.get("id", ""))
        terminal = RunState.FAILED if result.status == "failure" else RunState.COMPLETED
        return self._transition(run, ledger, terminal)

    def _handle_go(self, run: Run, ledger: RunLedger) -> bool:
        try:
            work_item = self._plane.get_work_item(run.project_id, run.work_item_id)
        except Exception:  # noqa: BLE001
            return self._transition(run, ledger, RunState.FAILED)

        worker = self._worker_factory(run)
        preflight = worker.assess_go(run, work_item)
        if preflight.status != "success":
            return self._finish_without_start(run, ledger, preflight)

        try:
            work_item = self._plane.get_work_item(run.project_id, run.work_item_id)
        except Exception:  # noqa: BLE001
            return self._transition(run, ledger, RunState.FAILED)
        if run.label_triggered and not self._has_go_label(work_item):
            return self._transition(run, ledger, RunState.CANCELLED)

        self._assign_hermes(run, work_item)
        try:
            start = self._plane.create_comment(
                run.project_id,
                run.work_item_id,
                "🤖 Hermes started work on this ticket.",
                external_source=self._start_external_source(run),
                external_id=run.trigger_id,
            )
        except Exception:  # noqa: BLE001
            return self._transition(run, ledger, RunState.FAILED)
        start_comment_id = str(start.get("id", ""))
        ledger.set_start_comment(run.run_id, start_comment_id)

        result = worker.execute_go(run, work_item)
        if result.status == "blocked":
            try:
                self._plane.update_comment(
                    run.project_id,
                    run.work_item_id,
                    start_comment_id,
                    f"🚫 **Blocked — waiting for approval**\n\n{result.final_comment_markdown}",
                )
            except Exception:  # noqa: BLE001
                return False
            return self._transition(run, ledger, RunState.BLOCKED)

        try:
            final = self._create_durable_comment(
                run, f"{self._status_prefix(result.status)}{result.final_comment_markdown}"
            )
        except Exception:  # noqa: BLE001
            # Keep the temporary comment and the authorization visible when no
            # durable result could be recorded; a later delivery can recover it.
            return self._transition(run, ledger, RunState.BLOCKED)
        ledger.set_final_comment(run.run_id, final.get("id", ""))
        terminal = RunState.FAILED if result.status == "failure" else RunState.COMPLETED
        if not self._transition(run, ledger, terminal):
            return False
        return self.recover_go_cleanup(ledger.get_run(run.run_id), ledger)

    def recover_go_cleanup(self, run: Run, ledger: RunLedger) -> bool:
        """Finish idempotent GO cleanup after a post-result crash or retry."""
        if not run.final_comment_id:
            return False
        try:
            work_item = self._plane.get_work_item(run.project_id, run.work_item_id)
        except Exception:  # noqa: BLE001
            return False
        if run.start_comment_id:
            try:
                self._plane.delete_comment(run.project_id, run.work_item_id, run.start_comment_id)
            except Exception:  # noqa: BLE001
                return False
        self._cleanup_go_authorization(run, work_item)
        ledger.set_start_comment(run.run_id, "")
        return True

    def _finish_without_start(self, run: Run, ledger: RunLedger, result: WorkerResult) -> bool:
        try:
            final = self._create_durable_comment(
                run, f"{self._status_prefix(result.status)}{result.final_comment_markdown}"
            )
        except Exception:  # noqa: BLE001
            return self._transition(run, ledger, RunState.FAILED)
        ledger.set_final_comment(run.run_id, final.get("id", ""))
        terminal = RunState.FAILED if result.status == "failure" else RunState.COMPLETED
        return self._transition(run, ledger, terminal)

    def _assign_hermes(self, run: Run, work_item: dict[str, Any]) -> None:
        if not self._hermes_user_id:
            return
        assignees = self._ids(work_item.get("assignees", []))
        if self._hermes_user_id in assignees:
            return
        try:
            self._plane.update_work_item(
                run.project_id, run.work_item_id, assignees=[*assignees, self._hermes_user_id]
            )
        except Exception:  # noqa: BLE001
            pass

    def _cleanup_go_authorization(self, run: Run, work_item: dict[str, Any]) -> None:
        if run.label_triggered:
            labels = [
                label_id
                for label_id, name in self._named_ids(work_item.get("labels", []))
                if name.casefold() != "hermes:go"
            ]
            try:
                self._plane.update_work_item(run.project_id, run.work_item_id, labels=labels)
            except Exception:  # noqa: BLE001
                pass
        if self._hermes_user_id:
            assignees = [
                assignee_id
                for assignee_id in self._ids(work_item.get("assignees", []))
                if assignee_id != self._hermes_user_id
            ]
            try:
                self._plane.update_work_item(run.project_id, run.work_item_id, assignees=assignees)
            except Exception:  # noqa: BLE001
                pass

    def _create_durable_comment(self, run: Run, html: str) -> dict[str, Any]:
        return self._plane.create_comment(
            run.project_id,
            run.work_item_id,
            html,
            external_source=self._durable_external_source(run),
            external_id=run.trigger_id,
        )

    def _durable_external_source(self, run: Run) -> str:
        return "hermes-plane-comment" if not run.label_triggered else "hermes-plane-run"

    def _start_external_source(self, run: Run) -> str:
        return "hermes-plane-comment-start" if not run.label_triggered else "hermes-plane-run-start"

    def _has_go_label(self, work_item: dict[str, Any]) -> bool:
        return any(
            name.casefold() == "hermes:go"
            for _label_id, name in self._named_ids(work_item.get("labels", []))
        )

    def _ids(self, values: Any) -> list[str]:
        return [value for value, _name in self._named_ids(values)]

    def _named_ids(self, values: Any) -> list[tuple[str, str]]:
        result: list[tuple[str, str]] = []
        if not isinstance(values, list):
            return result
        for value in values:
            if isinstance(value, dict) and value.get("id"):
                result.append((str(value["id"]), str(value.get("name", ""))))
            elif isinstance(value, str):
                result.append((value, ""))
        return result

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
