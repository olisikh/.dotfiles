from __future__ import annotations

import hashlib
import hmac
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))


class LeadingMentionPromptTests(unittest.TestCase):
    def test_extracts_prompt_after_a_leading_structured_bot_mention(self) -> None:
        from vikunja_hermes_controller import extract_leading_mention_prompt

        comment = (
            '<p><mention-user data-id="bot-hermes" data-label="Hermes">@Hermes'
            "</mention-user> What should I do next?</p>"
        )

        self.assertEqual(
            extract_leading_mention_prompt(comment, "bot-hermes"),
            "What should I do next?",
        )

    def test_accepts_a_leading_plain_text_trigger_but_rejects_mid_comment_or_other_mentions(self) -> None:
        from vikunja_hermes_controller import extract_leading_mention_prompt

        self.assertEqual(extract_leading_mention_prompt("@Hermes help", "bot-hermes"), "help")
        self.assertEqual(extract_leading_mention_prompt("<p>@bot-hermes hello</p>", "bot-hermes"), "hello")
        self.assertIsNone(
            extract_leading_mention_prompt(
                "Please review <mention-user data-id=\"bot-hermes\">@Hermes</mention-user>",
                "bot-hermes",
            )
        )
        self.assertIsNone(
            extract_leading_mention_prompt(
                '<p><mention-user data-id="bot-someone-else">@Else</mention-user> help</p>',
                "bot-hermes",
            )
        )
        self.assertIsNone(
            extract_leading_mention_prompt(
                '<mention-user data-id="bot-hermes">@Hermes</span> invoke me', "bot-hermes"
            )
        )
        self.assertIsNone(
            extract_leading_mention_prompt(
                '<mention-user data-id="bot-hermes"><strong>@Hermes</strong></mention-user> invoke me',
                "bot-hermes",
            )
        )


class VikunjaIngressTests(unittest.TestCase):
    def test_accepts_a_signed_comment_delivery_and_deduplicates_by_comment(self) -> None:
        from vikunja_hermes_controller import DeliveryQueue, ingest_vikunja_delivery

        secret = "shared-secret"
        payload = {
            "event_name": "task.comment.created",
            "data": {
                "task": {"id": 42, "project_id": 2},
                "comment": {"id": 77},
            },
        }
        body = json.dumps(payload, separators=(",", ":")).encode()
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)

        self.assertTrue(
            ingest_vikunja_delivery(
                queue,
                secret,
                {"X-Vikunja-Signature": signature},
                body,
            )
        )
        self.assertTrue(
            ingest_vikunja_delivery(
                queue,
                secret,
                {"X-Vikunja-Signature": signature},
                body,
            )
        )
        self.assertEqual(queue.claim_pending(), [("task.comment.created:42:77", 2, 42, 77)])
        self.assertEqual(queue.claim_pending(), [])

    def test_rejects_unsigned_or_non_comment_deliveries(self) -> None:
        from vikunja_hermes_controller import DeliveryQueue, ingest_vikunja_delivery

        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        self.assertFalse(ingest_vikunja_delivery(queue, "secret", {}, b"{}"))

        body = json.dumps(
            {"event_name": "task.updated", "data": {"task": {"id": 42, "project_id": 2}}}
        ).encode()
        signature = hmac.new(b"secret", body, hashlib.sha256).hexdigest()
        self.assertFalse(
            ingest_vikunja_delivery(
                queue,
                "secret",
                {"X-Vikunja-Signature": signature},
                body,
            )
        )


