#!/usr/bin/env python3
"""Tests for the durable Plane automation run ledger.

These tests verify the core guarantees required to move Hermes automation from
in-memory cooldowns to a persistent, recoverable, per-ticket lease:

- duplicate trigger_id never starts a second run;
- only one active lease exists per work item;
- expired leases become recoverable;
- terminal states are immutable.
"""
from __future__ import annotations

import sys
import time
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_invocation import Invocation, InvocationKind, InvocationOperation, InvocationSource
from plane_runs import RunLedger, RunState


def _make_invocation(
    *,
    trigger_id: str = "trigger-1",
    project_id: str = "project-1",
    work_item_id: str = "work-item-1",
    operation: InvocationOperation = InvocationOperation.GO,
    body: str = "Do the thing",
    label_triggered: bool = False,
) -> Invocation:
    return Invocation(
        trigger_id=trigger_id,
        project_id=project_id,
        work_item_id=work_item_id,
        kind=InvocationKind.COMMENT if not label_triggered else InvocationKind.LABEL,
        source=InvocationSource.COMMENT if not label_triggered else InvocationSource.LABEL,
        operation=operation,
        body=body,
        model_selector=None,
        label_triggered=label_triggered,
    )


def test_start_run_creates_pending_run() -> None:
    ledger = RunLedger(":memory:")
    invocation = _make_invocation()
    run = ledger.start_run(invocation)

    assert run.run_id
    assert run.trigger_id == invocation.trigger_id
    assert run.work_item_id == invocation.work_item_id
    assert run.project_id == invocation.project_id
    assert run.operation == invocation.operation
    assert run.body == invocation.body
    assert run.state == RunState.PENDING
    assert run.lease_expires_at is None
    assert run.start_comment_id == ""
    assert run.final_comment_id == ""


def test_start_run_is_idempotent_by_trigger_id() -> None:
    ledger = RunLedger(":memory:")
    invocation = _make_invocation()

    first = ledger.start_run(invocation)
    second = ledger.start_run(_make_invocation(body="different body"))

    assert first.run_id == second.run_id
    assert first.body == "Do the thing"
    assert second.body == "Do the thing"


def test_try_take_lease_grants_lease_when_pending() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())

    leased = ledger.try_take_lease(run.run_id, "session-a", lease_seconds=60)
    assert leased is True
    refreshed = ledger.get_run(run.run_id)
    assert refreshed.state == RunState.RUNNING
    assert refreshed.lease_expires_at is not None
    assert refreshed.worker_session_id == "session-a"


def test_try_take_lease_rejects_concurrent_holder() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())

    assert ledger.try_take_lease(run.run_id, "session-a", lease_seconds=60) is True
    assert ledger.try_take_lease(run.run_id, "session-b", lease_seconds=60) is False


def test_try_take_lease_allows_same_session_extension() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())

    assert ledger.try_take_lease(run.run_id, "session-a", lease_seconds=10) is True
    assert ledger.try_take_lease(run.run_id, "session-a", lease_seconds=60) is True
    refreshed = ledger.get_run(run.run_id)
    assert refreshed.lease_expires_at is not None


def test_try_take_lease_allows_after_expiry() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())

    assert ledger.try_take_lease(run.run_id, "session-a", lease_seconds=0) is True
    recovered = ledger.recover_expired_leases()
    assert len(recovered) == 1
    assert recovered[0].run_id == run.run_id
    assert ledger.try_take_lease(run.run_id, "session-b", lease_seconds=60) is True
    refreshed = ledger.get_run(run.run_id)
    assert refreshed.worker_session_id == "session-b"


def test_only_one_active_lease_per_work_item() -> None:
    ledger = RunLedger(":memory:")
    run_a = ledger.start_run(_make_invocation(trigger_id="a"))
    run_b = ledger.start_run(_make_invocation(trigger_id="b"))

    assert ledger.try_take_lease(run_a.run_id, "session", lease_seconds=60) is True
    assert ledger.try_take_lease(run_b.run_id, "session", lease_seconds=60) is False


def test_recover_expired_leases_returns_stale_runs() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())
    ledger.try_take_lease(run.run_id, "session-a", lease_seconds=0)

    recovered = ledger.recover_expired_leases()
    assert len(recovered) == 1
    assert recovered[0].run_id == run.run_id
    assert recovered[0].state == RunState.RUNNING


def test_recover_does_not_return_valid_leases() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())
    ledger.try_take_lease(run.run_id, "session", lease_seconds=600)

    assert ledger.recover_expired_leases() == []


