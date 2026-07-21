#!/usr/bin/env python3
"""Durable run ledger and per-ticket lease for Plane Hermes automation.

This replaces the in-memory cooldown with SQLite-backed state so a restart,
crash, or duplicate webhook cannot lose or duplicate work. All state changes
are narrow, typed, and controller-owned; the Hermes worker never mutates this
table directly.
"""
from __future__ import annotations

import sqlite3
import threading
import time
import uuid
from dataclasses import dataclass
from enum import Enum
from typing import Any

from plane_invocation import Invocation, InvocationKind, InvocationOperation, InvocationSource


class RunState(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    BLOCKED = "blocked"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass(frozen=True, slots=True)
class Run:
    run_id: str
    trigger_id: str
    project_id: str
    work_item_id: str
    operation: InvocationOperation
    body: str
    model_selector: str | None
    label_triggered: bool
    state: RunState
    lease_expires_at: float | None
    start_comment_id: str
    final_comment_id: str
    worker_session_id: str
    retry_count: int
    created_at: float
    updated_at: float


_TERMINAL_STATES = frozenset({RunState.COMPLETED, RunState.FAILED, RunState.CANCELLED})


class RunLedger:
    """SQLite-backed ledger for automation runs.

    Guarantees:
    - one run per trigger_id (idempotency);
    - one active lease per work_item_id;
    - expired leases can be recovered by a new worker session;
    - terminal states are immutable.
    """

    def __init__(self, database_path: str) -> None:
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(database_path, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS runs (
              run_id TEXT PRIMARY KEY,
              trigger_id TEXT NOT NULL UNIQUE,
              project_id TEXT NOT NULL,
              work_item_id TEXT NOT NULL,
              operation TEXT NOT NULL,
              body TEXT NOT NULL,
              model_selector TEXT,
              label_triggered INTEGER NOT NULL DEFAULT 0,
              state TEXT NOT NULL DEFAULT 'pending',
              lease_expires_at REAL,
              start_comment_id TEXT NOT NULL DEFAULT '',
              final_comment_id TEXT NOT NULL DEFAULT '',
              worker_session_id TEXT NOT NULL DEFAULT '',
              retry_count INTEGER NOT NULL DEFAULT 0,
              created_at REAL NOT NULL,
              updated_at REAL NOT NULL
            )
            """
        )
        self._conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_runs_work_item ON runs(work_item_id, state)"
        )
        self._conn.commit()

    def start_run(self, invocation: Invocation) -> Run:
        """Create or return the existing run for this trigger_id."""
        now = time.monotonic()
        run_id = str(uuid.uuid4())
        with self._lock:
            existing = self._conn.execute(
                "SELECT run_id FROM runs WHERE trigger_id = ?", (invocation.trigger_id,)
            ).fetchone()
            if existing:
                run_id = existing["run_id"]
            else:
                self._conn.execute(
                    """
                    INSERT INTO runs (
                      run_id, trigger_id, project_id, work_item_id, operation, body,
                      model_selector, label_triggered, state, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        run_id,
                        invocation.trigger_id,
                        invocation.project_id,
                        invocation.work_item_id,
                        invocation.operation.value,
                        invocation.body,
                        invocation.model_selector,
                        int(invocation.label_triggered),
                        RunState.PENDING.value,
                        now,
                        now,
                    ),
                )
                self._conn.commit()
            row = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs WHERE run_id = ?
                """,
                (run_id,),
            ).fetchone()
        if row is None:
            raise KeyError(run_id)
        return self._row_to_run(row)

    def get_run_by_trigger_id(self, trigger_id: str) -> Run:
        with self._lock:
            row = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs WHERE trigger_id = ?
                """,
                (trigger_id,),
            ).fetchone()
        if row is None:
            raise KeyError(trigger_id)
        return self._row_to_run(row)

    def maybe_get_run_by_trigger_id(self, trigger_id: str) -> Run | None:
        try:
            return self.get_run_by_trigger_id(trigger_id)
        except KeyError:
            return None

    def get_run(self, run_id: str) -> Run:
        with self._lock:
            row = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs WHERE run_id = ?
                """,
                (run_id,),
            ).fetchone()
        if row is None:
            raise KeyError(run_id)
        return self._row_to_run(row)

    def try_take_lease(
        self,
        run_id: str,
        worker_session_id: str,
        *,
        lease_seconds: float,
    ) -> bool:
        """Try to make this run running with a fresh lease.

        Returns True if the caller now holds the lease. Fails if another worker
        holds an unexpired lease for the same work_item_id, or if the run is
        already terminal. Same-session extension is always allowed.
        """
        now = time.monotonic()
        expiry = now + lease_seconds
        with self._lock:
            run = self._conn.execute(
                """
                SELECT work_item_id, state, lease_expires_at, worker_session_id
                FROM runs WHERE run_id = ?
                """,
                (run_id,),
            ).fetchone()
            if run is None:
                return False
            if RunState(run["state"]) in _TERMINAL_STATES:
                return False

            # One active lease per work_item_id.
            active = self._conn.execute(
                """
                SELECT run_id, lease_expires_at, worker_session_id
                FROM runs
                WHERE work_item_id = ?
                  AND state IN ('running', 'blocked')
                ORDER BY lease_expires_at DESC
                """,
                (run["work_item_id"],),
            ).fetchone()
            if active:
                if active["run_id"] != run_id:
                    # A different run holds (or held) the lease for this ticket.
                    if active["lease_expires_at"] is not None and active["lease_expires_at"] > now:
                        return False
                    # An expired lease on a different run still blocks starting a
                    # new active run until recovery clears it.
                    return False
                # Same run: extension for same session, or takeover if expired.
                if active["worker_session_id"] != worker_session_id:
                    if active["lease_expires_at"] is not None and active["lease_expires_at"] > now:
                        return False
                    # Different session is taking over an expired lease: count as retry.
                    self._conn.execute(
                        "UPDATE runs SET retry_count = retry_count + 1 WHERE run_id = ?",
                        (run_id,),
                    )
            elif run["worker_session_id"] and run["worker_session_id"] != worker_session_id:
                # No active row for this ticket, but the run already has a previous
                # session assigned (e.g. lease expired and was recovered): count retry.
                self._conn.execute(
                    "UPDATE runs SET retry_count = retry_count + 1 WHERE run_id = ?",
                    (run_id,),
                )

            self._conn.execute(
                """
                UPDATE runs
                SET state = 'running', lease_expires_at = ?, worker_session_id = ?, updated_at = ?
                WHERE run_id = ?
                """,
                (expiry, worker_session_id, now, run_id),
            )
            self._conn.commit()
        return True

    def recover_expired_leases(self, *, buffer_seconds: float = 0.0) -> list[Run]:
        """Return runs whose lease has expired and may be picked up again."""
        now = time.monotonic()
        with self._lock:
            rows = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs
                WHERE state = 'running'
                  AND lease_expires_at IS NOT NULL
                  AND lease_expires_at <= ?
                ORDER BY created_at
                """,
                (now - buffer_seconds,),
            ).fetchall()
        return [self._row_to_run(row) for row in rows]

    def transition(self, run_id: str, new_state: RunState) -> Run:
        """Move a run to a new state. Terminal states are immutable."""
        if new_state in _TERMINAL_STATES:
            pass  # terminal requested
        with self._lock:
            row = self._conn.execute(
                "SELECT state FROM runs WHERE run_id = ?", (run_id,)
            ).fetchone()
            if row is None:
                raise KeyError(run_id)
            current = RunState(row["state"])
            if current in _TERMINAL_STATES:
                raise ValueError(f"run {run_id} is already terminal ({current.value})")
            now = time.monotonic()
            self._conn.execute(
                "UPDATE runs SET state = ?, updated_at = ? WHERE run_id = ?",
                (new_state.value, now, run_id),
            )
            self._conn.commit()
            refreshed = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs WHERE run_id = ?
                """,
                (run_id,),
            ).fetchone()
        if refreshed is None:
            raise KeyError(run_id)
        return self._row_to_run(refreshed)

    def set_start_comment(self, run_id: str, comment_id: str) -> None:
        self._set_field(run_id, "start_comment_id", comment_id)

    def set_final_comment(self, run_id: str, comment_id: str) -> None:
        self._set_field(run_id, "final_comment_id", comment_id)

    def _set_field(self, run_id: str, field: str, value: Any) -> None:
        now = time.monotonic()
        with self._lock:
            self._conn.execute(
                f"UPDATE runs SET {field} = ?, updated_at = ? WHERE run_id = ?",
                (value, now, run_id),
            )
            self._conn.commit()

    def active_runs(self, work_item_id: str | None = None) -> list[Run]:
        """Return runs in non-terminal states, optionally filtered by ticket."""
        with self._lock:
            if work_item_id:
                rows = self._conn.execute(
                    """
                    SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                           model_selector, label_triggered, state, lease_expires_at,
                           start_comment_id, final_comment_id, worker_session_id, retry_count,
                           created_at, updated_at
                    FROM runs
                    WHERE work_item_id = ? AND state NOT IN ('completed', 'failed', 'cancelled')
                    ORDER BY created_at
                    """,
                    (work_item_id,),
                ).fetchall()
            else:
                rows = self._conn.execute(
                    """
                    SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                           model_selector, label_triggered, state, lease_expires_at,
                           start_comment_id, final_comment_id, worker_session_id, retry_count,
                           created_at, updated_at
                    FROM runs
                    WHERE state NOT IN ('completed', 'failed', 'cancelled')
                    ORDER BY created_at
                    """,
                ).fetchall()
        return [self._row_to_run(row) for row in rows]

    def cancel_for_trigger(self, trigger_id: str) -> bool:
        """Cancel a non-terminal run whose source can no longer be fetched."""
        with self._lock:
            row = self._conn.execute("SELECT run_id, state FROM runs WHERE trigger_id = ?", (trigger_id,)).fetchone()
            if row is None or row["state"] in {state.value for state in TERMINAL_STATES}:
                return False
            self._conn.execute(
                "UPDATE runs SET state = ?, updated_at = ? WHERE run_id = ?",
                (RunState.CANCELLED.value, time.monotonic(), row["run_id"]),
            )
            self._conn.commit()
            return True

    def metrics(self) -> dict[str, int | float]:
        """Return aggregate operational counts only; never include ticket bodies."""
        now = time.monotonic()
        with self._lock:
            rows = self._conn.execute("SELECT state, COUNT(*) AS count FROM runs GROUP BY state").fetchall()
            stale = self._conn.execute(
                "SELECT COUNT(*) AS count, MIN(lease_expires_at) AS oldest FROM runs "
                "WHERE state = 'running' AND lease_expires_at IS NOT NULL AND lease_expires_at <= ?",
                (now,),
            ).fetchone()
        counts = {state.value: 0 for state in RunState}
        counts.update({str(row["state"]): int(row["count"]) for row in rows})
        oldest = stale["oldest"] if stale and stale["oldest"] is not None else None
        return {
            **counts,
            "stale_running": 0 if oldest is None else int(stale["count"]),
            "oldest_stale_lease_seconds": 0.0 if oldest is None else max(0.0, now - float(oldest)),
        }

    def cancel_run(self, run_id: str) -> Run:
        """Cancel only a non-executing pending or blocked run."""
        run = self.get_run(run_id)
        if run.state not in {RunState.PENDING, RunState.BLOCKED}:
            raise ValueError("only pending or blocked runs can be cancelled")
        return self.transition(run_id, RunState.CANCELLED)

    def create_retry(self, run_id: str) -> Run:
        """Create a new pending run from an explicitly failed or cancelled run."""
        source = self.get_run(run_id)
        if source.state not in {RunState.FAILED, RunState.CANCELLED}:
            raise ValueError("only failed or cancelled runs can be retried")
        return self.start_run(
            Invocation(
                trigger_id=f"manual-retry:{source.run_id}:{uuid.uuid4()}",
                project_id=source.project_id,
                work_item_id=source.work_item_id,
                kind=InvocationKind.LABEL if source.label_triggered else InvocationKind.COMMENT,
                source=InvocationSource.LABEL if source.label_triggered else InvocationSource.COMMENT,
                operation=source.operation,
                body=source.body,
                model_selector=source.model_selector,
                label_triggered=source.label_triggered,
            )
        )

    def pending_manual_retries(self) -> list[Run]:
        with self._lock:
            rows = self._conn.execute(
                """
                SELECT run_id, trigger_id, project_id, work_item_id, operation, body,
                       model_selector, label_triggered, state, lease_expires_at,
                       start_comment_id, final_comment_id, worker_session_id, retry_count,
                       created_at, updated_at
                FROM runs
                WHERE state = 'pending' AND trigger_id LIKE 'manual-retry:%'
                ORDER BY created_at
                """
            ).fetchall()
        return [self._row_to_run(row) for row in rows]

    def close(self) -> None:
        with self._lock:
            self._conn.close()

    def _row_to_run(self, row: sqlite3.Row) -> Run:
        return Run(
            run_id=row["run_id"],
            trigger_id=row["trigger_id"],
            project_id=row["project_id"],
            work_item_id=row["work_item_id"],
            operation=InvocationOperation(row["operation"]),
            body=row["body"],
            model_selector=row["model_selector"],
            label_triggered=bool(row["label_triggered"]),
            state=RunState(row["state"]),
            lease_expires_at=row["lease_expires_at"],
            start_comment_id=row["start_comment_id"],
            final_comment_id=row["final_comment_id"],
            worker_session_id=row["worker_session_id"],
            retry_count=row["retry_count"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
        )
