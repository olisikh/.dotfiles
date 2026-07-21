#!/usr/bin/env python3
"""Tests for opt-in live Plane E2E smoke-test orchestration primitives."""
from __future__ import annotations

import sqlite3
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_smoke import SmokeConfiguration, SmokeError, SmokeWaiter


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


if __name__ == "__main__":
    for name in sorted(dir()):
        if name.startswith("test_"):
            globals()[name]()
            print(f"OK {name}")
    print("all_plane_smoke_tests_passed")
