#!/usr/bin/env python3
"""Tests for opt-in live Plane E2E smoke-test orchestration primitives."""
from __future__ import annotations

import contextlib
import io
import sqlite3
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_smoke import LiveSmokeRunner, SmokeConfiguration, SmokeError, SmokeLock, SmokeWaiter
from plane_automation import main as plane_automation_main


def test_configuration_requires_explicit_live_prerequisites() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        tmp_path = Path(temporary)
        env = {
            "PLANE_STATE_DIR": str(tmp_path),
            "PLANE_PUBLIC_BASE": "https://plane.example.test",
            "PLANE_WORKSPACE_SLUG": "workspace",
            "PLANE_E2E_PROJECT_ID": "project-1",
            "PLANE_E2E_TRIGGER_TOKEN_FILE": str(tmp_path / "missing"),
        }
        try:
            SmokeConfiguration.from_environment(env)
        except SmokeError as exc:
            assert "token" in str(exc).lower()
        else:
            raise AssertionError("missing trigger token must refuse a live run")


def test_configuration_reads_token_without_exposing_it_in_repr() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        tmp_path = Path(temporary)
        token_file = tmp_path / "token"
        token_file.write_text("e2e-secret-token\n")
        config = SmokeConfiguration.from_environment(
            {
                "PLANE_STATE_DIR": str(tmp_path),
                "PLANE_PUBLIC_BASE": "https://plane.example.test",
                "PLANE_WORKSPACE_SLUG": "workspace",
                "PLANE_E2E_PROJECT_ID": "project-1",
                "PLANE_E2E_TRIGGER_TOKEN_FILE": str(token_file),
            }
        )
        assert config.trigger_token == "e2e-secret-token"
        assert "e2e-secret-token" not in repr(config)


def test_create_ticket_can_include_initial_label_trigger() -> None:
    client = object.__new__(__import__("plane_smoke").PlaneE2EClient)
    client._config = type("Config", (), {"project_id": "project"})()
    client._request = MagicMock(return_value={"id": "ticket"})

    assert client.create_ticket("ticket", "description", label_ids=["label"]) == {"id": "ticket"}
    client._request.assert_called_once_with("POST", "/projects/project/issues/", {"name": "ticket", "description_stripped": "description", "labels": ["label"]})


def test_waiter_correlates_comment_and_label_deliveries() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        tmp_path = Path(temporary)
        queue_db = tmp_path / "dispatcher.sqlite3"
        conn = sqlite3.connect(queue_db)
        conn.execute(
            "CREATE TABLE deliveries (delivery_id TEXT PRIMARY KEY, project_id TEXT, work_item_id TEXT, identifier TEXT, event_type TEXT, comment_id TEXT, status TEXT)"
        )
        conn.execute(
            "INSERT INTO deliveries VALUES ('comment-delivery', 'project', 'item', 'TEST-1', 'issue_comment', 'comment-1', 'dispatched')"
        )
        conn.execute(
            "INSERT INTO deliveries VALUES ('label-delivery', 'project', 'item', 'TEST-1', 'issue', '', 'dispatched')"
        )
        conn.commit()
        conn.close()

        waiter = SmokeWaiter(str(queue_db), timeout_seconds=0.01, poll_seconds=0.001)
        assert waiter.comment_delivery("project", "item", "comment-1") == "comment-delivery"
        assert waiter.label_cursor("project", "item") == 2
        assert waiter.label_delivery("project", "item", after_rowid=1) == "label-delivery"
        waiter.ticket_idle("project", "item")


def test_smoke_runner_waits_out_issue_event_cooldown_before_label_trigger() -> None:
    runner = object.__new__(LiveSmokeRunner)
    runner._config = type("Config", (), {"project_id": "project"})()
    runner._waiter = MagicMock()
    with patch("plane_smoke.time.sleep") as sleep:
        runner._settle_issue_event("item")
    sleep.assert_called_once_with(12.0)
    runner._waiter.ticket_idle.assert_called_once_with("project", "item")


def test_smoke_lock_rejects_concurrent_live_run_and_cleans_up() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        lock_path = Path(temporary) / "live-smoke.lock"
        with SmokeLock(lock_path):
            assert lock_path.exists()
            try:
                with SmokeLock(lock_path):
                    raise AssertionError("second lock unexpectedly acquired")
            except SmokeError as exc:
                assert "already running" in str(exc)
        assert not lock_path.exists()


def test_smoke_command_requires_explicit_live_acknowledgement() -> None:
    stdout = io.StringIO()
    with patch.object(sys, "argv", ["plane-automation", "smoke"]), contextlib.redirect_stdout(stdout):
        assert plane_automation_main() == 1
    assert "--live" in stdout.getvalue()


if __name__ == "__main__":
    for name in sorted(dir()):
        if name.startswith("test_"):
            globals()[name]()
            print(f"OK {name}")
    print("all_plane_smoke_tests_passed")
