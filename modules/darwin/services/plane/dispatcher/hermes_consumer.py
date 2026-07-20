#!/usr/bin/env python3
"""Deliver queued Plane work-item webhooks to the Hermes loopback webhook.

This consumer intentionally does not contain credentials or re-fetch Plane state.
It only signs and hands off a minimal, durable work-item reference; Hermes' own
route prompt enforces the assignment/label policy.
"""
from __future__ import annotations

import hashlib
import hmac
import json
from pathlib import Path
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen

HERMES_WEBHOOK_URL = "http://127.0.0.1:8644/webhooks/plane-work-item"
SECRET_FILE = Path.home() / ".config/sops-nix/secrets/plane/hermes-webhook-secret"


def sign(secret: str, body: bytes, timestamp: str) -> str:
    signed_content = timestamp.encode("utf-8") + b"." + body
    return hmac.new(secret.encode("utf-8"), signed_content, hashlib.sha256).hexdigest()


def deliver(secret: str, delivery: tuple[str, str, str, str, str, str]) -> bool:
    delivery_id, project_id, work_item_id, identifier, event_type, comment_id = delivery
    body = json.dumps(
        {
            "delivery_id": delivery_id,
            "project_id": project_id,
            "work_item_id": work_item_id,
            "identifier": identifier,
            "event_type": event_type,
            "comment_id": comment_id,
        },
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")

    import time

    timestamp = str(int(time.time()))
    req = Request(
        HERMES_WEBHOOK_URL,
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-Webhook-Timestamp": timestamp,
            "X-Webhook-Signature-V2": sign(secret, body, timestamp),
        },
        method="POST",
    )
    try:
        with urlopen(req, timeout=30) as response:
            return 200 <= response.status < 300
    except HTTPError as exc:
        if 200 <= exc.code < 300:
            return True
        raise


def consume(queue: Any, secret: str) -> int:
    """Claim pending deliveries and hand them to Hermes.  Returns count dispatched."""
    deliveries = queue.claim_pending()
    dispatched = 0
    for delivery in deliveries:
        if deliver(secret, delivery):
            queue.finish(delivery[0])
            dispatched += 1
    return dispatched


if __name__ == "__main__":
    raise SystemExit("Use as a module from dispatcher/run.py")
