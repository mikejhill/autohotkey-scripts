"""Check that each script ends with a newline."""

from __future__ import annotations

from typing import Iterable


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    if text and not text.endswith("\n"):
        yield f"{rel}: missing trailing newline"

