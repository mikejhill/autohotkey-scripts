"""Ensure scripts declare the required AutoHotkey version."""

from __future__ import annotations

import re
from typing import Iterable

pattern = re.compile(r"^#Requires\s+AutoHotkey\s+v2", re.IGNORECASE)


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    first_line = lines[0].lstrip("\ufeff") if lines else ""
    if not pattern.match(first_line):
        yield f"{rel}: missing or incorrect #Requires directive on first line"

