"""Hermes subprocess worker wrapper with a strict JSON result envelope.

The controller owns every Plane mutation; the worker is a narrow reasoning task
that receives a prompt plus read-only context and returns a typed result. It
never has Plane-write tools.
"""
from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
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
        self._hermes_path = hermes_path
        self._max_turns = max_turns
        self._timeout = timeout_seconds

    def invoke(self, run: Run, work_item_context: dict[str, Any]) -> WorkerResult:
        """Run Hermes with a controller-authored prompt and parse the envelope."""
        prompt = self._build_prompt(run, work_item_context)
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
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self._timeout,
                check=False,
            )
        except subprocess.CalledProcessError as exc:
            return self._failure(f"Hermes exited with code {exc.returncode}: {exc.stderr}")
        except subprocess.TimeoutExpired as exc:
            return self._failure(f"Hermes timed out after {self._timeout}s")

        stdout = proc.stdout.strip()
        if proc.returncode != 0:
            stderr = proc.stderr.strip()
            return self._failure(f"Hermes exited {proc.returncode}: {stderr or stdout}")

        return self._parse_envelope(stdout)

    def _build_prompt(self, run: Run, work_item_context: dict[str, Any]) -> str:
        operation_name = run.operation.value
        title = work_item_context.get("name", "Untitled")
        description = work_item_context.get("description_html", "")
        return (
            f"You are helping with a Plane work item. Operation: {operation_name}.\n"
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
        try:
            data = json.loads(stdout)
        except json.JSONDecodeError:
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
