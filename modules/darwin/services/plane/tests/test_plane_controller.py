"""Tests for the Plane automation controller (ask/triage/parse-error paths).
"""
from __future__ import annotations

import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_client import PlaneClient
from plane_controller import HELP_MESSAGES, PlaneAutomationController
from plane_invocation import Invocation, InvocationError, InvocationKind, InvocationOperation, InvocationSource
from plane_runs import Run, RunLedger, RunState


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


def _make_run(operation: InvocationOperation = InvocationOperation.ASK, body: str = "Explain") -> Run:
    return Run(
        run_id="run-1",
        trigger_id="trigger-1",
        project_id="project-1",
        work_item_id="item-1",
        operation=operation,
        body=body,
        model_selector=None,
        label_triggered=False,
        state=RunState.PENDING,
        lease_expires_at=None,
        start_comment_id="",
        final_comment_id="",
        worker_session_id="",
        retry_count=0,
        created_at=0.0,
        updated_at=0.0,
    )


def _controller(client: PlaneClient) -> PlaneAutomationController:
    return PlaneAutomationController(
        plane_client=client,
        worker_factory=lambda run: _FakeWorker(run),
    )


class _FakeWorker:
    def __init__(self, run: Run) -> None:
        self.run = run

    def invoke(self, run: Run, context: dict[str, Any]) -> Any:
        from hermes_worker import WorkerResult

        return WorkerResult(
            status="success",
            final_comment_markdown=f"Answer for: {run.body}",
            summary="answered",
            artifacts=[],
        )


def test_posts_help_comment_for_parse_error() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {"id": "comment-1", "comment_html": "", "actor": "user-1"},
        "comments": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        ledger = RunLedger(":memory:")
        controller = _controller(client)
        invocation = Invocation(
            trigger_id="trigger-1",
            project_id="project-1",
            work_item_id="item-1",
            kind=InvocationKind.COMMENT,
            source=InvocationSource.COMMENT,
            operation=InvocationOperation.ASK,
            body="body",
        )
        run = ledger.start_run(invocation)

        result = controller.process_run(
            run,
            ledger,
            parse_error=InvocationError("empty_body"),
            actor_comment_id="comment-1",
        )

        assert result is True
        assert len(state["comments"]) == 1
        assert HELP_MESSAGES["empty_body"] in state["comments"][0]["comment_html"]
        assert ledger.get_run(run.run_id).state == RunState.COMPLETED
    finally:
        server.shutdown()
        server.server_close()
        ledger.close()


def test_routes_ask_through_worker_and_posts_comment() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": "<p>Context</p>"},
        "comment": {"id": "comment-1", "comment_html": "", "actor": "user-1"},
        "comments": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        ledger = RunLedger(":memory:")
        controller = _controller(client)
        run = ledger.start_run(
            Invocation(
                trigger_id="trigger-1",
                project_id="project-1",
                work_item_id="item-1",
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.ASK,
                body="Explain this",
            )
        )

        result = controller.process_run(run, ledger)

        assert result is True
        assert len(state["comments"]) == 1
        assert "Answer for: Explain this" in state["comments"][0]["comment_html"]
        updated = ledger.get_run(run.run_id)
        assert updated.state == RunState.COMPLETED
        assert updated.final_comment_id == "new-comment-1"
    finally:
        server.shutdown()
        server.server_close()
        ledger.close()


def test_routes_triage_through_worker_and_posts_comment() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Big refactor", "description_html": "<p>We need to migrate.</p>"},
        "comment": {"id": "comment-1", "comment_html": "", "actor": "user-1"},
        "comments": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        ledger = RunLedger(":memory:")
        controller = _controller(client)
        run = ledger.start_run(
            Invocation(
                trigger_id="trigger-1",
                project_id="project-1",
                work_item_id="item-1",
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.TRIAGE,
                body="Assess risks",
            )
        )

        result = controller.process_run(run, ledger)

        assert result is True
        assert len(state["comments"]) == 1
        assert "Answer for: Assess risks" in state["comments"][0]["comment_html"]
    finally:
        server.shutdown()
        server.server_close()
        ledger.close()


def test_marks_run_failed_and_posts_comment_on_worker_failure() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {"id": "comment-1", "comment_html": "", "actor": "user-1"},
        "comments": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        ledger = RunLedger(":memory:")

        class _FailingWorker:
            def invoke(self, run: Run, context: dict[str, Any]) -> Any:
                from hermes_worker import WorkerResult

                return WorkerResult(
                    status="failure",
                    final_comment_markdown="Worker failed internally.",
                    summary="internal failure",
                    artifacts=[],
                )

        controller = PlaneAutomationController(
            plane_client=client,
            worker_factory=lambda run: _FailingWorker(),
        )
        run = ledger.start_run(
            Invocation(
                trigger_id="trigger-1",
                project_id="project-1",
                work_item_id="item-1",
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.ASK,
                body="Explain",
            )
        )

        result = controller.process_run(run, ledger)

        assert result is True
        assert len(state["comments"]) == 1
        assert "Worker failed internally" in state["comments"][0]["comment_html"]
        assert ledger.get_run(run.run_id).state == RunState.FAILED
    finally:
        server.shutdown()
        server.server_close()
        ledger.close()


def test_rejects_hermes_self_authored_comment() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "item-1", "name": "Test issue", "description_html": ""},
        "comment": {"id": "comment-1", "comment_html": "<p>@Hermes go</p>", "actor": "hermes-user-id"},
        "comments": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        ledger = RunLedger(":memory:")
        controller = PlaneAutomationController(
            plane_client=client,
            worker_factory=lambda run: _FakeWorker(run),
            hermes_user_id="hermes-user-id",
        )
        run = ledger.start_run(
            Invocation(
                trigger_id="trigger-1",
                project_id="project-1",
                work_item_id="item-1",
                kind=InvocationKind.COMMENT,
                source=InvocationSource.COMMENT,
                operation=InvocationOperation.GO,
                body="Implement it",
            )
        )

        result = controller.process_run(run, ledger, actor_comment_id="comment-1")

        assert result is True
        assert ledger.get_run(run.run_id).state == RunState.CANCELLED
        assert len(state["comments"]) == 0
    finally:
        server.shutdown()
        server.server_close()
        ledger.close()


if __name__ == "__main__":
    import signal

    def _timeout(_sig, _frame) -> None:
        raise SystemExit("plane_controller_tests_timeout")

    signal.signal(signal.SIGALRM, _timeout)
    signal.alarm(30)
    for name in sorted(dir()):
        if name.startswith("test_"):
            fn = globals()[name]
            fn()
            print(f"OK {name}")
    print("all_plane_controller_tests_passed")
