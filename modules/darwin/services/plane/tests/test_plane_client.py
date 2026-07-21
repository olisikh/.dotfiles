"""Tests for the lightweight Plane REST client used by the automation controller.
"""
from __future__ import annotations

import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_client import PlaneClient


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
            body["id"] = "new-comment-1"
            self.state["comments"].append(body)
            self.send_response(201)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(body).encode())
        else:
            self.send_error(404)

    def do_DELETE(self) -> None:  # noqa: N802
        if "/comments/" in self.path:
            parts = [p for p in self.path.split("/") if p]
            comment_id = parts[-1]
            self.state["deleted"].append(comment_id)
            self.send_response(204)
            self.end_headers()
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


def test_get_work_item_returns_issue_details() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "issue-1", "name": "Test issue", "description_html": "<p>Details</p>"},
        "comments": [],
        "deleted": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        issue = client.get_work_item("project-1", "issue-1")
        assert issue["id"] == "issue-1"
        assert issue["name"] == "Test issue"
    finally:
        server.shutdown()
        server.server_close()


def test_create_comment_posts_html_and_returns_id() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "issue-1", "name": "Test issue", "description_html": ""},
        "comments": [],
        "deleted": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        result = client.create_comment("project-1", "issue-1", "<p>Hello</p>")
        assert result["id"] == "new-comment-1"
        assert state["comments"][0]["comment_html"] == "<p>Hello</p>"
    finally:
        server.shutdown()
        server.server_close()


def test_get_comment_fetches_comment_details() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "issue-1", "name": "Test issue", "description_html": ""},
        "comment": {"id": "comment-1", "comment_html": "<p>Original</p>", "actor": "user-1"},
        "comments": [],
        "deleted": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        comment = client.get_comment("project-1", "comment-1")
        assert comment["id"] == "comment-1"
    finally:
        server.shutdown()
        server.server_close()


def test_delete_comment_records_removal() -> None:
    state: dict[str, Any] = {
        "issue": {"id": "issue-1", "name": "Test issue", "description_html": ""},
        "comments": [],
        "deleted": [],
    }
    server = _make_server(state)
    try:
        client = _client(server)
        client.delete_comment("project-1", "issue-1", "comment-1")
        assert state["deleted"] == ["comment-1"]
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    import signal

    def _timeout(_sig, _frame) -> None:
        raise SystemExit("plane_client_tests_timeout")

    signal.signal(signal.SIGALRM, _timeout)
    signal.alarm(30)
    for name in sorted(dir()):
        if name.startswith("test_"):
            fn = globals()[name]
            fn()
            print(f"OK {name}")
    print("all_plane_client_tests_passed")
