#!/usr/bin/env python3
"""Simple linter for AutoHotkey v2 scripts."""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent
AHK_DIR = ROOT / 'scripts'

pattern = re.compile(r"^#Requires\s+AutoHotkey\s+v2", re.IGNORECASE)

ok = True
for path in sorted(AHK_DIR.rglob('*.ahk')):
    rel = path.relative_to(ROOT)
    text = path.read_text(encoding='utf-8')
    lines = text.splitlines()

    # Directive must be the very first line (allow a UTF-8 BOM)
    first_line = lines[0].lstrip('\ufeff') if lines else ''
    if not pattern.match(first_line):
        print(f"{rel}: missing or incorrect #Requires directive on first line")
        ok = False

    if text and not text.endswith('\n'):
        print(f"{rel}: missing trailing newline")
        ok = False

    for i, line in enumerate(lines, 1):
        if line.rstrip() != line:
            print(f"{rel}:{i}: trailing whitespace")
            ok = False

if not ok:
    sys.exit(1)
