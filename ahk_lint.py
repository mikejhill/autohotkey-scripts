#!/usr/bin/env python3
"""Flexible linter for AutoHotkey v2 scripts.

Rules are implemented in separate modules within the ``lint`` package.  By
default all available rules are applied, but a subset can be selected via the
``--rules`` argument or a file containing rule names can be provided with
``--rule-file``.
"""

from __future__ import annotations

import argparse
import importlib
import pathlib
import sys
from typing import Iterable


ROOT = pathlib.Path(__file__).resolve().parent
AHK_DIR = ROOT / "scripts"
RULE_DIR = ROOT / "lint"
RULE_PREFIX = "rule_"


def _iter_rule_names_from_file(path: pathlib.Path) -> Iterable[str]:
    """Yield rule names from ``path``.

    Empty lines and comments starting with ``#`` are ignored.
    """

    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            yield line


def _load_rules(rule_names: list[str]) -> list:
    """Import rule modules for the given ``rule_names``."""

    modules = []
    for name in rule_names:
        module_name = f"lint.{RULE_PREFIX}{name}"
        try:
            module = importlib.import_module(module_name)
        except ModuleNotFoundError:
            print(f"Unknown rule: {name}", file=sys.stderr)
            sys.exit(2)
        if not hasattr(module, "check"):
            print(f"Rule {name} does not define a check() function", file=sys.stderr)
            sys.exit(2)
        modules.append(module)
    return modules


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Linter for AutoHotkey scripts")
    parser.add_argument(
        "--rules",
        nargs="*",
        default=[],
        help="Names of rules to apply (without the 'rule_' prefix)",
    )
    parser.add_argument(
        "--rule-file",
        type=pathlib.Path,
        help="File containing rule names (one per line)",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()

    rule_names: list[str] = []
    if args.rule_file:
        rule_names.extend(_iter_rule_names_from_file(args.rule_file))
    rule_names.extend(args.rules)

    if not rule_names:
        rule_names = [p.stem[len(RULE_PREFIX) :] for p in RULE_DIR.glob(f"{RULE_PREFIX}*.py")]

    # Remove duplicates while preserving order
    seen: set[str] = set()
    rule_names = [n for n in rule_names if not (n in seen or seen.add(n))]

    rules = _load_rules(rule_names)

    ok = True
    for path in sorted(AHK_DIR.rglob("*.ahk")):
        rel = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        for rule in rules:
            for message in rule.check(path, rel, text, lines):
                print(message)
                ok = False

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()

