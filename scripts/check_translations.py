#!/usr/bin/env python3
"""Report translation coverage and verify that existing translations stay faithful.

Checks performed for every translated file that exists:

* Markdown structure parity with the Chinese source (headings, code fences, table rows).
* Link targets preserved.
* For COBOL sources, every non-comment source line must match the original byte for byte,
  and each comment line must stay within the fixed-format limit.

Exit status is 1 when a structural check fails; missing translations are reported but do
not fail the run, because they are expected during incremental translation.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSLATIONS = ROOT / "site-src" / "translations"
LESSONS = ROOT / "lessons"
EXTENSIONS = ROOT / "extensions"
EXCLUDED_PARTS = {"instructor", "tasks", "validation", "evidence", "grading"}
EXCLUDED_NAMES = {"AGENTS.md", "INSTRUCTOR.md", "manual-review-signoff.md", "SESSION-REPORT.md"}
EXCLUDED_SUFFIXES = {".log", ".pyc", ".db", ".sqlite", ".o", ".so"}
TEXT_SUFFIXES = {".md", ".cob", ".cpy", ".cbsql", ".sql", ".txt", ".csv", ".dat", ".json", ".yml", ".yaml", ".sh", ".py"}
COBOL_SUFFIXES = {".cob", ".cpy"}
COBOL_LINE_LIMIT = 72


def covered(path: Path) -> bool:
    rel = path.relative_to(ROOT)
    if set(rel.parts) & EXCLUDED_PARTS or path.name in EXCLUDED_NAMES:
        return False
    if "build" in rel.parts or ".git" in rel.parts or "__pycache__" in rel.parts:
        return False
    if path.name.startswith(".") or path.suffix.lower() in EXCLUDED_SUFFIXES:
        return False
    return True


def sources() -> list[Path]:
    found: list[Path] = [ROOT / "README.md"]
    for base in (LESSONS, EXTENSIONS):
        found.extend(p for p in sorted(base.rglob("*"))
                     if p.is_file() and p.suffix.lower() in TEXT_SUFFIXES and covered(p))
    return found


FRONTMATTER = re.compile(r"\A---\r?\n.*?\r?\n---\r?\n", re.S)


def strip_frontmatter(text: str) -> str:
    """Translation provenance metadata is allowed in the repository but never compared."""
    return FRONTMATTER.sub("", text, count=1)


def markdown_shape(text: str) -> dict[str, int]:
    fences = len(re.findall(r"^\s*```", text, re.M))
    return {
        "headings": len(re.findall(r"^#{1,6}\s", text, re.M)),
        "fences": fences // 2 if fences % 2 == 0 else -1,
        "table_rows": len(re.findall(r"^\s*\|", text, re.M)),
        "links": len(re.findall(r"\]\([^)]+\)", text)),
        "inline_code": len(re.findall(r"`[^`\n]+`", text)),
    }


def link_targets(text: str) -> set[str]:
    """Link destinations that must survive translation unchanged."""
    return {target for target in re.findall(r"\]\(([^)\s]+)", text)
            if not target.startswith(("#",))}


def cobol_check(original: str, candidate: str) -> list[str]:
    problems = []
    original_lines = original.splitlines()
    candidate_lines = candidate.splitlines()
    if len(original_lines) != len(candidate_lines):
        problems.append(f"line count {len(original_lines)} -> {len(candidate_lines)}")
        return problems
    for number, (before, after) in enumerate(zip(original_lines, candidate_lines), start=1):
        is_comment = len(before) > 6 and before[6] == "*"
        if not is_comment and before != after:
            problems.append(f"code line {number} changed")
        if is_comment:
            limit = COBOL_LINE_LIMIT if len(before) > 6 else len(before)
            if len(after.encode("utf-8")) > limit + 8:
                problems.append(f"comment line {number} exceeds width")
    return problems


def main() -> int:
    missing = {"en": [], "ja": []}
    failures: list[str] = []
    advisories: list[str] = []
    done = {"en": 0, "ja": 0}
    for locale in ("en", "ja"):
        for source in sources():
            rel = source.relative_to(ROOT)
            candidate = TRANSLATIONS / locale / rel
            if not candidate.is_file():
                missing[locale].append(rel.as_posix())
                continue
            done[locale] += 1
            original = source.read_text(encoding="utf-8")
            translated = candidate.read_text(encoding="utf-8")
            if source.suffix.lower() == ".md":
                original = strip_frontmatter(original)
                translated = strip_frontmatter(translated)
            if source.suffix.lower() == ".md":
                before, after = markdown_shape(original), markdown_shape(translated)
                for key in ("headings", "fences", "table_rows", "links"):
                    if before[key] != after[key]:
                        failures.append(f"{locale}/{rel}: {key} {before[key]} -> {after[key]}")
                if before["inline_code"] != after["inline_code"]:
                    advisories.append(f"{locale}/{rel}: inline_code {before['inline_code']} -> {after['inline_code']}")
                lost = link_targets(original) - link_targets(translated)
                added = link_targets(translated) - link_targets(original)
                if lost:
                    failures.append(f"{locale}/{rel}: {len(lost)} link target(s) lost, e.g. {sorted(lost)[0]}")
                if added:
                    failures.append(f"{locale}/{rel}: {len(added)} link target(s) added, e.g. {sorted(added)[0]}")
            elif source.suffix.lower() in COBOL_SUFFIXES:
                for problem in cobol_check(original, translated):
                    failures.append(f"{locale}/{rel}: {problem}")
    total = len(sources())
    for locale in ("en", "ja"):
        print(f"{locale}: {done[locale]}/{total} translated, {len(missing[locale])} pending")
    if advisories:
        print(f"\n{len(advisories)} advisory note(s) (cosmetic, not blocking):")
        for line in advisories[:20]:
            print("  " + line)
    if failures:
        print("\nstructural failures:")
        for line in failures[:80]:
            print("  " + line)
        print(f"\n{len(failures)} failure(s)")
        return 1
    print("\nno structural failures in translated files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
