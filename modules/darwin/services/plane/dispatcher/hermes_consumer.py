"""Consume queued Plane deliveries by driving the deterministic controller.

The consumer no longer forwards webhooks to Hermes. Instead it re-fetches the
source comment or labels from Plane, resolves the run in the ledger, takes a
per-ticket lease, and asks the controller to execute one run to a terminal state.
"""
from __future__ import annotations

import os
import time
from typing import Any

from plane_controller import PlaneAutomationController
from plane_invocation import (
    Invocation,
    InvocationError,
    InvocationKind,
    InvocationOperation,
    InvocationSource,
    parse_comment_invocation,
    select_label_invocation,
)
from plane_runs import Run, RunLedger


def consume(
    queue: Any,
    ledger: RunLedger,
    controller: PlaneAutomationController,
    *,
    worker_session_id: str | None = None,
    lease_seconds: float = 300.0,
) -> int:
    """Claim pending deliveries and drive each to a terminal run state.

    Returns the number of deliveries that were finished (terminal runs). Deliveries
    whose lease is held by another worker remain pending and will be reclaimed
    later.
    """
    if worker_session_id is None:
        worker_session_id = f"{os.getpid()}-{time.monotonic()}"
    deliveries = queue.claim_pending()
    finished = 0
    for delivery in deliveries:
        if _process_delivery(delivery, ledger, controller, worker_session_id, lease_seconds):
            queue.finish(delivery[0])
            finished += 1
    return finished


def _process_delivery(
    delivery: tuple[str, str, str, str, str, str],
    ledger: RunLedger,
    controller: PlaneAutomationController,
    worker_session_id: str,
    lease_seconds: float,
) -> bool:
    delivery_id, project_id, work_item_id, _identifier, event_type, comment_id = delivery

    if event_type == "issue_comment":
        return _process_comment_delivery(
            delivery_id, project_id, work_item_id, comment_id,
            ledger, controller, worker_session_id, lease_seconds,
        )
    if event_type == "issue":
        return _process_label_delivery(
            delivery_id, project_id, work_item_id,
            ledger, controller, worker_session_id, lease_seconds,
        )
    return True


def _process_comment_delivery(
    delivery_id: str,
    project_id: str,
    work_item_id: str,
    comment_id: str,
    ledger: RunLedger,
    controller: PlaneAutomationController,
    worker_session_id: str,
    lease_seconds: float,
) -> bool:
    try:
        comment = controller.plane_client.get_comment(project_id, comment_id)
    except Exception:  # noqa: BLE001 - Plane fetch failures are retried later
        return False
    comment_html = comment.get("comment_html", "")
    invocation = parse_comment_invocation(delivery_id, project_id, work_item_id, comment_html)

    if invocation is None:
        # Not a Hermes mention; nothing to do.
        return True

    if isinstance(invocation, InvocationError):
        run = _ensure_run(
            ledger,
            Invocation(
                trigger_id=delivery_id,
                project_id=project_id,
                work_item_id=work_item_id,
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.ASK,
                body="",
            ),
        )
        if not ledger.try_take_lease(run.run_id, worker_session_id, lease_seconds=lease_seconds):
            return False
        return controller.process_run(run, ledger, parse_error=invocation, actor_comment_id=comment_id)

    run = _ensure_run(ledger, invocation)
    if not ledger.try_take_lease(run.run_id, worker_session_id, lease_seconds=lease_seconds):
        return False
    return controller.process_run(run, ledger, actor_comment_id=comment_id)


def _process_label_delivery(
    delivery_id: str,
    project_id: str,
    work_item_id: str,
    ledger: RunLedger,
    controller: PlaneAutomationController,
    worker_session_id: str,
    lease_seconds: float,
) -> bool:
    try:
        work_item = controller.plane_client.get_work_item(project_id, work_item_id)
    except Exception:  # noqa: BLE001
        return False
    labels = [
        label.get("name", "")
        for label in work_item.get("labels", [])
        if isinstance(label, dict)
    ]
    invocation = select_label_invocation(delivery_id, project_id, work_item_id, labels)
    if invocation is None:
        return True

    run = _ensure_run(ledger, invocation)
    if not ledger.try_take_lease(run.run_id, worker_session_id, lease_seconds=lease_seconds):
        return False
    return controller.process_run(run, ledger)


def _ensure_run(ledger: RunLedger, invocation: Invocation) -> Run:
    existing = ledger.maybe_get_run_by_trigger_id(invocation.trigger_id)
    if existing is not None:
        return existing
    return ledger.start_run(invocation)
