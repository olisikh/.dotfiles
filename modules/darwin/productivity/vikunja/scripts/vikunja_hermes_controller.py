"""Safe, durable ingress primitives for the Vikunja Hermes comment controller."""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import logging
import re
import sqlite3
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from html.parser import HTMLParser
from pathlib import Path
from typing import Any


PERSONAL_PROJECT_ID = 2


class _LeadingMentionPromptParser(HTMLParser):
    """Accept only a canonical Vikunja mention as the first meaningful content."""

    _WRAPPERS = {"p", "div"}

    def __init__(self, bot_username: str) -> None:
        super().__init__(convert_charrefs=True)
        self.bot_username = bot_username
        self.state = "awaiting"
        self.invalid = False
        self.mention_depth = 0
        self.prompt_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if self.invalid:
            return
        if self.state == "awaiting":
            if tag in self._WRAPPERS:
                return
            if tag != "mention-user":
                self.invalid = True
                return
            data_id = dict(attrs).get("data-id")
            if data_id != self.bot_username:
                self.invalid = True
                return
            self.state = "mention"
            self.mention_depth = 1
            return
        if self.state == "mention":
            self.mention_depth += 1
            return
        if self.state == "prompt" and tag in {"br", "p", "div"}:
            self.prompt_parts.append("\n")

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if self.state == "prompt" and tag == "br":
            self.prompt_parts.append("\n")
        elif self.state == "awaiting" and tag not in self._WRAPPERS:
            self.invalid = True

    def handle_endtag(self, tag: str) -> None:
        if self.state == "mention":
            # Vikunja emits a simple <mention-user> text node. Reject any
            # mismatched/nested markup rather than treating it as an invocation.
            if tag != "mention-user" or self.mention_depth != 1:
                self.invalid = True
                return
            self.mention_depth = 0
            self.state = "prompt"

    def handle_data(self, data: str) -> None:
        if self.invalid or not data:
            return
        if self.state == "awaiting" and data.strip():
            self.invalid = True
        elif self.state == "prompt":
            self.prompt_parts.append(data)

    def prompt(self) -> str | None:
        if self.invalid or self.state == "awaiting":
            return None
        text = "".join(self.prompt_parts).strip()
        return text or None


def extract_leading_mention_prompt(comment_html: str, bot_username: str) -> str | None:
    """Return a prompt for a leading structured mention or canonical literal fallback.

    Vikunja 2.4's picker currently omits bot users from its project-user search.
    Until upstream fixes that, accept only a leading, case-sensitive ``@Hermes``
    or ``@bot-hermes`` token in otherwise plain comment text.
    """
    parser = _LeadingMentionPromptParser(bot_username)
    try:
        parser.feed(comment_html)
        parser.close()
    except Exception:  # Defensive: malformed external HTML never becomes an invocation.
        return None
    structured = parser.prompt()
    if structured is not None:
        return structured
    # Never downgrade malformed attempted structured markup to a literal trigger.
    if "<mention-user" in comment_html.lower():
        return None
    plain = _html_to_text(comment_html)
    match = re.fullmatch(r"@(Hermes|" + re.escape(bot_username) + r")(?:\s+)(.+)", plain, re.DOTALL)
    return match.group(2).strip() if match and match.group(2).strip() else None


