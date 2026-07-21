"""Tests for validated Plane per-invocation model selector policy."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "dispatcher"))

from model_policy import ModelSelectorError, ModelSelectorPolicy


POLICY = ModelSelectorPolicy({"gpt-5.6": "gpt-5.6-terra", "fast": "gpt-5.6-luna"})


def test_omitted_selector_keeps_normal_hermes_routing() -> None:
    assert POLICY.resolve(None) is None


def test_known_alias_resolves_to_trusted_literal_model() -> None:
    assert POLICY.resolve("fast") == "gpt-5.6-luna"


def test_unknown_selector_is_rejected_without_passthrough() -> None:
    try:
        POLICY.resolve("opencode-go/qwen3.7-max")
    except ModelSelectorError as exc:
        assert exc.selector == "opencode-go/qwen3.7-max"
        assert exc.allowed == ("fast", "gpt-5.6")
    else:
        raise AssertionError("unknown selector was accepted")


def test_registry_rejects_unsafe_literal_model_value() -> None:
    try:
        ModelSelectorPolicy({"unsafe": "gpt-5.6-terra --ignore-rules"})
    except ValueError as exc:
        assert "unsafe model value" in str(exc)
    else:
        raise AssertionError("unsafe registry value was accepted")


def test_policy_loads_registry_from_runtime_json() -> None:
    policy = ModelSelectorPolicy.from_json('{"fast":"gpt-5.6-luna"}')
    assert policy.resolve("fast") == "gpt-5.6-luna"


def test_policy_rejects_non_object_runtime_json() -> None:
    try:
        ModelSelectorPolicy.from_json('["gpt-5.6-terra"]')
    except ValueError as exc:
        assert "object" in str(exc)
    else:
        raise AssertionError("list registry was accepted")


if __name__ == "__main__":
    for name in sorted(globals()):
        if name.startswith("test_"):
            globals()[name]()
            print(f"OK {name}")
    print("all_model_policy_tests_passed")
