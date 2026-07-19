from __future__ import annotations

import hashlib
import hmac
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))


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

    def test_rejects_non_issue_or_incomplete_events(self) -> None:
        from plane_dispatcher import extract_work_item_ref

        self.assertIsNone(extract_work_item_ref({"event": "issue_comment", "data": {}}))
        self.assertIsNone(extract_work_item_ref({"event": "issue", "data": {"id": "x"}}))


class DeliveryQueueTests(unittest.TestCase):
    def test_deduplicates_plane_delivery_ids(self) -> None:
        from plane_dispatcher import DeliveryQueue

        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        self.assertTrue(queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1"))
        self.assertFalse(queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1"))
        self.assertEqual(queue.pending(), [("delivery-1", "project-1", "item-1", "PERSONAL-1")])

    def test_claim_pending_makes_a_delivery_invisible_to_another_consumer(self) -> None:
        from plane_dispatcher import DeliveryQueue

        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1")

        self.assertEqual(queue.claim_pending(), [("delivery-1", "project-1", "item-1", "PERSONAL-1")])
        self.assertEqual(queue.claim_pending(), [])

    def test_finish_marks_a_claimed_delivery_as_dispatched(self) -> None:
        from plane_dispatcher import DeliveryQueue

        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        queue.enqueue("delivery-1", "project-1", "item-1", "PERSONAL-1")
        queue.claim_pending()

        queue.finish("delivery-1")

        self.assertEqual(queue.pending(), [])
        self.assertEqual(queue.claim_pending(), [])


class DeliveryIngestionTests(unittest.TestCase):
    def test_accepts_valid_signed_issue_delivery_once(self) -> None:
        import json
        from plane_dispatcher import DeliveryQueue, ingest_plane_delivery

        body = json.dumps(
            {
                "event": "issue",
                "data": {"id": "item-1", "project_id": "project-1", "identifier": "PERSONAL-1"},
            }
        ).encode()
        secret = "secret"
        signature = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)

        self.assertTrue(
            ingest_plane_delivery(
                queue,
                secret,
                {"X-Plane-Delivery": "delivery-1", "X-Plane-Signature": signature},
                body,
            )
        )
        self.assertFalse(
            ingest_plane_delivery(
                queue,
                secret,
                {"X-Plane-Delivery": "delivery-1", "X-Plane-Signature": signature},
                body,
            )
        )

    def test_rejects_unsigned_or_non_issue_delivery(self) -> None:
        import json
        from plane_dispatcher import DeliveryQueue, ingest_plane_delivery

        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        self.assertFalse(ingest_plane_delivery(queue, "secret", {}, b"{}"))
        body = json.dumps({"event": "issue_comment", "data": {}}).encode()
        signature = hmac.new(b"secret", body, hashlib.sha256).hexdigest()
        self.assertFalse(
            ingest_plane_delivery(
                queue,
                "secret",
                {"X-Plane-Delivery": "delivery-2", "X-Plane-Signature": signature},
                body,
            )
        )


class DispatchHttpHandlerTests(unittest.TestCase):
    def test_accepts_only_a_valid_post_to_the_dispatch_path(self) -> None:
        import http.client
        import json
        import threading
        from http.server import ThreadingHTTPServer
        from plane_dispatcher import DeliveryQueue, make_dispatch_handler

        secret = "secret"
        queue = DeliveryQueue(":memory:")
        self.addCleanup(queue.close)
        server = ThreadingHTTPServer(("127.0.0.1", 0), make_dispatch_handler(queue, secret))
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
