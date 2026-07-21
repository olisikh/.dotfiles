"""Safe primitives for the opt-in live Plane/Hermes smoke runner.

This module deliberately has no automatic entry point: a live run is initiated
only by `plane-automation smoke`. It reads a dedicated non-Hermes trigger token,
creates one disposable ticket, and relies on Plane's configured webhook delivery.
"""
from __future__ import annotations

import os
import sqlite3
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Mapping


class SmokeError(RuntimeError):
    """A failed prerequisite or assertion in an explicit live smoke run."""


class SmokeLock:
    """Exclusive, process-local guard against overlapping real Plane smoke runs."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._held = False

    def __enter__(self) -> "SmokeLock":
        self._path.parent.mkdir(parents=True, exist_ok=True)
        try:
            descriptor = os.open(self._path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError as exc:
            raise SmokeError("a live Plane smoke run is already running") from exc
        try:
            os.write(descriptor, f"pid={os.getpid()}\n".encode())
        finally:
            os.close(descriptor)
        self._held = True
        return self

    def __exit__(self, *_: object) -> None:
        if self._held:
            self._path.unlink(missing_ok=True)
            self._held = False


@dataclass(frozen=True, slots=True)
class SmokeConfiguration:
    state_dir: Path
    public_base: str
    workspace_slug: str
    project_id: str
    trigger_token: str = field(repr=False)

    @classmethod
    def from_environment(cls, environ: Mapping[str, str] | None = None) -> "SmokeConfiguration":
        env = os.environ if environ is None else environ
        required = ("PLANE_STATE_DIR", "PLANE_PUBLIC_BASE", "PLANE_WORKSPACE_SLUG", "PLANE_E2E_PROJECT_ID")
        missing = [name for name in required if not env.get(name, "").strip()]
        if missing:
            raise SmokeError(f"live smoke configuration missing: {', '.join(missing)}")
        token_path = Path(env.get("PLANE_E2E_TRIGGER_TOKEN_FILE", ""))
        try:
            token = token_path.read_text().strip()
        except OSError as exc:
            raise SmokeError("live smoke trigger token file is unavailable") from exc
        if not token:
            raise SmokeError("live smoke trigger token is empty")
        return cls(
            state_dir=Path(env["PLANE_STATE_DIR"]),
            public_base=env["PLANE_PUBLIC_BASE"].rstrip("/"),
            workspace_slug=env["PLANE_WORKSPACE_SLUG"],
            project_id=env["PLANE_E2E_PROJECT_ID"],
            trigger_token=token,
        )


class SmokeWaiter:
    """Read-only correlation of actual Plane deliveries in the local queue."""

    def __init__(self, queue_database: str, *, timeout_seconds: float, poll_seconds: float = 1.0) -> None:
        self._database = queue_database
        self._timeout = timeout_seconds
        self._poll = poll_seconds

    def comment_delivery(self, project_id: str, work_item_id: str, comment_id: str) -> str:
        return self._wait_one(
            "SELECT delivery_id FROM deliveries WHERE project_id = ? AND work_item_id = ? "
            "AND event_type = 'issue_comment' AND comment_id = ? ORDER BY rowid DESC LIMIT 1",
            (project_id, work_item_id, comment_id),
            "comment webhook delivery",
        )

    def label_cursor(self, project_id: str, work_item_id: str) -> int:
        with sqlite3.connect(self._database) as conn:
            row = conn.execute(
                "SELECT COALESCE(MAX(rowid), 0) FROM deliveries WHERE project_id = ? AND work_item_id = ?",
                (project_id, work_item_id),
            ).fetchone()
        return int(row[0]) if row else 0

    def label_delivery(self, project_id: str, work_item_id: str, *, after_rowid: int) -> str:
        return self._wait_one(
            "SELECT delivery_id FROM deliveries WHERE project_id = ? AND work_item_id = ? "
            "AND event_type = 'issue' AND rowid > ? ORDER BY rowid ASC LIMIT 1",
            (project_id, work_item_id, after_rowid),
            "label webhook delivery",
        )

    def _wait_one(self, query: str, parameters: tuple[object, ...], label: str) -> str:
        deadline = time.monotonic() + self._timeout
        while time.monotonic() < deadline:
            try:
                with sqlite3.connect(self._database) as conn:
                    row = conn.execute(query, parameters).fetchone()
            except sqlite3.Error:
                row = None
            if row and row[0]:
                return str(row[0])
            time.sleep(self._poll)
        raise SmokeError(f"timed out waiting for {label}")


class PlaneE2EClient:
    """Minimal REST surface used only by the explicit smoke command."""

    def __init__(self, config: SmokeConfiguration) -> None:
        self._config = config

    def _request(self, method: str, path: str, payload: dict[str, object] | None = None) -> object:
        import json
        import urllib.error
        from urllib.request import Request, urlopen

        data = json.dumps(payload, separators=(",", ":")).encode() if payload is not None else None
        request = Request(
            f"{self._config.public_base}/api/v1/workspaces/{self._config.workspace_slug}{path}",
            data=data,
            headers={"X-Api-Key": self._config.trigger_token, "Content-Type": "application/json"},
            method=method,
        )
        try:
            with urlopen(request, timeout=30) as response:
                return {} if response.status == 204 else json.loads(response.read().decode())
        except urllib.error.HTTPError as exc:
            raise SmokeError(f"Plane E2E API {method} {path} failed ({exc.code})") from exc

    def create_ticket(self, name: str, description: str) -> dict[str, object]:
        result = self._request("POST", f"/projects/{self._config.project_id}/issues/", {"name": name, "description_stripped": description})
        if not isinstance(result, dict) or not result.get("id"):
            raise SmokeError("Plane did not return a created E2E ticket")
        return result

    def create_comment(self, work_item_id: str, html: str) -> dict[str, object]:
        result = self._request("POST", f"/projects/{self._config.project_id}/issues/{work_item_id}/comments/", {"comment_html": html, "access": "INTERNAL"})
        if not isinstance(result, dict) or not result.get("id"):
            raise SmokeError("Plane did not return an E2E source comment")
        return result

    def get_comment(self, work_item_id: str, comment_id: str) -> dict[str, object]:
        result = self._request("GET", f"/projects/{self._config.project_id}/issues/{work_item_id}/comments/{comment_id}/")
        return result if isinstance(result, dict) else {}

    def labels(self) -> list[dict[str, object]]:
        result = self._request("GET", f"/projects/{self._config.project_id}/labels/")
        rows = result.get("results", result) if isinstance(result, dict) else result
        return [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []

    def ensure_label(self, name: str) -> str:
        for label in self.labels():
            if str(label.get("name", "")).casefold() == name.casefold() and label.get("id"):
                return str(label["id"])
        result = self._request("POST", f"/projects/{self._config.project_id}/labels/", {"name": name, "color": "#6B7280"})
        if not isinstance(result, dict) or not result.get("id"):
            raise SmokeError(f"Plane did not create label {name}")
        return str(result["id"])

    def set_labels(self, work_item_id: str, label_ids: list[str]) -> None:
        self._request("PATCH", f"/projects/{self._config.project_id}/issues/{work_item_id}/", {"labels": label_ids})

    def close_ticket(self, work_item_id: str) -> None:
        result = self._request("GET", f"/projects/{self._config.project_id}/states/")
        rows = result.get("results", result) if isinstance(result, dict) else result
        state = next((row for row in rows if isinstance(row, dict) and row.get("group") == "completed"), None) if isinstance(rows, list) else None
        if not isinstance(state, dict) or not state.get("id"):
            raise SmokeError("TEST project has no completed state")
        self._request("PATCH", f"/projects/{self._config.project_id}/issues/{work_item_id}/", {"state": str(state["id"])})


class LiveSmokeRunner:
    """Execute positive live cases and close the disposable ticket even on failure."""

    _ISSUE_EVENT_SETTLE_SECONDS = 12.0

    def __init__(self, config: SmokeConfiguration, *, timeout_seconds: float = 300.0) -> None:
        self._config = config
        self._api = PlaneE2EClient(config)
        self._waiter = SmokeWaiter(str(config.state_dir / "dispatcher.sqlite3"), timeout_seconds=timeout_seconds)
        self._timeout = timeout_seconds

    def run(self) -> dict[str, object]:
        with SmokeLock(self._config.state_dir / "live-smoke.lock"):
            return self._run_unlocked()

    def _run_unlocked(self) -> dict[str, object]:
        marker = f"PLANE_E2E_{int(time.time())}"
        ticket = self._api.create_ticket(
            f"Hermes E2E smoke {marker}",
            f"Disposable automated regression ticket. Never modify files, services, or integrations. Return the requested marker only: {marker}.",
        )
        work_item_id = str(ticket["id"])
        cases: list[dict[str, object]] = []
        cleanup_error = ""
        try:
            cases.append(self._comment_case(work_item_id, f"@Hermes --model luna --variant low Reply exactly: {marker}_ASK", f"{marker}_ASK"))
            cases.append(self._comment_case(work_item_id, f"@Hermes --model luna /triage Reply exactly: {marker}_TRIAGE", f"{marker}_TRIAGE"))
            cases.append(self._comment_case(work_item_id, f"@Hermes --model luna --variant low /go E2E only: do not modify files, services, or Plane. Reply exactly: {marker}_GO", f"{marker}_GO"))
            self._settle_issue_event()
            cases.append(self._label_case(work_item_id, "hermes:triage"))
            self._settle_issue_event()
            cases.append(self._label_case(work_item_id, "hermes:go"))
        finally:
            try:
                self._api.set_labels(work_item_id, [])
                self._api.close_ticket(work_item_id)
            except Exception as exc:  # noqa: BLE001
                cleanup_error = str(exc)
        if cleanup_error:
            raise SmokeError(f"smoke ticket cleanup failed: {cleanup_error}")
        return {"ticket_id": work_item_id, "ticket_identifier": ticket.get("identifier", ""), "cases": cases, "closed": True}

    def _settle_issue_event(self) -> None:
        """Avoid the dispatcher's bounded issue-event cooldown between label cases."""
        time.sleep(self._ISSUE_EVENT_SETTLE_SECONDS)

    def _comment_case(self, work_item_id: str, body: str, marker: str) -> dict[str, object]:
        comment = self._api.create_comment(work_item_id, body)
        run = self._wait_for_run(self._waiter.comment_delivery(self._config.project_id, work_item_id, str(comment["id"])))
        final = self._api.get_comment(work_item_id, run.final_comment_id)
        if marker not in str(final.get("comment_html", "")):
            raise SmokeError(f"Hermes result omitted expected marker for {marker}")
        return {"kind": "comment", "marker": marker, "run_id": run.run_id, "state": run.state.value}

    def _label_case(self, work_item_id: str, label_name: str) -> dict[str, object]:
        label_id = self._api.ensure_label(label_name)
        cursor = self._waiter.label_cursor(self._config.project_id, work_item_id)
        self._api.set_labels(work_item_id, [label_id])
        run = self._wait_for_run(self._waiter.label_delivery(self._config.project_id, work_item_id, after_rowid=cursor))
        self._api.set_labels(work_item_id, [])
        if not run.final_comment_id:
            raise SmokeError(f"{label_name} completed without a durable result")
        return {"kind": "label", "label": label_name, "run_id": run.run_id, "state": run.state.value}

    def _wait_for_run(self, delivery_id: str):
        from plane_runs import RunLedger, RunState

        deadline = time.monotonic() + self._timeout
        ledger = RunLedger(str(self._config.state_dir / "runs.sqlite3"))
        try:
            while time.monotonic() < deadline:
                run = ledger.maybe_get_run_by_trigger_id(delivery_id)
                if run is not None and run.state in {RunState.COMPLETED, RunState.FAILED, RunState.CANCELLED}:
                    if run.state != RunState.COMPLETED:
                        raise SmokeError(f"Hermes run {run.run_id} ended {run.state.value}")
                    return run
                time.sleep(1)
        finally:
            ledger.close()
        raise SmokeError("timed out waiting for terminal Hermes run")