def test_terminal_transition_is_immutable() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())
    ledger.try_take_lease(run.run_id, "session", lease_seconds=60)

    ledger.transition(run.run_id, RunState.COMPLETED)
    try:
        ledger.transition(run.run_id, RunState.FAILED)
    except ValueError as exc:
        assert "already terminal" in str(exc)
    else:
        raise AssertionError("terminal transition must be immutable")


def test_terminal_states_are_completed_failed_cancelled() -> None:
    for terminal in (RunState.COMPLETED, RunState.FAILED, RunState.CANCELLED):
        ledger = RunLedger(":memory:")
        run = ledger.start_run(_make_invocation())
        ledger.try_take_lease(run.run_id, "session", lease_seconds=60)
        ledger.transition(run.run_id, terminal)
        refreshed = ledger.get_run(run.run_id)
        assert refreshed.state == terminal


def test_set_start_comment_and_final_comment() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation())
    ledger.try_take_lease(run.run_id, "session", lease_seconds=60)

    ledger.set_start_comment(run.run_id, "comment-start-1")
    ledger.set_final_comment(run.run_id, "comment-final-1")
    refreshed = ledger.get_run(run.run_id)
    assert refreshed.start_comment_id == "comment-start-1"
    assert refreshed.final_comment_id == "comment-final-1"


def test_active_runs_filters_by_state_and_work_item() -> None:
    ledger = RunLedger(":memory:")
    run = ledger.start_run(_make_invocation(trigger_id="x", work_item_id="w-1"))
    ledger.try_take_lease(run.run_id, "session", lease_seconds=60)

    ledger.start_run(_make_invocation(trigger_id="y", work_item_id="w-2"))

    all_active = ledger.active_runs()
    assert len(all_active) == 2
    assert {r.work_item_id for r in all_active} == {"w-1", "w-2"}

    w1_active = ledger.active_runs(work_item_id="w-1")
    assert len(w1_active) == 1
    assert w1_active[0].work_item_id == "w-1"

    assert ledger.active_runs(work_item_id="w-3") == []


def test_metrics_report_state_counts_and_stale_lease_age_without_ticket_content() -> None:
    ledger = RunLedger(":memory:")
    running = ledger.start_run(_make_invocation(trigger_id="running", body="secret ticket body"))
    ledger.try_take_lease(running.run_id, "session", lease_seconds=0)
    blocked = ledger.start_run(_make_invocation(trigger_id="blocked", work_item_id="w-2"))
    ledger.try_take_lease(blocked.run_id, "session", lease_seconds=60)
    ledger.transition(blocked.run_id, RunState.BLOCKED)

    metrics = ledger.metrics()

    assert metrics["pending"] == 0
    assert metrics["running"] == 1
    assert metrics["blocked"] == 1
    assert metrics["stale_running"] == 1
    assert metrics["oldest_stale_lease_seconds"] >= 0
    assert "secret ticket body" not in repr(metrics)


def test_cancel_blocked_run_and_create_controlled_retry_of_failed_run() -> None:
    ledger = RunLedger(":memory:")
    blocked = ledger.start_run(_make_invocation(trigger_id="blocked"))
    ledger.try_take_lease(blocked.run_id, "session", lease_seconds=60)
    ledger.transition(blocked.run_id, RunState.BLOCKED)

    assert ledger.cancel_run(blocked.run_id).state == RunState.CANCELLED

    failed = ledger.start_run(_make_invocation(trigger_id="failed", work_item_id="other"))
    ledger.try_take_lease(failed.run_id, "session", lease_seconds=60)
    ledger.transition(failed.run_id, RunState.FAILED)
    retry = ledger.create_retry(failed.run_id)

    assert retry.state == RunState.PENDING
    assert retry.trigger_id.startswith(f"manual-retry:{failed.run_id}:")
    assert retry.work_item_id == failed.work_item_id
    assert ledger.pending_manual_retries() == [retry]


def test_cancel_for_trigger_marks_only_non_terminal_run_cancelled() -> None:
    ledger = RunLedger(":memory:")
    active = ledger.start_run(_make_invocation(trigger_id="deleted-source"))

    assert ledger.cancel_for_trigger("deleted-source") is True
    assert ledger.get_run(active.run_id).state == RunState.CANCELLED
    assert ledger.cancel_for_trigger("deleted-source") is False


if __name__ == "__main__":
    import signal

    def _timeout(_sig, _frame):
        raise SystemExit("plane_runs_tests_timeout")

    signal.signal(signal.SIGALRM, _timeout)
    signal.alarm(30)
    for name in sorted(dir()):
        if name.startswith("test_"):
            fn = globals()[name]
            fn()
            print(f"OK {name}")
    print("all_plane_runs_tests_passed")
