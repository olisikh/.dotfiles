"""Tests for the consumer that drives the controller from queued deliveries.
"""
from __future__ import annotations

import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from hermes_consumer import consume
from plane_client import PlaneClient
from plane_controller import PlaneAutomationController
from plane_dispatcher import DeliveryQueue
from plane_invocation import InvocationOperation
from plane_runs import RunLedger


class FakePlaneHandler(BaseHTTPRequestHandler):
    def __init__(self, state: dict[str, Any], *args, **kwargs) -> None:
        self.state = state
        super().__init__(*args, **kwargs)

    def log_message(self, format: str, *args: Any) -> None:
        return

    def do_GET(self) -> None:  # noqa: N802
        if "/issues/" in self.path and "/comments" not in self.path:
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(self.state["issue"]).encode())
        elif "/comments/" in self.path:
            if self.state.get("comment_missing"):
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(self.state["comment"]).encode())
        else:
            self.send_error(404)

    def do_POST(self) -> None:  # noqa: N802
        if "/comments/" in self.path:
            length = int(self.headers.get("Content-Length", "0"))
            body = json.loads(self.rfile.read(length))
            body["id"] = f"new-comment-{len(self.state['comments']) + 1}"
            self.state["comments"].append(body)
            self.send_response(201)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(body).encode())
        else:
            self.send_error(404)


def _make_server(state: dict[str, Any]) -> HTTPServer:
    def handler(*args, **kwargs) -> FakePlaneHandler:
        return FakePlaneHandler(state, *args, **kwargs)

    server = HTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def _client(server: HTTPServer) -> PlaneClient:
    return PlaneClient(
        base_url=f"http://127.0.0.1:{server.server_port}",
        workspace_slug="ws",
        api_key="token",
    )


class _FakeWorker:
    def __init__(self, run: Any) -> None:
        pass

    def invoke(self, run: Any, context: dict[str, Any]) -> Any:
        from hermes_worker import WorkerResult

        return WorkerResult(
            status="success",
            final_comment_markdown=f"Answer for: {run.body}",
            summary="answered",
            artifacts=[],
        )


def _setup(
    server_state: dict[str, Any],
    hermes_user_id: str | None = None,
) -> tuple[DeliveryQueue, RunLedger, PlaneAutomationController, HTTPServer]:
    server = _make_server(server_state)
    client = _client(server)
    queue = DeliveryQueue(":memory:")
    ledger = RunLedger(":memory:")
    controller = PlaneAutomationController(
        plane_client=client,
        worker_factory=lambda run: _FakeWorker(run),
        hermes_user_id=hermes_user_id,
    )
    return queue, ledger, controller, server


def test_consumes_comment_ask_delivery_to_terminal() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": "<p>Context</p>"},
        "comment": {
            "id": "comment-1",
            "comment_html": "<p>@Hermes Explain this ticket</p>",
            "actor": "user-1",
        },
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue_comment", "comment-1")

        finished = consume(queue, ledger, controller, worker_session_id="session-a")

        assert finished == 1
        assert len(state["comments"]) == 1
        assert "Answer for: Explain this ticket" in state["comments"][0]["comment_html"]
        assert queue.claim_pending() == []
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


def test_finishes_delivery_when_source_comment_was_deleted() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {},
        "comment_missing": True,
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue_comment", "deleted-comment")

        assert consume(queue, ledger, controller, worker_session_id="session-a") == 1
        assert queue.pending() == []
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


def test_skips_non_hermes_comment_delivery() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {
            "id": "comment-1",
            "comment_html": "<p>Thanks for the update</p>",
            "actor": "user-1",
        },
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue_comment", "comment-1")

        finished = consume(queue, ledger, controller, worker_session_id="session-a")

        assert finished == 1
        assert state["comments"] == []
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


def test_posts_help_for_malformed_hermes_comment() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {
            "id": "comment-1",
            "comment_html": "<p>@Hermes --unknown-flag hi</p>",
            "actor": "user-1",
        },
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue_comment", "comment-1")

        finished = consume(queue, ledger, controller, worker_session_id="session-a")

        assert finished == 1
        assert len(state["comments"]) == 1
        assert "Unknown flag" in state["comments"][0]["comment_html"]
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


def test_consumes_label_triage_delivery() -> None:
    state: dict[str, Any] = {
        "issue": {
            "id": "item-1",
            "name": "Refactor",
            "description_html": "<p>Migrate</p>",
            "labels": [{"name": "hermes:triage"}],
        },
        "comment": {"id": "comment-1", "comment_html": "", "actor": "user-1"},
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue", "")

        finished = consume(queue, ledger, controller, worker_session_id="session-a")

        assert finished == 1
        assert len(state["comments"]) == 1
        run = ledger.get_run_by_trigger_id("delivery-1")
        assert run.operation == InvocationOperation.TRIAGE
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


def test_does_not_finish_when_another_session_holds_lease() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {
            "id": "comment-1",
            "comment_html": "<p>@Hermes Explain this ticket</p>",
            "actor": "user-1",
        },
        "comments": [],
    }
    queue, ledger, controller, server = _setup(state)
    try:
        queue.enqueue("delivery-1", "project-1", "item-1", "", "issue_comment", "comment-1")
        # Seed a run and lease it to another session.
        from plane_invocation import Invocation, InvocationKind, InvocationSource

        run = ledger.start_run(
            Invocation(
                trigger_id="delivery-1",
                project_id="project-1",
                work_item_id="item-1",
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.ASK,
                body="Explain this ticket",
            )
        )
        assert ledger.try_take_lease(run.run_id, "session-b", lease_seconds=60.0)

        finished = consume(queue, ledger, controller, worker_session_id="session-a")

        assert finished == 0
        assert state["comments"] == []
        # Delivery is returned to pending so the periodic consumer can retry it
        # once the other session's durable lease expires.
        assert queue.pending() == [
            ("delivery-1", "project-1", "item-1", "", "issue_comment", "comment-1")
        ]
    finally:
        server.shutdown()
        server.server_close()
        queue.close()
        ledger.close()


if __name__ == "__main__":
    import signal

    def _timeout(_sig, _frame) -> None:
        raise SystemExit("consumer_controller_tests_timeout")

    signal.signal(signal.SIGALRM, _timeout)
    signal.alarm(30)
    for name in sorted(dir()):
        if name.startswith("test_"):
            fn = globals()[name]
            fn()
            print(f"OK {name}")
    print("all_consumer_controller_tests_passed")
