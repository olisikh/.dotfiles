"""Lightweight Plane REST client for the automation controller.

The controller uses this module for all Plane reads and writes. It intentionally
has no business logic; mutation decisions live in plane_controller.py.
"""
from __future__ import annotations

import json
import urllib.error
from typing import Any
from urllib.request import Request, urlopen


class PlaneClient:
    def __init__(self, *, base_url: str, workspace_slug: str, api_key: str) -> None:
        self._base = base_url.rstrip("/")
        self._workspace = workspace_slug
        self._api_key = api_key

    def _url(self, path: str) -> str:
        return f"{self._base}/api/v1/workspaces/{self._workspace}{path}"

    def _request(
        self,
        method: str,
        path: str,
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        data = json.dumps(payload, separators=(",", ":")).encode("utf-8") if payload is not None else None
        headers = {
            "X-Api-Key": self._api_key,
            "Content-Type": "application/json",
        }
        req = Request(
            self._url(path),
            data=data,
            headers=headers,
            method=method,
        )
        try:
            with urlopen(req, timeout=30) as response:
                if response.status == 204:
                    return {}
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            raise PlaneClientError(
                method=method,
                path=path,
                status=exc.code,
                body=body,
            ) from exc

    def get_work_item(self, project_id: str, work_item_id: str) -> dict[str, Any]:
        return self._request("GET", f"/projects/{project_id}/issues/{work_item_id}/")

    def get_comment(self, project_id: str, work_item_id: str, comment_id: str) -> dict[str, Any]:
        return self._request(
            "GET", f"/projects/{project_id}/issues/{work_item_id}/comments/{comment_id}/"
        )

    def update_work_item(
        self,
        project_id: str,
        work_item_id: str,
        *,
        assignees: list[str] | None = None,
        labels: list[str] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, list[str]] = {}
        if assignees is not None:
            payload["assignees"] = assignees
        if labels is not None:
            payload["labels"] = labels
        if not payload:
            raise ValueError("update_work_item requires assignees or labels")
        return self._request("PATCH", f"/projects/{project_id}/issues/{work_item_id}/", payload)

    def create_comment(
        self,
        project_id: str,
        work_item_id: str,
        comment_html: str,
        *,
        external_source: str | None = None,
        external_id: str | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {"comment_html": comment_html, "access": "INTERNAL"}
        if external_source is not None:
            payload["external_source"] = external_source
        if external_id is not None:
            payload["external_id"] = external_id
        return self._request(
            "POST",
            f"/projects/{project_id}/issues/{work_item_id}/comments/",
            payload,
        )

    def update_comment(
        self,
        project_id: str,
        work_item_id: str,
        comment_id: str,
        comment_html: str,
    ) -> dict[str, Any]:
        return self._request(
            "PATCH",
            f"/projects/{project_id}/issues/{work_item_id}/comments/{comment_id}/",
            {"comment_html": comment_html, "access": "INTERNAL"},
        )

    def delete_comment(self, project_id: str, work_item_id: str, comment_id: str) -> None:
        try:
            self._request(
                "DELETE", f"/projects/{project_id}/issues/{work_item_id}/comments/{comment_id}/"
            )
        except PlaneClientError as exc:
            if exc.status != 404:
                raise


class PlaneClientError(Exception):
    def __init__(
        self,
        *,
        method: str,
        path: str,
        status: int,
        body: str,
    ) -> None:
        super().__init__(f"Plane {method} {path} failed ({status}): {body[:200]}")
        self.method = method
        self.path = path
        self.status = status
        self.body = body