class DeliveryQueue:
    """SQLite-backed idempotency queue keyed by Vikunja source comment."""

    def __init__(self, database_path: str) -> None:
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(database_path, check_same_thread=False)
        self._conn.execute(
            """
            CREATE TABLE IF NOT EXISTS deliveries (
                trigger_id TEXT PRIMARY KEY,
                project_id INTEGER NOT NULL,
                task_id INTEGER NOT NULL,
                comment_id INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                attempts INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        self._conn.commit()

    def enqueue(self, trigger_id: str, project_id: int, task_id: int, comment_id: int) -> bool:
        with self._lock:
            cursor = self._conn.execute(
                """
                INSERT INTO deliveries (trigger_id, project_id, task_id, comment_id)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(trigger_id) DO NOTHING
                """,
                (trigger_id, project_id, task_id, comment_id),
            )
            self._conn.commit()
            return cursor.rowcount == 1

    def claim_pending(self) -> list[tuple[str, int, int, int]]:
        with self._lock:
            rows = list(
                self._conn.execute(
                    """
                    SELECT trigger_id, project_id, task_id, comment_id
                    FROM deliveries
                    WHERE status = 'pending'
                    ORDER BY created_at, trigger_id
                    """
                )
            )
            if rows:
                self._conn.executemany(
                    """
                    UPDATE deliveries
                    SET status = 'processing', attempts = attempts + 1, updated_at = CURRENT_TIMESTAMP
                    WHERE trigger_id = ?
                    """,
                    [(trigger_id,) for trigger_id, *_ in rows],
                )
                self._conn.commit()
            return rows

    def finish(self, trigger_id: str) -> None:
        with self._lock:
            self._conn.execute(
                "UPDATE deliveries SET status = 'completed', updated_at = CURRENT_TIMESTAMP WHERE trigger_id = ?",
                (trigger_id,),
            )
            self._conn.commit()

    def release(self, trigger_id: str) -> None:
        with self._lock:
            self._conn.execute(
                "UPDATE deliveries SET status = 'pending', updated_at = CURRENT_TIMESTAMP WHERE trigger_id = ?",
                (trigger_id,),
            )
            self._conn.commit()

    def recover_processing(self) -> None:
        with self._lock:
            self._conn.execute(
                "UPDATE deliveries SET status = 'pending', updated_at = CURRENT_TIMESTAMP WHERE status = 'processing'"
            )
            self._conn.commit()

    def close(self) -> None:
        with self._lock:
            self._conn.close()


class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"br", "p", "div", "li"}:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        self.parts.append(data)


def _html_to_text(value: object) -> str:
    if not isinstance(value, str):
        return ""
    parser = _TextExtractor()
    parser.feed(value)
    parser.close()
    return " ".join("".join(parser.parts).split())


def _reply_html(reply: str) -> str:
    import html

    lines = html.escape(reply.strip()).splitlines() or ["I could not produce a response."]
    return "".join(f"<p>{line or '&nbsp;'}</p>" for line in lines)


class VikunjaApiClient:
    """Minimal v2 API client used only by the controller's deterministic I/O."""

    def __init__(self, base_url: str, token: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.token = token

    def _request_json(self, method: str, path: str, body: object | None = None) -> object:
        from urllib.error import HTTPError, URLError
        from urllib.request import Request, urlopen

        data = None
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {self.token}",
        }
        if body is not None:
            data = json.dumps(body, separators=(",", ":")).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = Request(self.base_url + path, data=data, headers=headers, method=method)
        try:
            with urlopen(request, timeout=20) as response:
                raw = response.read()
        except HTTPError as error:
            raise RuntimeError(f"Vikunja API {method} {path} failed with HTTP {error.code}") from error
        except URLError as error:
            raise RuntimeError(f"Vikunja API {method} {path} was unavailable") from error
        if not raw:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError as error:
            raise RuntimeError(f"Vikunja API {method} {path} returned invalid JSON") from error

    @staticmethod
    def _object(value: object, name: str) -> dict[str, Any]:
        if not isinstance(value, dict):
            raise RuntimeError(f"Vikunja API returned an invalid {name} response")
        return value

    def get_task(self, task_id: int) -> dict[str, Any]:
        return self._object(self._request_json("GET", f"/tasks/{task_id}"), "task")

    def get_comment(self, task_id: int, comment_id: int) -> dict[str, Any]:
        return self._object(
            self._request_json("GET", f"/tasks/{task_id}/comments/{comment_id}"), "comment"
        )

    def list_comments(self, task_id: int) -> list[dict[str, Any]]:
        response = self._object(
            self._request_json("GET", f"/tasks/{task_id}/comments?order_by=asc&per_page=100"),
            "comment list",
        )
        items = response.get("items")
        if not isinstance(items, list) or not all(isinstance(item, dict) for item in items):
            raise RuntimeError("Vikunja API returned an invalid comment list")
        return items

    def post_comment(self, task_id: int, comment_html: str) -> None:
        self._request_json("POST", f"/tasks/{task_id}/comments", {"comment": comment_html})


class VikunjaHermesController:
    """Re-fetches a comment, applies the invocation policy, and posts one reply."""

    def __init__(
        self,
        *,
        client: Any,
        bot_username: str,
        bot_user_id: int,
        project_id: int,
        run_agent: Any,
    ) -> None:
        self.client = client
        self.bot_username = bot_username
        self.bot_user_id = bot_user_id
        self.project_id = project_id
        self.run_agent = run_agent

    def process(self, delivery: tuple[str, int, int, int]) -> str:
        _trigger_id, _payload_project_id, task_id, comment_id = delivery
        task = self.client.get_task(task_id)
        if self.project_id != PERSONAL_PROJECT_ID or task.get("project_id") != PERSONAL_PROJECT_ID:
            return "ignored"

        comment = self.client.get_comment(task_id, comment_id)
        author = comment.get("author") if isinstance(comment, dict) else None
        if not isinstance(author, dict):
            return "ignored"
        if author.get("id") == self.bot_user_id:
            return "ignored"

        direct_prompt = extract_leading_mention_prompt(comment.get("comment", ""), self.bot_username)
        if direct_prompt is None:
            return "ignored"

        comments = self.client.list_comments(task_id)
        agent_prompt = self._build_agent_prompt(task, comments, direct_prompt)
        reply = self.run_agent(agent_prompt)
        if not isinstance(reply, str) or not reply.strip():
            raise RuntimeError("Hermes returned no reply")
        self.client.post_comment(task_id, _reply_html(reply))
        return "replied"

    @staticmethod
    def _build_agent_prompt(task: dict[str, Any], comments: list[dict[str, Any]], direct_prompt: str) -> str:
        title = _html_to_text(task.get("title"))
        description = _html_to_text(task.get("description"))
        rendered_comments = []
        for comment in comments[-50:]:
            author = comment.get("author") if isinstance(comment, dict) else None
            username = author.get("username", "unknown") if isinstance(author, dict) else "unknown"
            text = _html_to_text(comment.get("comment") if isinstance(comment, dict) else "")
            if text:
                rendered_comments.append(f"- {username}: {text}")
        history = "\n".join(rendered_comments) or "- No prior comments."
        return (
            "You are Hermes, a full Hermes agent responding to a human's direct Vikunja prompt. "
            "Follow the human's request and normal Hermes operating rules. You may use your configured tools "
            "and integrations, including Vikunja, when useful to complete the request. The controller will post "
            "your final response as one bot comment after this turn, so do not create a duplicate final comment; "
            "post Vikunja comments yourself only when the human specifically asks you to. Return the helpful "
            "response for the human.\n\n"
            f"Ticket title: {title}\n"
            f"Ticket description: {description}\n"
            f"Comment history:\n{history}\n\n"
            f"Current human prompt: {direct_prompt}"
        )


def verify_vikunja_signature(secret: str, body: bytes, signature: str) -> bool:
    expected = hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature.strip())


