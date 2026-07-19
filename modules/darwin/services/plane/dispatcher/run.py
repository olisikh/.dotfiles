#!/usr/bin/env python3
"""Run the loopback-only Plane webhook ingress service."""
from __future__ import annotations

import os
import signal
import threading
from http.server import ThreadingHTTPServer
from pathlib import Path

from plane_dispatcher import DeliveryQueue, make_dispatch_handler


def required_path(name: str) -> Path:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"required runtime environment variable is unavailable: {name}")
    return Path(value)


state_dir = required_path("PLANE_STATE_DIR")
secrets_dir = required_path("PLANE_SECRETS_DIR")
secret_file = secrets_dir / "dispatcher-secret"
secret = secret_file.read_text(encoding="utf-8").strip()
if not secret:
    raise SystemExit(f"Plane dispatcher secret is empty: {secret_file}")

state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
queue = DeliveryQueue(str(state_dir / "dispatcher.sqlite3"))
server = ThreadingHTTPServer(
    ("127.0.0.1", int(os.environ.get("PLANE_DISPATCHER_PORT", "9801"))),
    make_dispatch_handler(queue, secret),
)


signal.signal(
    signal.SIGTERM,
    lambda *_args: threading.Thread(target=server.shutdown, daemon=True).start(),
)
signal.signal(
    signal.SIGINT,
    lambda *_args: threading.Thread(target=server.shutdown, daemon=True).start(),
)
try:
    server.serve_forever(poll_interval=0.5)
finally:
    server.server_close()
    queue.close()
