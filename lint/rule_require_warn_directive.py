"""Ensure scripts enable the #Warn directive."""

from __future__ import annotations

import re
from typing import Iterable

pattern = re.compile(r"^#Warn\b", re.IGNORECASE)


def check(path, rel, text: str, lines: list[str]) -> Iterable[str]:
    for line in lines:
        if pattern.match(line.strip()):
            return
    yield f"{rel}: missing #Warn directive"