def _extract_comment_reference(payload: dict[str, Any]) -> tuple[int, int, int] | None:
    if payload.get("event_name") != "task.comment.created":
        return None
    data = payload.get("data")
    if not isinstance(data, dict):
        return None
    task = data.get("task")
    comment = data.get("comment")
    if not isinstance(task, dict) or not isinstance(comment, dict):
        return None
    project_id = task.get("project_id")
    task_id = task.get("id")
    comment_id = comment.get("id")
    if not all(isinstance(value, int) and value > 0 for value in (project_id, task_id, comment_id)):
        return None
    return project_id, task_id, comment_id


def ingest_vikunja_delivery(
    queue: DeliveryQueue, secret: str, headers: dict[str, str], body: bytes,
    *, project_id: int = PERSONAL_PROJECT_ID,
) -> bool:
    """Verify and durably record one supported Vikunja delivery.

    The webhook payload remains only an authenticated hint; the controller must
    re-fetch the task and comment before it invokes Hermes or posts a reply.
    """
    normalized_headers = {key.lower(): value for key, value in headers.items()}
    signature = normalized_headers.get("x-vikunja-signature", "")
    if not signature or not verify_vikunja_signature(secret, body, signature):
        return False
    try:
        payload = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return False
    if not isinstance(payload, dict):
        return False
    reference = _extract_comment_reference(payload)
    if reference is None:
        return False
    payload_project_id, task_id, comment_id = reference
    if project_id != PERSONAL_PROJECT_ID or payload_project_id != PERSONAL_PROJECT_ID:
        return False
    queue.enqueue(f"task.comment.created:{task_id}:{comment_id}", payload_project_id, task_id, comment_id)
    return True


