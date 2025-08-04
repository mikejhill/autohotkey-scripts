"""Ensure scripts declare #SingleInstance Force to prevent duplicates."""

from __future__ import annotations

import re
from typing import Iterable

pattern = re.compile(r"^#SingleInstance\b", re.IGNORECASE)
force_pattern = re.compile(r"^#SingleInstance\s+Force\b", re.IGNORECASE)


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    for line in lines:
        stripped = line.strip()
        if pattern.match(stripped):
            if not force_pattern.match(stripped):
                yield f"{rel}: #SingleInstance should use 'Force'"
            return
    yield f"{rel}: missing #SingleInstance directive"