class CommentControllerTests(unittest.TestCase):
    def test_replies_only_to_a_human_leading_bot_mention_in_the_target_project(self) -> None:
        from vikunja_hermes_controller import VikunjaHermesController

        class FakeClient:
            def __init__(self) -> None:
                self.posted: list[tuple[int, str]] = []

            def get_task(self, task_id: int) -> dict[str, object]:
                self.assertEqual(task_id, 42)
                return {"id": 42, "project_id": 2, "title": "Prepare the proposal", "description": ""}

            def get_comment(self, task_id: int, comment_id: int) -> dict[str, object]:
                self.assertEqual((task_id, comment_id), (42, 77))
                return {
                    "id": 77,
                    "comment": '<p><mention-user data-id="bot-hermes">@Hermes</mention-user> What is missing?</p>',
                    "author": {"id": 4, "username": "oleksii"},
                }

            def list_comments(self, task_id: int) -> list[dict[str, object]]:
                self.assertEqual(task_id, 42)
                return [{"comment": "Earlier decision", "author": {"username": "oleksii"}}]

            def post_comment(self, task_id: int, comment_html: str) -> None:
                self.posted.append((task_id, comment_html))

            def assertEqual(self, actual: object, expected: object) -> None:
                if actual != expected:
                    raise AssertionError(f"{actual!r} != {expected!r}")

        captured_prompts: list[str] = []
        client = FakeClient()
        controller = VikunjaHermesController(
            client=client,
            bot_username="bot-hermes",
            bot_user_id=99,
            project_id=2,
            run_agent=lambda prompt: captured_prompts.append(prompt) or "The scope is clear.",
        )

        self.assertEqual(
            controller.process(("task.comment.created:42:77", 2, 42, 77)),
            "replied",
        )
        self.assertEqual(len(captured_prompts), 1)
        self.assertIn("Prepare the proposal", captured_prompts[0])
        self.assertIn("What is missing?", captured_prompts[0])
        self.assertIn("Do not access Vikunja directly", captured_prompts[0])
        self.assertEqual(client.posted, [(42, "<p>The scope is clear.</p>")])

    def test_ignores_self_authored_and_non_target_project_comments(self) -> None:
        from vikunja_hermes_controller import VikunjaHermesController

        class FakeClient:
            def __init__(self, project_id: int, author_id: int) -> None:
                self.project_id = project_id
                self.author_id = author_id
                self.posted = False

            def get_task(self, task_id: int) -> dict[str, object]:
                return {"id": task_id, "project_id": self.project_id, "title": "x", "description": ""}

            def get_comment(self, task_id: int, comment_id: int) -> dict[str, object]:
                return {
                    "id": comment_id,
                    "comment": '<p><mention-user data-id="bot-hermes">@Hermes</mention-user> help</p>',
                    "author": {"id": self.author_id, "username": "bot-hermes"},
                }

            def list_comments(self, task_id: int) -> list[dict[str, object]]:
                raise AssertionError("ignored deliveries must not load context")

            def post_comment(self, task_id: int, comment_html: str) -> None:
                self.posted = True

        for client in (FakeClient(project_id=1, author_id=4), FakeClient(project_id=2, author_id=99)):
            controller = VikunjaHermesController(
                client=client,
                bot_username="bot-hermes",
                bot_user_id=99,
                project_id=2,
                run_agent=lambda _prompt: (_ for _ in ()).throw(AssertionError("must not run")),
            )
            self.assertEqual(controller.process(("id", 2, 42, 77)), "ignored")
            self.assertFalse(client.posted)


class VikunjaApiClientTests(unittest.TestCase):
    def test_uses_v2_task_and_comment_routes(self) -> None:
        from vikunja_hermes_controller import VikunjaApiClient

        class RecordingClient(VikunjaApiClient):
            def __init__(self) -> None:
                super().__init__("http://vikunja.test/api/v2", "token")
                self.calls: list[tuple[str, str, object | None]] = []

            def _request_json(self, method: str, path: str, body: object | None = None) -> object:
                self.calls.append((method, path, body))
                if path.endswith("/comments?order_by=asc&per_page=100") and method == "GET":
                    return {"items": [{"id": 1}]}
                return {"id": 1, "project_id": 2}

        client = RecordingClient()
        self.assertEqual(client.get_task(42)["id"], 1)
        self.assertEqual(client.get_comment(42, 77)["id"], 1)
        self.assertEqual(client.list_comments(42), [{"id": 1}])
        client.post_comment(42, "<p>reply</p>")
        self.assertEqual(
            client.calls,
            [
                ("GET", "/tasks/42", None),
                ("GET", "/tasks/42/comments/77", None),
                ("GET", "/tasks/42/comments?order_by=asc&per_page=100", None),
                ("POST", "/tasks/42/comments", {"comment": "<p>reply</p>"}),
            ],
        )


if __name__ == "__main__":
    unittest.main()
