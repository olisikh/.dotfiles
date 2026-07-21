#!/usr/bin/env python3
"""Pure, side-effect-free grammar and normalization for Plane Hermes triggers.

This module owns the strict parsing of `@Hermes` comments and the canonical
selection of supported `hermes:*` labels. It produces a single immutable
`Invocation` shape that the controller can persist and act on without any
further LLM reasoning about trigger intent.
"""
from __future__ import annotations

import re
import shlex
from dataclasses import dataclass, field
from enum import Enum
from html.parser import HTMLParser


class InvocationKind(str, Enum):
    COMMENT = "comment"
    LABEL = "label"


class InvocationOperation(str, Enum):
    ASK = "ask"
    TRIAGE = "triage"
    GO = "go"


class InvocationSource(str, Enum):
    COMMENT = "comment"
    LABEL = "label"


@dataclass(frozen=True, slots=True)
class Invocation:
    """Normalized trigger ready for the controller to persist and execute."""

    trigger_id: str
    project_id: str
    work_item_id: str
    kind: InvocationKind
    source: InvocationSource
    operation: InvocationOperation
    body: str
    model_selector: str | None = None
    reasoning_effort: str | None = None
    label_triggered: bool = False


@dataclass(frozen=True, slots=True)
class InvocationError:
    """Typed user-facing parse error — the controller posts one deterministic
    help comment for any of these reasons instead of silently ignoring."""

    reason: str
    detail: str = ""


KNOWN_LABELS = ("hermes:triage", "hermes:go")
VALID_REASONING_EFFORTS = frozenset({"minimal", "low", "medium", "high", "xhigh", "max", "ultra"})


class _CommentTextExtractor(HTMLParser):
    _BLOCK_TAGS = frozenset({"blockquote", "br", "div", "li", "p"})

    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        self.parts.append(data)

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() == "br":
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in self._BLOCK_TAGS:
            self.parts.append("\n")


def parse_comment_invocation(
    trigger_id: str,
    project_id: str,
    work_item_id: str,
    comment_html: str,
) -> Invocation | InvocationError | None:
    """Parse a leading ``@Hermes`` comment into a normalized invocation.

    Returns ``None`` only when the text is not a Hermes invocation at all
    (non-leading mention). Returns a typed ``InvocationError`` for any
    leading-mention text that is malformed, so the controller can post one
    deterministic help comment instead of silently swallowing user intent.
    """
    extractor = _CommentTextExtractor()
    extractor.feed(comment_html)
    text = "".join(extractor.parts).strip()
    match = re.fullmatch(r"@hermes(?:\s+(.*))?", text, flags=re.IGNORECASE | re.DOTALL)
    if match is None:
        return None
    context = (match.group(1) or "").strip()
    if not context:
        return InvocationError("empty_body")
    try:
        tokens = shlex.split(context, posix=True)
    except ValueError:
        return InvocationError("malformed_quoting")
    if not tokens:
        return InvocationError("empty_body")

    operation = InvocationOperation.ASK
    model_selector: str | None = None
    reasoning_effort: str | None = None
    i = 0
    flags_seen: set[str] = set()

    while i < len(tokens):
        token = tokens[i]
        if not token.startswith("--"):
            break
        flag_name = token[2:].lower()
        if flag_name in flags_seen:
            return InvocationError("duplicate_flag", flag_name)
        if flag_name not in {"op", "model", "variant"}:
            return InvocationError("unknown_flag", flag_name)
        flags_seen.add(flag_name)
        if i + 1 >= len(tokens):
            return InvocationError("missing_flag_value", flag_name)
        value = tokens[i + 1]
        if flag_name == "op":
            try:
                operation = InvocationOperation(value.lower())
            except ValueError:
                return InvocationError("invalid_op_value", value)
        elif flag_name == "model":
            model_selector = value
        else:
            normalized_effort = value.lower()
            if normalized_effort not in VALID_REASONING_EFFORTS:
                return InvocationError("invalid_variant", value)
            reasoning_effort = normalized_effort
        i += 2

    if flags_seen and i == len(tokens):
        return InvocationError("empty_body")

    remaining = " ".join(tokens[i:]).strip()
    if not remaining:
        return InvocationError("empty_body")

    if remaining.startswith("/"):
        command, *trailing = remaining.split(None, 1)
        mode = command[1:].lower()
        if mode in {"go", "triage"} and trailing:
            operation = InvocationOperation(mode)
            body = trailing[0].strip()
        elif mode in {"go", "triage"}:
            return InvocationError("empty_body")
        else:
            return InvocationError("unknown_command", command)
    else:
        body = remaining

    if not body:
        return InvocationError("empty_body")

    return Invocation(
        trigger_id=trigger_id,
        project_id=project_id,
        work_item_id=work_item_id,
        kind=InvocationKind.COMMENT,
        source=InvocationSource.COMMENT,
        operation=operation,
        body=body,
        model_selector=model_selector,
        reasoning_effort=reasoning_effort,
        label_triggered=False,
    )


def select_label_invocation(
    delivery_id: str,
    project_id: str,
    work_item_id: str,
    labels: list[str],
) -> Invocation | None:
    """Return the highest-priority supported label as a normalized invocation."""
    normalized = {label.strip().lower() for label in labels}
    selected = next((label for label in KNOWN_LABELS if label in normalized), None)
    if selected is None:
        return None
    operation = InvocationOperation.GO if selected == "hermes:go" else InvocationOperation.TRIAGE
    return Invocation(
        trigger_id=delivery_id,
        project_id=project_id,
        work_item_id=work_item_id,
        kind=InvocationKind.LABEL,
        source=InvocationSource.LABEL,
        operation=operation,
        body="",
        model_selector=None,
        label_triggered=True,
    )