def _read_secret(path: str) -> str:
    secret = Path(path).read_text(encoding="utf-8").strip()
    if not secret:
        raise RuntimeError(f"secret file is empty: {path}")
    return secret


def run_hermes_oneshot(
    prompt: str,
    *,
    executable: str,
    provider: str,
    model: str,
) -> str:
    """Invoke a normal full-capability Hermes one-shot turn."""
    command = [
        executable,
        "-z",
        prompt,
        "--provider",
        provider,
        "--model",
        model,
        "--no-restore-cwd",
    ]
    result = subprocess.run(command, text=True, capture_output=True, timeout=300, check=False)
    if result.returncode != 0:
        detail = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "unknown error"
        raise RuntimeError(f"Hermes one-shot failed: {detail[:500]}")
    reply = result.stdout.strip()
    if not reply:
        raise RuntimeError("Hermes one-shot produced no response")
    return reply


def _make_handler(queue: DeliveryQueue, secret: str, path: str) -> type[BaseHTTPRequestHandler]:
    class WebhookHandler(BaseHTTPRequestHandler):
        server_version = "VikunjaHermesController/1"

        def do_POST(self) -> None:  # noqa: N802 - required HTTP handler spelling
            if self.path != path:
                self.send_error(404)
                return
            try:
                content_length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                self.send_error(400)
                return
            if content_length <= 0 or content_length > 1_000_000:
                self.send_error(413)
                return
            body = self.rfile.read(content_length)
            accepted = ingest_vikunja_delivery(queue, secret, dict(self.headers.items()), body)
            if not accepted:
                self.send_error(401)
                return
            self.send_response(202)
            self.send_header("Content-Length", "0")
            self.end_headers()

        def log_message(self, format: str, *args: object) -> None:
            logging.info("webhook %s", format % args)

    return WebhookHandler


def _worker_loop(
    queue: DeliveryQueue,
    controller: VikunjaHermesController,
    stop_event: threading.Event,
) -> None:
    while not stop_event.is_set():
        deliveries = queue.claim_pending()
        if not deliveries:
            stop_event.wait(0.5)
            continue
        for delivery in deliveries:
            trigger_id = delivery[0]
            try:
                result = controller.process(delivery)
                queue.finish(trigger_id)
                logging.info("delivery %s %s", trigger_id, result)
            except Exception:
                logging.exception("delivery %s failed; it will be retried", trigger_id)
                queue.release(trigger_id)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Vikunja comment → Hermes reply controller")
    parser.add_argument("--api-base", required=True)
    parser.add_argument("--api-token-file", required=True)
    parser.add_argument("--webhook-secret-file", required=True)
    parser.add_argument("--state-db", required=True)
    parser.add_argument("--bot-username", required=True)
    parser.add_argument("--bot-user-id", required=True, type=int)
    parser.add_argument("--project-id", required=True, type=int)
    parser.add_argument("--hermes-executable", required=True)
    parser.add_argument("--hermes-provider", required=True)
    parser.add_argument("--hermes-model", required=True)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", default=3457, type=int)
    parser.add_argument("--path", default="/hooks/vikunja-hermes")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    queue = DeliveryQueue(args.state_db)
    queue.recover_processing()
    client = VikunjaApiClient(args.api_base, _read_secret(args.api_token_file))
    controller = VikunjaHermesController(
        client=client,
        bot_username=args.bot_username,
        bot_user_id=args.bot_user_id,
        project_id=args.project_id,
        run_agent=lambda prompt: run_hermes_oneshot(
            prompt,
            executable=args.hermes_executable,
            provider=args.hermes_provider,
            model=args.hermes_model,
        ),
    )
    stop_event = threading.Event()
    worker = threading.Thread(target=_worker_loop, args=(queue, controller, stop_event), daemon=True)
    worker.start()
    server = ThreadingHTTPServer((args.bind, args.port), _make_handler(queue, _read_secret(args.webhook_secret_file), args.path))
    logging.info("listening on http://%s:%s%s", args.bind, args.port, args.path)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        logging.info("stopping")
    finally:
        stop_event.set()
        server.shutdown()
        server.server_close()
        worker.join(timeout=2)
        queue.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
