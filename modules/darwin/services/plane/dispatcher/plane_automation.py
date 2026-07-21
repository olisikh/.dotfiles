#!/usr/bin/env python3
"""Local, controller-owned operational commands for Plane automation runs."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from plane_runs import Run, RunLedger
from plane_smoke import LiveSmokeRunner, SmokeConfiguration, SmokeError


def _public_run(run: Run) -> dict[str, object]:
    return {
        "run_id": run.run_id,
        "trigger_id": run.trigger_id,
        "project_id": run.project_id,
        "work_item_id": run.work_item_id,
        "operation": run.operation.value,
        "label_triggered": run.label_triggered,
        "state": run.state.value,
        "retry_count": run.retry_count,
        "created_at": run.created_at,
        "updated_at": run.updated_at,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect and control Plane automation runs")
    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("status", help="Show sanitized aggregate metrics and active runs")
    smoke_parser = subcommands.add_parser("smoke", help="Run explicit positive smoke tests against the live TEST project")
    smoke_parser.add_argument("--live", action="store_true", help="Acknowledge that this creates and closes a real TEST ticket")
    smoke_parser.add_argument("--timeout", type=float, default=300.0, help="Seconds to wait for each real webhook/run")
    for command, help_text in (("cancel", "Cancel a pending or blocked run"), ("retry", "Clone a failed or cancelled run")):
        command_parser = subcommands.add_parser(command, help=help_text)
        command_parser.add_argument("run_id")
    args = parser.parse_args()

    if args.command == "smoke":
        if not args.live:
            print(json.dumps({"ok": False, "error": "refusing live Plane mutation without --live"}, separators=(",", ":")))
            return 1
        try:
            report = LiveSmokeRunner(SmokeConfiguration.from_environment(), timeout_seconds=args.timeout).run()
        except SmokeError as exc:
            print(json.dumps({"ok": False, "error": str(exc)}, separators=(",", ":")))
            return 1
        print(json.dumps({"ok": True, **report}, separators=(",", ":")))
        return 0

    state_dir = Path(os.environ["PLANE_STATE_DIR"])
    ledger = RunLedger(str(state_dir / "runs.sqlite3"))
    try:
        if args.command == "status":
            print(json.dumps({"metrics": ledger.metrics(), "active_runs": [_public_run(run) for run in ledger.active_runs()]}, separators=(",", ":")))
        elif args.command == "cancel":
            print(json.dumps(_public_run(ledger.cancel_run(args.run_id)), separators=(",", ":")))
        else:
            print(json.dumps(_public_run(ledger.create_retry(args.run_id)), separators=(",", ":")))
    finally:
        ledger.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
