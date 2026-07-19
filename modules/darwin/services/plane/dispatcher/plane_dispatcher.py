"""Narrow, local-only bridge for signed Plane webhooks.

The HTTP server and queueing code will only dispatch a delivery after it has
been authenticated.  Keeping the signature primitive side-effect-free makes it
simple to verify and hard to accidentally bypass.
"""
from __future__ import annotations

import hashlib
import hmac
import sqlite3
import threading
from http.server import BaseHTTPRequestHandler
from typing import Any


class DeliveryQueue:
    """Small durable idempotency queue keyed by Plane's delivery UUID."""

    def __init__(self, database_path: str) -> None:
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(database_path, check_same_thread=False)
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS deliveries (
              delivery_id TEXT PRIMARY KEY,
              project_id TEXT NOT NULL,
              work_item_id TEXT NOT NULL,
              identifier TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending'
            )
            """
        )
        self._conn.commit()

    def enqueue(
        self, delivery_id: str, project_id: str, work_item_id: str, identifier: str
    ) -> bool:
        with self._lock:
            cursor = self._conn.execute(
                """
                INSERT INTO deliveries (delivery_id, project_id, work_item_id, identifier)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(delivery_id) DO NOTHING
                """,
                (delivery_id, project_id, work_item_id, identifier),
            )
            self._conn.commit()
            return cursor.rowcount == 1

    def pending(self) -> list[tuple[str, str, str, str]]:
        with self._lock:
            return list(
                self._conn.execute(
                    """
                    SELECT delivery_id, project_id, work_item_id, identifier
                    FROM deliveries WHERE status = 'pending' ORDER BY rowid
                    """
                )
            )

    def claim_pending(self) -> list[tuple[str, str, str, str]]:
        """Atomically claim every pending delivery for one consumer pass."""
        with self._lock:
            deliveries = list(
                self._conn.execute(
                    """
                    SELECT delivery_id, project_id, work_item_id, identifier
                    FROM deliveries WHERE status = 'pending' ORDER BY rowid
                    """
                )
            )
            if deliveries:
                self._conn.executemany(
                    "UPDATE deliveries SET status = 'processing' WHERE delivery_id = ?",
                    [(delivery_id,) for delivery_id, *_ in deliveries],
                )
                self._conn.commit()
            return deliveries

    def finish(self, delivery_id: str) -> None:
        """Record a successfully handed-off delivery; it must not replay."""
        with self._lock:
            self._conn.execute(
                "UPDATE deliveries SET status = 'dispatched' WHERE delivery_id = ?",
                (delivery_id,),
            )
            self._conn.commit()

    def close(self) -> None:
        with self._lock:
            self._conn.close()


def make_dispatch_handler(queue: DeliveryQueue, secret: str) -> type[BaseHTTPRequestHandler]:
    """Create the only HTTP surface: POST /plane, capped at one MiB."""

    class PlaneDispatchHandler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:  # noqa: N802 - standard-library callback name
            if self.path != "/plane":
                self.send_error(404)
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                self.send_error(400)
                return
            if not 0 < length <= 1024 * 1024:
                self.send_error(413)
                return
            body = self.rfile.read(length)
            accepted = ingest_plane_delivery(queue, secret, dict(self.headers.items()), body)
            self.send_response(202 if accepted else 401)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def log_message(self, format: str, *args: object) -> None:
            # Launchd captures process output; do not log webhook bodies or headers.
            return

    return PlaneDispatchHandler


def ingest_plane_delivery(
    queue: DeliveryQueue, secret: str, headers: dict[str, str], body: bytes
) -> bool:
    """Authenticate and enqueue one Plane issue event without trusting its state."""
    normalized_headers = {key.lower(): value for key, value in headers.items()}
    delivery_id = normalized_headers.get("x-plane-delivery", "")
    signature = normalized_headers.get("x-plane-signature", "")
    if not delivery_id or not signature or not verify_plane_signature(secret, body, signature):
        return False
    try:
        import json

        payload = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return False
    if not isinstance(payload, dict):
        return False
    ref = extract_work_item_ref(payload)
    if ref is None:
        return False
    project_id, work_item_id, identifier = ref
    return queue.enqueue(delivery_id, project_id, work_item_id, identifier)


def verify_plane_signature(secret: str, body: bytes, signature: str) -> bool:
    """Return whether ``signature`` is Plane's HMAC-SHA256 of ``body``."""
    expected = hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature.strip())


def extract_work_item_ref(payload: dict[str, Any]) -> tuple[str, str, str] | None:
    """Return stable project/work-item references from a Plane issue event.

    The dispatcher intentionally ignores every other event class.  It needs the
    UUID pair to re-fetch current state rather than trusting the event body.
    """
    if payload.get("event") != "issue":
        return None
    data = payload.get("data")
    if not isinstance(data, dict):
        return None
    work_item_id = data.get("id")
    project = data.get("project_id") or data.get("project")
    if isinstance(project, dict):
        project = project.get("id")
    if not isinstance(work_item_id, str) or not isinstance(project, str):
        return None
    identifier = data.get("identifier")
    return project, work_item_id, identifier if isinstance(identifier, str) else ""
