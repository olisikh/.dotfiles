#!/usr/bin/env python3
"""Run the loopback-only Plane webhook ingress service."""
from __future__ import annotations

import os
import signal
import threading
from http.server import ThreadingHTTPServer
from pathlib import Path

from plane_runs import RunLedger

from plane_client import PlaneClient
from plane_controller import PlaneAutomationController
from plane_dispatcher import CooldownMap, DeliveryQueue, make_dispatch_handler


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
recovered = queue.recover_processing()
if recovered:
    print(f"plane_dispatcher_recovered_processing={recovered}")
ledger = RunLedger(str(state_dir / "runs.sqlite3"))
cooldown = CooldownMap(float(os.environ.get("PLANE_DISPATCHER_COOLDOWN_SECONDS", "10")))
server = ThreadingHTTPServer(
    ("127.0.0.1", int(os.environ.get("PLANE_DISPATCHER_PORT", "9801"))),
    make_dispatch_handler(queue, ledger, cooldown, secret),
)


def _load_agent_env() -> dict[str, str]:
    """Load the rendered Plane agent environment file."""
    env: dict[str, str] = {}
    agent_env = state_dir / "plane-agent.env"
    legacy_env = Path(os.environ.get("PLANE_LEGACY_RUNTIME_DIR", "")) / "plane-agent.env"
    if not agent_env.exists() and legacy_env.exists():
        agent_env = legacy_env
    if agent_env.exists():
        with agent_env.open(encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                env[key] = value.strip()
    return env


def _make_controller() -> PlaneAutomationController:
    """Build the deterministic Plane automation controller."""
    agent_env = _load_agent_env()
    workspace_slug = agent_env.get("PLANE_WORKSPACE_SLUG", os.environ.get("PLANE_WORKSPACE_SLUG", ""))
    if not workspace_slug:
        raise ValueError("PLANE_WORKSPACE_SLUG is not set")

    base_url = os.environ.get("PLANE_INTERNAL_BASE_URL", "")
    if not base_url:
        base_url = f"http://127.0.0.1:{os.environ.get('PLANE_PROXY_PORT', '28080')}"

    api_key_file = secrets_dir / "hermes-api-token"
    if not api_key_file.exists():
        raise ValueError(f"missing Plane API token: {api_key_file}")
    api_key = api_key_file.read_text(encoding="utf-8").strip()
    if not api_key:
        raise ValueError("empty Plane API token")

    plane_client = PlaneClient(base_url=base_url, workspace_slug=workspace_slug, api_key=api_key)
    hermes_user_id = os.environ.get("PLANE_HERMES_USER_ID", "")
    return PlaneAutomationController(
        plane_client=plane_client,
        hermes_user_id=hermes_user_id or None,
    )


def _consumer_tick() -> None:
    """Periodically claim pending deliveries and drive them to terminal state."""
    try:
        from hermes_consumer import consume

        controller = _make_controller()
        dispatched = consume(queue, ledger, controller)
        if dispatched:
            print(f"plane_dispatcher_handoff: dispatched={dispatched}")
    except Exception as exc:  # noqa: BLE001 - background worker must stay alive
        print(f"plane_dispatcher_consumer_error: {exc}")
    finally:
        threading.Timer(30.0, _consumer_tick).start()


signal.signal(
    signal.SIGTERM,
    lambda *_args: threading.Thread(target=server.shutdown, daemon=True).start(),
)
signal.signal(
    signal.SIGINT,
    lambda *_args: threading.Thread(target=server.shutdown, daemon=True).start(),
)
threading.Timer(30.0, _consumer_tick).start()
try:
    server.serve_forever(poll_interval=0.5)
finally:
    server.server_close()
    queue.close()
    ledger.close()
