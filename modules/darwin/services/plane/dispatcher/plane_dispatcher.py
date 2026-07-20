#!/usr/bin/env python3
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
import time
from http.server import BaseHTTPRequestHandler
from typing import Any


class CooldownMap:
    """In-memory reject-if-too-recent map keyed by work_item_id.

    This prevents two rapid Plane webhooks for the same ticket from spawning
    concurrent Hermes sessions. It is intentionally in-process: the dispatcher
    is a single process; duplicate delivery UUIDs are still blocked by the queue.
    """

    def __init__(self, cooldown_seconds: float) -> None:
        self._cooldown = cooldown_seconds
        self._lock = threading.Lock()
        self._last_seen: dict[str, float] = {}

    def is_allowed(self, work_item_id: str) -> bool:
        now = time.monotonic()
        with self._lock:
            last = self._last_seen.get(work_item_id, 0.0)
            if now - last < self._cooldown:
                return False
            self._last_seen[work_item_id] = now
            return True


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
              event_type TEXT NOT NULL DEFAULT 'issue',
              comment_id TEXT NOT NULL DEFAULT '',
              status TEXT NOT NULL DEFAULT 'pending'
            )
            """
        )
        existing_columns = {
            row[1] for row in self._conn.execute("PRAGMA table_info(deliveries)")
        }
        if "event_type" not in existing_columns:
            self._conn.execute(
                "ALTER TABLE deliveries ADD COLUMN event_type TEXT NOT NULL DEFAULT 'issue'"
            )
        if "comment_id" not in existing_columns:
            self._conn.execute(
                "ALTER TABLE deliveries ADD COLUMN comment_id TEXT NOT NULL DEFAULT ''"
            )
        self._conn.commit()

    def enqueue(
        self,
        delivery_id: str,
        project_id: str,
        work_item_id: str,
        identifier: str,
        event_type: str = "issue",
        comment_id: str = "",
    ) -> bool:
        with self._lock:
            cursor = self._conn.execute(
                """
                INSERT INTO deliveries
                  (delivery_id, project_id, work_item_id, identifier, event_type, comment_id)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(delivery_id) DO NOTHING
                """,
                (delivery_id, project_id, work_item_id, identifier, event_type, comment_id),
            )
            self._conn.commit()
            return cursor.rowcount == 1

    def pending(self) -> list[tuple[str, str, str, str, str, str]]:
        with self._lock:
            return list(
                self._conn.execute(
                    """
                    SELECT delivery_id, project_id, work_item_id, identifier, event_type, comment_id
                    FROM deliveries WHERE status = 'pending' ORDER BY rowid
                    """
                )
            )

    def claim_pending(self) -> list[tuple[str, str, str, str, str, str]]:
        """Atomically claim every pending delivery for one consumer pass."""
        with self._lock:
            deliveries = list(
                self._conn.execute(
                    """
                    SELECT delivery_id, project_id, work_item_id, identifier, event_type, comment_id
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


def make_dispatch_handler(
    queue: DeliveryQueue, cooldown: CooldownMap, secret: str
) -> type[BaseHTTPRequestHandler]:
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
            result = ingest_plane_delivery(
                queue, cooldown, secret, dict(self.headers.items()), body
            )
            if result == "accepted":
                self.send_response(202)
            elif result == "cooldown":
                self.send_response(429)
            else:
                self.send_response(401)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def log_message(self, format: str, *args: object) -> None:
            # Launchd captures process output; do not log webhook bodies or headers.
            return

    return PlaneDispatchHandler


def ingest_plane_delivery(
    queue: DeliveryQueue,
    cooldown: CooldownMap,
    secret: str,
    headers: dict[str, str],
    body: bytes,
) -> str:
    """Authenticate, cooldown, and enqueue one Plane issue event.

    Returns one of: 'accepted', 'cooldown', 'rejected'.
    """
    normalized_headers = {key.lower(): value for key, value in headers.items()}
    delivery_id = normalized_headers.get("x-plane-delivery", "")
    signature = normalized_headers.get("x-plane-signature", "")
    if not delivery_id or not signature or not verify_plane_signature(secret, body, signature):
        return "rejected"
    try:
        import json

        payload = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return "rejected"
    if not isinstance(payload, dict):
        return "rejected"
    ref = extract_work_item_ref(payload)
    if ref is None:
        return "rejected"
    project_id, work_item_id, identifier = ref
    event_type = payload["event"]
    data = payload["data"]
    comment_id = data.get("id", "") if event_type == "issue_comment" else ""
    if not cooldown.is_allowed(work_item_id):
        return "cooldown"
    return (
        "accepted"
        if queue.enqueue(
            delivery_id, project_id, work_item_id, identifier, event_type, comment_id
        )
        else "rejected"
    )


def verify_plane_signature(secret: str, body: bytes, signature: str) -> bool:
    """Return whether ``signature`` is Plane's HMAC-SHA256 of ``body``."""
    expected = hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature.strip())


def extract_work_item_ref(payload: dict[str, Any]) -> tuple[str, str, str] | None:
    """Return stable project/work-item references from a Plane issue event.

    The dispatcher intentionally ignores every other event class.  It needs the
    UUID pair to re-fetch current state rather than trusting the event body.
    """
    event = payload.get("event")
    if event not in {"issue", "issue_comment"}:
        return None
    data = payload.get("data", {})
    if not isinstance(data, dict):
        return None
    # Plane v1.3.1's IssueExpandSerializer uses `project`; older payloads and
    # some API paths use `project_id`. Accept both while treating the webhook
    # body only as a reference — Hermes re-fetches current state through MCP.
    project_id = data.get("project_id") or data.get("project") or ""
    if event == "issue":
        work_item_id = data.get("id") or ""
        identifier = data.get("identifier") or ""
    else:
        # IssueCommentSerializer exposes the parent work item as `issue`.
        work_item_id = data.get("issue_id") or data.get("issue") or ""
        identifier = ""
    if not project_id or not work_item_id:
        return None
    return project_id, work_item_id, identifier


if __name__ == "__main__":
    raise SystemExit("Use as a module from dispatcher/run.py")
