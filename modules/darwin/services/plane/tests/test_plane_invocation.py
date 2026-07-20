from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from plane_invocation import (
    Invocation,
    InvocationKind,
    InvocationOperation,
    InvocationSource,
    parse_comment_invocation,
    select_label_invocation,
)


class TestCommentInvocationParser:
    def test_bare_question_defaults_to_ask(self) -> None:
        invocation = parse_comment_invocation("comment-1", "project-1", "item-1", "@Hermes What does this mean?")
        assert invocation == Invocation(
            trigger_id="comment-1",
            project_id="project-1",
            work_item_id="item-1",
            kind=InvocationKind.COMMENT,
            source=InvocationSource.COMMENT,
            operation=InvocationOperation.ASK,
            body="What does this mean?",
            model_selector=None,
            label_triggered=False,
        )

    def test_legacy_triage_command(self) -> None:
        invocation = parse_comment_invocation("comment-2", "project-1", "item-1", "@Hermes /triage Compare options")
        assert invocation.operation == InvocationOperation.TRIAGE
        assert invocation.body == "Compare options"

    def test_legacy_go_command(self) -> None:
        invocation = parse_comment_invocation("comment-3", "project-1", "item-1", "@Hermes /go Implement this")
        assert invocation.operation == InvocationOperation.GO
        assert invocation.body == "Implement this"

    def test_op_flag_with_ask(self) -> None:
        invocation = parse_comment_invocation("comment-4", "project-1", "item-1", "@Hermes --op ask What is this?")
        assert invocation.operation == InvocationOperation.ASK
        assert invocation.body == "What is this?"

    def test_op_flag_with_triage(self) -> None:
        invocation = parse_comment_invocation("comment-5", "project-1", "item-1", "@Hermes --op triage Evaluate risk")
        assert invocation.operation == InvocationOperation.TRIAGE
        assert invocation.body == "Evaluate risk"

    def test_op_flag_with_go(self) -> None:
        invocation = parse_comment_invocation("comment-6", "project-1", "item-1", "@Hermes --op go Do the work")
        assert invocation.operation == InvocationOperation.GO
        assert invocation.body == "Do the work"

    def test_model_selector(self) -> None:
        invocation = parse_comment_invocation("comment-7", "project-1", "item-1", "@Hermes --op go --model gpt-5.6 Do the work")
        assert invocation.operation == InvocationOperation.GO
        assert invocation.model_selector == "gpt-5.6"
        assert invocation.body == "Do the work"

    def test_model_selector_without_op(self) -> None:
        invocation = parse_comment_invocation("comment-8", "project-1", "item-1", "@Hermes --model gpt-5.6 Ask question")
        assert invocation.operation == InvocationOperation.ASK
        assert invocation.model_selector == "gpt-5.6"
        assert invocation.body == "Ask question"

    def test_flags_after_body_are_ignored_as_text(self) -> None:
        invocation = parse_comment_invocation("comment-9", "project-1", "item-1", "@Hermes Implement --model gpt-5.6 the feature")
        assert invocation.operation == InvocationOperation.ASK
        assert invocation.model_selector is None
        assert invocation.body == "Implement --model gpt-5.6 the feature"

    def test_flag_value_not_first_token_is_ignored_as_text(self) -> None:
        invocation = parse_comment_invocation("c", "p", "w", "@Hermes body --op go")
        assert invocation.operation == InvocationOperation.ASK
        assert invocation.model_selector is None
        assert invocation.body == "body --op go"

    def test_quoted_model_selector(self) -> None:
        invocation = parse_comment_invocation("comment-10", "project-1", "item-1", '@Hermes --op go --model "gpt-5.6" Work on it')
        assert invocation.model_selector == "gpt-5.6"
        assert invocation.body == "Work on it"

    def test_non_leading_mention_returns_none(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "Please @Hermes help") is None

    def test_empty_body_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes") is None

    def test_bare_command_without_context_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes /go") is None
        assert parse_comment_invocation("c", "p", "w", "@Hermes /triage") is None

    def test_unknown_command_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes /skill something") is None

    def test_unknown_flag_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes --unknown flag body") is None

    def test_duplicate_op_flag_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes --op go --op triage body") is None

    def test_duplicate_model_flag_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes --model a --model b body") is None

    def test_missing_flag_value_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", "@Hermes --op") is None
        assert parse_comment_invocation("c", "p", "w", "@Hermes --model") is None

    def test_malformed_quoting_is_invalid(self) -> None:
        assert parse_comment_invocation("c", "p", "w", '@Hermes --op go "unterminated') is None

    def test_case_insensitive_mention(self) -> None:
        invocation = parse_comment_invocation("c", "p", "w", "@HERMES /go Implement")
        assert invocation.operation == InvocationOperation.GO

    def test_case_insensitive_op_values(self) -> None:
        invocation = parse_comment_invocation("c", "p", "w", "@Hermes --OP Go --MODEL gpt-5.6 Work")
        assert invocation.operation == InvocationOperation.GO
        assert invocation.model_selector == "gpt-5.6"

    def test_html_wrapping(self) -> None:
        invocation = parse_comment_invocation("c", "p", "w", "<p>@Hermes --op triage Check this</p>")
        assert invocation.operation == InvocationOperation.TRIAGE
        assert invocation.body == "Check this"


class TestLabelInvocationParser:
    def test_go_label(self) -> None:
        invocation = select_label_invocation("delivery-1", "project-1", "item-1", ["hermes:go"])
        assert invocation == Invocation(
            trigger_id="delivery-1",
            project_id="project-1",
            work_item_id="item-1",
            kind=InvocationKind.LABEL,
            source=InvocationSource.LABEL,
            operation=InvocationOperation.GO,
            body="",
            model_selector=None,
            label_triggered=True,
        )

    def test_triage_label(self) -> None:
        invocation = select_label_invocation("delivery-2", "project-1", "item-1", ["hermes:triage"])
        assert invocation.operation == InvocationOperation.TRIAGE
        assert invocation.label_triggered is True

    def test_triage_wins_over_go(self) -> None:
        invocation = select_label_invocation("delivery-3", "project-1", "item-1", ["hermes:go", "hermes:triage"])
        assert invocation.operation == InvocationOperation.TRIAGE

    def test_unknown_labels_return_none(self) -> None:
        assert select_label_invocation("d", "p", "w", ["hermes:review"]) is None
        assert select_label_invocation("d", "p", "w", []) is None

    def test_case_insensitive_labels(self) -> None:
        invocation = select_label_invocation("d", "p", "w", ["HERMES:GO"])
        assert invocation.operation == InvocationOperation.GO


if __name__ == "__main__":
    for cls in [TestCommentInvocationParser, TestLabelInvocationParser]:
        instance = cls()
        for name in dir(instance):
            if name.startswith("test_"):
                getattr(instance, name)()
                print(f"OK {cls.__name__}.{name}")
    print("all_plane_invocation_tests_passed")
