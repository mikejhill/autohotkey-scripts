"""Flag lines that contain trailing whitespace."""

from __future__ import annotations

from typing import Iterable


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    for i, line in enumerate(lines, 1):
        if line.rstrip() != line:
            yield f"{rel}:{i}: trailing whitespace"

