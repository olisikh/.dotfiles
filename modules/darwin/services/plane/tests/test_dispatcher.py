from __future__ import annotations

import hashlib
import hmac
import sqlite3
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_dispatcher import CooldownMap, DeliveryQueue, ingest_plane_delivery, make_dispatch_handler


class PlaneWebhookValidationTests(unittest.TestCase):
    def test_accepts_the_documented_hex_hmac_signature(self) -> None:
        from plane_dispatcher import verify_plane_signature

        secret = "shared-secret"
        body = b'{"event":"issue","action":"updated"}'
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()

        self.assertTrue(verify_plane_signature(secret, body, signature))

    def test_rejects_a_signature_for_different_content(self) -> None:
        from plane_dispatcher import verify_plane_signature

        secret = "shared-secret"
        signature = hmac.new(secret.encode(), b"different", hashlib.sha256).hexdigest()

        self.assertFalse(verify_plane_signature(secret, b"actual", signature))


class WorkItemReferenceTests(unittest.TestCase):
    def test_extracts_project_and_work_item_ids_from_issue_event(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        payload = {
            "event": "issue",
            "data": {
                "id": "work-item-id",
                "project_id": "project-id",
                "identifier": "PERSONAL-42",
            },
        }

        self.assertEqual(
            extract_work_item_ref(payload),
            ("project-id", "work-item-id", "PERSONAL-42"),
        )

    def test_extracts_plane_v131_issueexpand_project_reference(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        payload = {
            "event": "issue",
            "data": {"id": "work-item-id", "project": "project-id", "sequence_id": 30},
        }

        self.assertEqual(extract_work_item_ref(payload), ("project-id", "work-item-id", ""))

    def test_extracts_project_and_work_item_ids_from_comment_event(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        payload = {
            "event": "issue_comment",
            "data": {"id": "comment-id", "project": "project-id", "issue": "work-item-id"},
        }

        self.assertEqual(extract_work_item_ref(payload), ("project-id", "work-item-id", ""))

    def test_rejects_non_issue_or_incomplete_events(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        self.assertIsNone(extract_work_item_ref({"event": "issue_comment", "data": {}}))
        self.assertIsNone(extract_work_item_ref({"event": "issue", "data": {"id": "x"}}))

    def test_rejects_non_string_event_references(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        self.assertIsNone(
            extract_work_item_ref(
                {"event": "issue", "data": {"id": ["item"], "project": "project"}}
            )
        )
        self.assertIsNone(
            extract_work_item_ref(
                {"event": "issue_comment", "data": {"id": {}, "issue": "item", "project": "project"}}
            )
        )
        self.assertIsNone(extract_work_item_ref({"event": ["issue"], "data": {}}))


class DeliveryQueueTests(unittest.TestCase):
    def test_deduplicates_plane_delivery_ids(self) -> None:
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        self.assertTrue(queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1"))
        self.assertFalse(queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1"))
        self.assertEqual(
            queue.pending(),
            [("delivery-1", "project-1", "item-1", "PERSONAL-1", "issue", "")],
        )

    def test_migrates_legacy_queue_rows_with_comment_defaults(self) -> None:
        with tempfile.NamedTemporaryFile(suffix=".sqlite3") as database_file:
            connection = sqlite3.connect(database_file.name)
            connection.execute(
                """
                CREATE TABLE deliveries (
                  delivery_id TEXT PRIMARY KEY,
                  project_id TEXT NOT NULL,
                  work_item_id TEXT NOT NULL,
                  identifier TEXT NOT NULL,
                  status TEXT NOT NULL DEFAULT 'pending'
                )
                """
            )
            connection.execute(
                "INSERT INTO deliveries (delivery_id, project_id, work_item_id, identifier) VALUES (?, ?, ?, ?)",
                ("legacy-1", "project-1", "item-1", "PERSO-1"),
            )
            connection.commit()
            connection.close()

            queue = DeliveryQueue(database_file.name)
            self.addCleanup(queue.close)
            self.assertEqual(
                queue.pending(),
                [("legacy-1", "project-1", "item-1", "PERSO-1", "issue", "")],
            )

    def test_claim_pending_makes_a_delivery_invisible_to_another_consumer(self) -> None:
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1")

        self.assertEqual(
            queue.claim_pending(),
            [("delivery-1", "project-1", "item-1", "PERSONAL-1", "issue", "")],
        )
        self.assertEqual(queue.claim_pending(), [])

    def test_finish_marks_a_claimed_delivery_as_dispatched(self) -> None:
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1")
        queue.claim_pending()

        queue.finish("delivery-1")

        self.assertEqual(queue.pending(), [])
        self.assertEqual(queue.claim_pending(), [])


class CooldownMapTests(unittest.TestCase):
    def test_allows_first_request_then_rejects_within_cooldown(self) -> None:
        cooldown = CooldownMap(0.2)
        self.assertTrue(cooldown.is_allowed("item-1"))
        self.assertFalse(cooldown.is_allowed("item-1"))

    def test_allows_after_cooldown_expires(self) -> None:
        cooldown = CooldownMap(0.1)
        self.assertTrue(cooldown.is_allowed("item-1"))
        time.sleep(0.12)
        self.assertTrue(cooldown.is_allowed("item-1"))

    def test_tracks_different_keys_independently(self) -> None:
        cooldown = CooldownMap(0.2)
        self.assertTrue(cooldown.is_allowed("item-1"))
        self.assertTrue(cooldown.is_allowed("item-2"))
        self.assertFalse(cooldown.is_allowed("item-1"))


class DeliveryIngestionTests(unittest.TestCase):
    def test_accepts_valid_signed_issue_delivery_once(self) -> None:
        import json

        body = json.dumps(
            {
                "event": "issue",
                "data": {"id": "item-1", "project_id": "project-1", "identifier": "PERSONAL-1"},
            }
        ).encode()
        secret = "secret"
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        queue = DeliveryQueue(":memory:")
        cooldown = CooldownMap(60.0)
        self.addCleanup(queue.close)

        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                secret,
                {"X-Plane-Delivery": "delivery-1", "X-Plane-Signature": signature},
                body,
            ),
            "accepted",
        )
        self.assertEqual(
            ingest_plane_delivery(
                queue,
                CooldownMap(60.0),
                secret,
                {"X-Plane-Delivery": "delivery-1", "X-Plane-Signature": signature},
                body,
            ),
            "rejected",
        )

    def test_accepts_valid_signed_comment_delivery_with_comment_reference(self) -> None:
        import json

        body = json.dumps(
            {
                "event": "issue_comment",
                "data": {"id": "comment-1", "issue": "item-1", "project": "project-1"},
            }
        ).encode()
        secret = "secret"
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)

        self.assertEqual(
            ingest_plane_delivery(
                queue,
                CooldownMap(60.0),
                secret,
                {"X-Plane-Delivery": "delivery-comment-1", "X-Plane-Signature": signature},
                body,
            ),
            "accepted",
        )
        self.assertEqual(
            queue.pending(),
            [("delivery-comment-1", "project-1", "item-1", "", "issue_comment", "comment-1")],
        )

    def test_accepts_comment_after_issue_within_same_ticket_cooldown(self) -> None:
        import json

        secret = "secret"
        queue = DeliveryQueue(":memory:")
        cooldown = CooldownMap(60.0)
        self.addCleanup(queue.close)
        issue_body = json.dumps(
            {"event": "issue", "data": {"id": "item-1", "project_id": "project-1"}}
        ).encode()
        comment_body = json.dumps(
            {
                "event": "issue_comment",
                "data": {"id": "comment-1", "issue": "item-1", "project": "project-1"},
            }
        ).encode()

        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                secret,
                {
                    "X-Plane-Delivery": "delivery-issue-1",
                    "X-Plane-Signature": hmac.new(secret.encode(), issue_body, hashlib.sha256).hexdigest(),
                },
                issue_body,
            ),
            "accepted",
        )
        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                secret,
                {
                    "X-Plane-Delivery": "delivery-comment-1",
                    "X-Plane-Signature": hmac.new(secret.encode(), comment_body, hashlib.sha256).hexdigest(),
                },
                comment_body,
            ),
            "accepted",
        )
        self.assertEqual(len(queue.pending()), 2)

    def test_rejects_unsigned_or_non_issue_delivery(self) -> None:
        import json

        queue = DeliveryQueue(":memory:")
        cooldown = CooldownMap(60.0)
        self.addCleanup(queue.close)
        self.assertEqual(ingest_plane_delivery(queue, cooldown, "secret", {}, b"{}"), "rejected")
        body = json.dumps({"event": "issue_comment", "data": {}}).encode()
        signature = hmac.new(b"secret", body, hashlib.sha256).hexdigest()
        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                "secret",
                {"X-Plane-Delivery": "delivery-2", "X-Plane-Signature": signature},
                body,
            ),
            "rejected",
        )

    def test_rejects_delivery_within_cooldown(self) -> None:
        import json

        body = json.dumps(
            {"event": "issue", "data": {"id": "item-1", "project_id": "project-1"}}
        ).encode()
        secret = "secret"
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        queue = DeliveryQueue(":memory:")
        cooldown = CooldownMap(60.0)
        self.addCleanup(queue.close)

        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                secret,
                {"X-Plane-Delivery": "delivery-1", "X-Plane-Signature": signature},
                body,
            ),
            "accepted",
        )
        self.assertEqual(
            ingest_plane_delivery(
                queue,
                cooldown,
                secret,
                {"X-Plane-Delivery": "delivery-2", "X-Plane-Signature": signature},
                body,
            ),
            "cooldown",
        )


class DispatchHttpHandlerTests(unittest.TestCase):
    def test_accepts_only_a_valid_post_to_the_dispatch_path(self) -> None:
        import http.client
        import json
        import threading
        from http.server import ThreadingHTTPServer

        secret = "secret"
        queue = DeliveryQueue(":memory:")
        cooldown = CooldownMap(60.0)
        self.addCleanup(queue.close)
        server = ThreadingHTTPServer(
            ("127.0.0.1", 0), make_dispatch_handler(queue, cooldown, secret)
        )
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            body = json.dumps(
                {"event": "issue", "data": {"id": "item", "project_id": "project"}}
            ).encode()
            signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
            connection = http.client.HTTPConnection("127.0.0.1", server.server_port)
            connection.request(
                "POST",
                "/plane",
                body,
                {"X-Plane-Delivery": "delivery", "X-Plane-Signature": signature},
            )
            self.assertEqual(connection.getresponse().status, 202)

            connection.request("POST", "/plane", b"{}")
            self.assertEqual(connection.getresponse().status, 401)
            connection.close()
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    unittest.main()
