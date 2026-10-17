#!/usr/bin/env python3
"""Generate localized copies of lesson diagrams from a translation table.

Every lesson figure keeps one canonical English SVG. This tool reads a JSON
table of label translations and writes localized variants next to it:

    lessons/<lesson>/assets/<name>.svg                  (English, canonical)
    lessons/<lesson>/assets/<name>.zh-cn.svg
    lessons/<lesson>/assets/<name>.ja.svg

Usage:
    python3 scripts/diagram_i18n.py --extract   # list untranslated labels
    python3 scripts/diagram_i18n.py --build     # write localized SVGs
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LESSONS = ROOT / "lessons"
EXTENSIONS = ROOT / "extensions"
TABLE = ROOT / "site-src" / "diagram-i18n.json"
LOCALES = ("zh-cn", "ja")

TEXT_RE = re.compile(r"(<text\b[^>]*>)(.*?)(</text>)", re.S)


def figures() -> list[Path]:
    """Canonical English figures (localized variants are skipped)."""
    out = []
    for base in (LESSONS, EXTENSIONS):
        for path in sorted(base.rglob("assets/*.svg")):
            if path.stem.endswith(tuple(f".{loc}" for loc in LOCALES)):
                continue
            out.append(path)
    return out


def labels(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    found = []
    for _open, body, _close in TEXT_RE.findall(text):
        value = body.strip()
        if value:
            found.append(value)
    return found


def load_table() -> dict:
    if TABLE.is_file():
        return json.loads(TABLE.read_text(encoding="utf-8"))
    return {}


def key_for(path: Path) -> str:
    for base in (LESSONS, EXTENSIONS):
        try:
            return path.relative_to(base).as_posix()
        except ValueError:
            continue
    return path.name


def cmd_extract() -> None:
    table = load_table()
    missing = 0
    for path in figures():
        key = key_for(path)
        entry = table.setdefault(key, {})
        for label in labels(path):
            if label not in entry:
                entry[label] = {loc: "" for loc in LOCALES}
                missing += 1
    TABLE.parent.mkdir(parents=True, exist_ok=True)
    TABLE.write_text(json.dumps(table, ensure_ascii=False, indent=2, sort_keys=False) + "\n", encoding="utf-8")
    print(f"{len(figures())} figures, {missing} labels awaiting translation -> {TABLE.relative_to(ROOT)}")


def cmd_build() -> None:
    table = load_table()
    written = 0
    untranslated = 0
    for path in figures():
        key = key_for(path)
        entry = table.get(key, {})
        source = path.read_text(encoding="utf-8")
        for loc in LOCALES:
            def replace(match: re.Match[str]) -> str:
                nonlocal untranslated
                body = match.group(2)
                stripped = body.strip()
                target = entry.get(stripped, {}).get(loc, "")
                if not target:
                    if stripped:
                        untranslated += 1
                    return match.group(0)
                lead = body[: len(body) - len(body.lstrip())]
                trail = body[len(body.rstrip()):]
                return f"{match.group(1)}{lead}{target}{trail}{match.group(3)}"
            localized = TEXT_RE.sub(replace, source)
            out = path.with_name(f"{path.stem}.{loc}.svg")
            out.write_text(localized, encoding="utf-8")
            written += 1
    print(f"wrote {written} localized figures, {untranslated} labels still empty")


def main() -> None:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--extract", action="store_true")
    group.add_argument("--build", action="store_true")
    args = parser.parse_args()
    cmd_extract() if args.extract else cmd_build()


if __name__ == "__main__":
    main()
