"""Hermes subprocess worker wrapper with a strict JSON result envelope.

The controller owns every Plane mutation; the worker is a narrow reasoning task
that receives a prompt plus read-only context and returns a typed result. It
never has Plane-write tools.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from plane_invocation import InvocationOperation
from plane_runs import Run


@dataclass(frozen=True, slots=True)
class WorkerResult:
    status: str
    final_comment_markdown: str
    summary: str
    artifacts: list[dict[str, Any]]


class HermesWorker:
    """Invoke Hermes as a one-shot worker for ask/triage/go reasoning."""

    def __init__(
        self,
        *,
        hermes_path: str = "~/.local/bin/hermes",
        max_turns: int = 30,
        timeout_seconds: float = 300.0,
    ) -> None:
        self._hermes_path = os.path.expanduser(hermes_path)
        self._max_turns = max_turns
        self._timeout = timeout_seconds

    def invoke(self, run: Run, work_item_context: dict[str, Any]) -> WorkerResult:
        """Run Hermes for a read-only ask or triage response."""
        return self._invoke_prompt(run, self._build_prompt(run, work_item_context, stage="response"))

    def assess_go(self, run: Run, work_item_context: dict[str, Any]) -> WorkerResult:
        """Determine whether a GO request is actionable without taking action."""
        return self._invoke_prompt(run, self._build_prompt(run, work_item_context, stage="preflight"))

    def execute_go(self, run: Run, work_item_context: dict[str, Any]) -> WorkerResult:
        """Execute an already-cleared GO request and report its terminal result."""
        return self._invoke_prompt(run, self._build_prompt(run, work_item_context, stage="execution"))

    def _invoke_prompt(self, run: Run, prompt: str) -> WorkerResult:
        """Run a controller-authored prompt and parse the strict result envelope."""
        cmd = [
            self._hermes_path,
            "chat",
            "-q",
            prompt,
            "-Q",
            "--ignore-rules",
            "--no-restore-cwd",
            "--max-turns",
            str(self._max_turns),
        ]
        if run.model_selector:
            cmd.extend(["-m", run.model_selector])

        try:
            env, temporary_home = self._variant_environment(run.reasoning_effort)
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self._timeout,
                check=False,
                env=env,
            )
        except subprocess.CalledProcessError as exc:
            return self._failure(f"Hermes exited with code {exc.returncode}: {exc.stderr}")
        except subprocess.TimeoutExpired as exc:
            return self._failure(f"Hermes timed out after {self._timeout}s")
        except OSError as exc:
            return self._failure(f"Hermes worker could not start: {exc}")

        stdout = proc.stdout.strip()
        if proc.returncode != 0:
            stderr = proc.stderr.strip()
            return self._failure(f"Hermes exited {proc.returncode}: {stderr or stdout}")

        return self._parse_envelope(stdout)

    def _variant_environment(self, effort: str | None) -> tuple[dict[str, str] | None, tempfile.TemporaryDirectory[str] | None]:
        """Give one worker an isolated config with its requested reasoning effort."""
        if effort is None:
            return None, None
        source_home = Path(os.environ.get("HERMES_HOME", "~/.hermes")).expanduser()
        source_config = source_home / "config.yaml"
        raw_config = source_config.read_text(encoding="utf-8")
        rewritten, replacements = re.subn(
            r"(?m)^  reasoning_effort:\s*.*$", f"  reasoning_effort: {effort}", raw_config, count=1
        )
        if replacements != 1:
            raise RuntimeError("could not set agent.reasoning_effort in isolated Hermes config")
        temporary_home = tempfile.TemporaryDirectory(prefix="plane-hermes-")
        temp_path = Path(temporary_home.name)
        (temp_path / "config.yaml").write_text(rewritten, encoding="utf-8")
        (temp_path / "config.yaml").chmod(0o600)
        for credential_name in (".env", "auth.json"):
            source_credential = source_home / credential_name
            if source_credential.exists():
                (temp_path / credential_name).symlink_to(source_credential)
        env = os.environ.copy()
        env["HERMES_HOME"] = temporary_home.name
        return env, temporary_home

    def _build_prompt(
        self, run: Run, work_item_context: dict[str, Any], *, stage: str
    ) -> str:
        operation_name = run.operation.value
        title = work_item_context.get("name", "Untitled")
        description = work_item_context.get("description_html", "")
        stage_instruction = {
            "response": "Answer or triage the ticket context. Do not mutate Plane.",
            "preflight": (
                "Do not execute work, write files, call external services, or mutate Plane. "
                "Only determine whether the request is sufficiently clear to execute. "
                "Return status=success if it is clear, or status=clarification_needed with "
                "a concise question if it is not."
            ),
            "execution": (
                "Execute the requested work now, respecting normal Hermes guardrails. "
                "If an approval guardrail prevents the requested action, return status=blocked."
            ),
        }[stage]
        return (
            f"You are helping with a Plane work item. Operation: {operation_name}.\n"
            f"Stage: {stage}. {stage_instruction}\n"
            f"Title: {title}\n"
            f"Description HTML: {description}\n"
            f"User request: {run.body}\n\n"
            "Return ONLY a JSON object with exactly these keys:\n"
            "- status: one of success, clarification_needed, blocked, failure\n"
            "- final_comment_markdown: the markdown to post as the response comment\n"
            "- summary: a short internal summary (one sentence)\n"
            "- artifacts: a list of objects with kind and value (or empty list)\n"
            "Do not include any text outside the JSON object."
        )

    def _parse_envelope(self, stdout: str) -> WorkerResult:
        payload = stdout.lstrip()
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            # Hermes may emit a human-readable local diagnostic before the
            # machine contract. Accept only a complete trailing JSON envelope.
            start = payload.find("{")
            if start < 0:
                data = None
            else:
                try:
                    data, consumed = json.JSONDecoder().raw_decode(payload[start:])
                    if payload[start + consumed :].strip():
                        data = None
                except json.JSONDecodeError:
                    data = None
            if data is None:
                return self._failure(
                    f"Worker envelope invalid: expected JSON, got:\n\n{stdout[:2000]}",
                    summary="worker envelope invalid: not JSON",
                )
        if not isinstance(data, dict):
            return self._failure("Worker envelope invalid: JSON root is not an object")
        required = {"status", "final_comment_markdown", "summary", "artifacts"}
        missing = required - data.keys()
        if missing:
            return self._failure(
                f"Worker envelope invalid: missing keys {sorted(missing)}",
                summary=f"worker envelope invalid: missing {sorted(missing)}",
            )
        return WorkerResult(
            status=str(data["status"]),
            final_comment_markdown=str(data["final_comment_markdown"]),
            summary=str(data["summary"]),
            artifacts=list(data.get("artifacts", []) or []),
        )

    def _failure(self, markdown: str, summary: str | None = None) -> WorkerResult:
        return WorkerResult(
            status="failure",
            final_comment_markdown=f"⚠️ Automation failed.\n\n{markdown}",
            summary=summary or markdown[:200],
            artifacts=[],
        )
