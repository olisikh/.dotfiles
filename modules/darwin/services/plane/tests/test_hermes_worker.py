"""Tests for the Hermes subprocess worker wrapper used by the Plane controller.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from hermes_worker import HermesWorker, WorkerResult
from plane_invocation import Invocation, InvocationKind, InvocationOperation, InvocationSource
from plane_runs import Run, RunState


def _make_run(
    body: str = "Explain this", operation: InvocationOperation = InvocationOperation.ASK
) -> Run:
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


def _successful_stdout() -> str:
    return json.dumps(
        {
            "status": "success",
            "final_comment_markdown": "Here is the answer.",
            "summary": "answered",
            "artifacts": [],
        }
    )


def test_invokes_hermes_with_query_and_parses_envelope() -> None:
    worker = HermesWorker(hermes_path="/fake/hermes")
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = _successful_stdout()
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.invoke(
            _make_run("Explain this"),
            {"name": "Test issue", "description_html": "<p>Context</p>"},
        )

    assert isinstance(result, WorkerResult)
    assert result.status == "success"
    assert result.final_comment_markdown == "Here is the answer."
    assert result.summary == "answered"
    mock_run.assert_called_once()
    cmd = mock_run.call_args[0][0]
    assert cmd[0] == "/fake/hermes"
    assert cmd[1] == "chat"
    assert "-q" in cmd
    assert "Explain this" in cmd[cmd.index("-q") + 1]


def test_wraps_non_json_stdout_as_failure() -> None:
    worker = HermesWorker()
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = "Just plain text"
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.invoke(_make_run(), {})

    assert result.status == "failure"
    assert "Just plain text" in result.final_comment_markdown
    assert result.summary.startswith("worker envelope invalid")


def test_returns_failure_on_subprocess_error() -> None:
    worker = HermesWorker()
    with patch("subprocess.run") as mock_run:
        from subprocess import CalledProcessError

        mock_run.side_effect = CalledProcessError(1, "hermes", output="", stderr="boom")

        result = worker.invoke(_make_run(), {})

    assert result.status == "failure"
    assert "boom" in result.final_comment_markdown


def test_validates_required_envelope_fields() -> None:
    worker = HermesWorker()
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = json.dumps({"status": "success"})
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.invoke(_make_run(), {})

    assert result.status == "failure"
    assert "missing" in result.summary.lower()


def test_go_preflight_is_read_only_and_does_not_authorize_execution() -> None:
    worker = HermesWorker(hermes_path="/fake/hermes")
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = _successful_stdout()
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.assess_go(
            _make_run("Implement it", InvocationOperation.GO),
            {"name": "Test issue", "description_html": "<p>Context</p>"},
        )

    assert result.status == "success"
    prompt = mock_run.call_args[0][0][mock_run.call_args[0][0].index("-q") + 1]
    assert "Do not execute" in prompt
    assert "clarification_needed" in prompt


def test_go_execution_prompt_authorizes_actual_work() -> None:
    worker = HermesWorker(hermes_path="/fake/hermes")
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = _successful_stdout()
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.execute_go(
            _make_run("Implement it", InvocationOperation.GO),
            {"name": "Test issue", "description_html": "<p>Context</p>"},
        )

    assert result.status == "success"
    prompt = mock_run.call_args[0][0][mock_run.call_args[0][0].index("-q") + 1]
    assert "Execute the requested work" in prompt


def test_accepts_json_envelope_after_hermes_cli_preamble() -> None:
    worker = HermesWorker()
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.stdout = "⚠ diagnostic warning\n" + _successful_stdout()
        mock_run.return_value.stderr = ""
        mock_run.return_value.returncode = 0

        result = worker.invoke(_make_run(), {})

    assert result.status == "success"
    assert result.final_comment_markdown == "Here is the answer."


def test_variant_environment_preserves_auth_credentials() -> None:
    with tempfile.TemporaryDirectory() as source_dir:
        source_home = Path(source_dir)
        (source_home / "config.yaml").write_text("agent:\n  reasoning_effort: medium\n")
        auth = source_home / "auth.json"
        auth.write_text('{"providers": {}}')
        with patch.dict(os.environ, {"HERMES_HOME": str(source_home)}, clear=False):
            env, temporary_home = HermesWorker()._variant_environment("low")
        try:
            assert env is not None
            assert temporary_home is not None
            isolated_auth = Path(temporary_home.name) / "auth.json"
            assert isolated_auth.is_symlink()
            assert isolated_auth.readlink() == auth
        finally:
            if temporary_home is not None:
                temporary_home.cleanup()


if __name__ == "__main__":
    import signal

    def _timeout(_sig, _frame) -> None:
        raise SystemExit("hermes_worker_tests_timeout")

    signal.signal(signal.SIGALRM, _timeout)
    signal.alarm(30)
    for name in sorted(dir()):
        if name.startswith("test_"):
            fn = globals()[name]
            fn()
            print(f"OK {name}")
    print("all_hermes_worker_tests_passed")
