"""Trusted model-selector policy for Plane comment invocations."""
from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Mapping

_MODEL_VALUE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:/-]{0,127}$")


@dataclass(frozen=True, slots=True)
class ModelSelectorError(ValueError):
    selector: str
    allowed: tuple[str, ...]

    def __str__(self) -> str:
        choices = ", ".join(self.allowed) or "none"
        return f"unsupported model selector {self.selector!r}; allowed selectors: {choices}"


class ModelSelectorPolicy:
    """Resolve only controller-configured aliases to literal Hermes model IDs."""

    @classmethod
    def from_json(cls, registry_json: str) -> "ModelSelectorPolicy":
        try:
            registry = json.loads(registry_json)
        except json.JSONDecodeError as exc:
            raise ValueError("model selector registry is not valid JSON") from exc
        if not isinstance(registry, dict):
            raise ValueError("model selector registry JSON must be an object")
        return cls(registry)

    def __init__(self, selectors: Mapping[str, str]) -> None:
        normalized: dict[str, str] = {}
        for alias, model in selectors.items():
            if not isinstance(alias, str) or not alias or not isinstance(model, str):
                raise ValueError("model selector registry must contain non-empty string aliases and values")
            if not _MODEL_VALUE.fullmatch(model):
                raise ValueError(f"unsafe model value for selector {alias!r}")
            normalized[alias] = model
        self._selectors = normalized

    def resolve(self, selector: str | None) -> str | None:
        if selector is None:
            return None
        try:
            return self._selectors[selector]
        except KeyError as exc:
            raise ModelSelectorError(selector, tuple(sorted(self._selectors))) from exc
