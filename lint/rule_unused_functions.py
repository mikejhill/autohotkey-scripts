"""Warn about functions defined but never called within the same file."""

from __future__ import annotations

import re
from typing import Iterable

# Match a simple function definition like `MyFunc(param) {`
func_def_re = re.compile(r"^\s*([A-Za-z_][\w]*)\s*\([^)]*\)\s*{")


def _strip_comments(lines: list[str]) -> str:
    """Return text with comments removed."""
    cleaned = []
    for line in lines:
        cleaned.append(line.split(";", 1)[0])
    return "\n".join(cleaned)


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    defined: list[tuple[str, int]] = []
    for i, line in enumerate(lines, 1):
        m = func_def_re.match(line)
        if m:
            defined.append((m.group(1), i))

    if not defined:
        return

    body = _strip_comments(lines)

    for name, line_no in defined:
        occurrences = len(re.findall(rf"\b{name}\s*\(", body))
        if occurrences <= 1:
            yield f"{rel}:{line_no}: function '{name}' defined but not used"

