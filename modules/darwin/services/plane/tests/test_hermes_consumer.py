import hashlib
import hmac
import json
import sqlite3
import sys
import threading
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

import hermes_consumer
import plane_dispatcher

DB_PATH = ":memory:"
PLANE_SECRET = "plane-ingress-test-secret"
HERMES_SECRET = "hermes-webhook-test-secret"


def test_consumer_signs_with_timestamp() -> None:
    body = b'{"a":1}'
    timestamp = "1234567890"
    sig = hermes_consumer.sign(HERMES_SECRET, body, timestamp)
    expected = hmac.new(
        HERMES_SECRET.encode(),
        (timestamp + "." + body.decode()).encode(),
        hashlib.sha256,
    ).hexdigest()
    assert sig == expected


def test_deliver_marks_2xx_successful() -> None:
    import http.server
    import threading

    received: list[dict[str, Any]] = []

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(length)
            received.append({"headers": dict(self.headers), "body": json.loads(body), "raw_body": body})
            self.send_response(204)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def log_message(self, *args: object) -> None:
            return

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        original_url = hermes_consumer.HERMES_WEBHOOK_URL
        hermes_consumer.HERMES_WEBHOOK_URL = f"http://127.0.0.1:{port}/webhooks/plane-work-item"
        assert hermes_consumer.deliver(
            HERMES_SECRET, ("d-1", "p-1", "w-1", "#1", "issue_comment", "comment-1")
        )
        assert len(received) == 1
        req = received[0]
        assert req["body"]["delivery_id"] == "d-1"
        assert req["body"]["project_id"] == "p-1"
        assert req["body"]["event_type"] == "issue_comment"
        assert req["body"]["comment_id"] == "comment-1"
        assert "X-Webhook-Timestamp" in req["headers"]
        assert "X-Webhook-Signature-V2" in req["headers"]
        assert hmac.compare_digest(
            req["headers"]["X-Webhook-Signature-V2"],
            hmac.new(
                HERMES_SECRET.encode(),
                req["headers"]["X-Webhook-Timestamp"].encode("utf-8") + b"." + req["raw_body"],
                hashlib.sha256,
            ).hexdigest(),
        )
    finally:
        hermes_consumer.HERMES_WEBHOOK_URL = original_url
        server.shutdown()


class FakeDeliver:
    calls: list[tuple[str, str, str, str, str, str]] = []

    @classmethod
    def deliver(cls, secret: str, delivery: tuple[str, str, str, str, str, str]) -> bool:
        assert secret == HERMES_SECRET
        cls.calls.append(delivery)
        return True


def test_consume_dispatches_only_claimed() -> None:
    queue = plane_dispatcher.DeliveryQueue(":memory:")
    queue.enqueue("d-1", "p-1", "w-1", "#1")
    queue.enqueue("d-2", "p-1", "w-2", "#2")
    FakeDeliver.calls.clear()

    try:
        real = hermes_consumer.deliver
        hermes_consumer.deliver = FakeDeliver.deliver
        count = hermes_consumer.consume(queue, HERMES_SECRET)
    finally:
        hermes_consumer.deliver = real
    assert count == 2
    assert sorted(d[0] for d in FakeDeliver.calls) == ["d-1", "d-2"]
    assert queue.pending() == []


def test_consume_forwards_comment_metadata_to_hermes() -> None:
    queue = plane_dispatcher.DeliveryQueue(":memory:")
    queue.enqueue("d-comment", "p-1", "w-1", "", "issue_comment", "comment-1")
    FakeDeliver.calls.clear()

    try:
        real = hermes_consumer.deliver
        hermes_consumer.deliver = FakeDeliver.deliver
        count = hermes_consumer.consume(queue, HERMES_SECRET)
    finally:
        hermes_consumer.deliver = real

    assert count == 1
    assert FakeDeliver.calls == [("d-comment", "p-1", "w-1", "", "issue_comment", "comment-1")]
    assert queue.pending() == []


def test_consume_skips_failed_without_finishing() -> None:
    queue = plane_dispatcher.DeliveryQueue(":memory:")
    queue.enqueue("d-1", "p-1", "w-1", "#1")
    call_count = 0

    def flaky(secret: str, delivery: tuple[str, str, str, str]) -> bool:
        nonlocal call_count
        call_count += 1
        return False

    try:
        real = hermes_consumer.deliver
        hermes_consumer.deliver = flaky
        count = hermes_consumer.consume(queue, HERMES_SECRET)
    finally:
        hermes_consumer.deliver = real
    assert count == 0
    assert call_count == 1
    # Delivery stays in processing status for a later retry.
    with queue._lock:
        processing = list(queue._conn.execute("SELECT status FROM deliveries"))
    assert processing == [("processing",)]


if __name__ == "__main__":
    import sys

    import __main__

    for name in dir(__main__):
        if name.startswith("test_"):
            fn = getattr(__main__, name)
            fn()
            print(f"OK {name}")
    print("all_consumer_tests_passed")
    sys.exit(0)
