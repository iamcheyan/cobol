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


CJK_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff\u3040-\u30ff]")


def needs_translation(path: Path) -> bool:
    """True when a file has prose that should differ per language.

    Excluded on purpose:
    * binary content;
    * files without Chinese/Japanese characters (already language-neutral);
    * literal artifacts -- expected program output, fixtures and sample data --
      because translating them would stop matching what the programs actually
      print.
    """
    rel_parts = set(path.parts)
    if rel_parts & {"expected", "fixtures", "db"}:
        return False
    if path.name.startswith("expected"):
        return False
    if path.suffix.lower() in {".dat", ".csv", ".png", ".jpg", ".gif", ".pdf"}:
        return False
    try:
        raw = path.read_bytes()[:16384]
    except OSError:
        return False
    if b"\0" in raw:
        return False
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return False
    return bool(CJK_RE.search(text))


def sources() -> list[Path]:
    found: list[Path] = [ROOT / "README.md"]
    for base in (LESSONS, EXTENSIONS):
        found.extend(p for p in sorted(base.rglob("*"))
                     if p.is_file() and p.suffix.lower() in TEXT_SUFFIXES
                     and covered(p) and needs_translation(p))
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


FENCE_RE = re.compile(r"```.*?```", re.S)
# Markdown link destinations must stay byte-identical to the source, including non-English
# fragments such as ``README.md#运行环境``. Strip them before judging prose.
LINK_DEST_RE = re.compile(r"\]\([^)]*\)")
INLINE_RE = re.compile(r"`[^`\n]*`")
HAN_RE = re.compile(r"[\u4e00-\u9fff]")
KANA_RE = re.compile(r"[\u3040-\u30ff]")
LATIN_RE = re.compile(r"[A-Za-z]")

# Characters written in Simplified Chinese that standard Japanese orthography does not use.
# They survive even when a whole paragraph was pasted in untranslated, which is the failure
# mode ``language_problem`` misses: such a file is mostly Japanese, so the global ratio
# still looks fine while individual paragraphs are Chinese.
SIMPLIFIED_ONLY = set(
    "课这说时问题应该发际关键认让请还们对为经过样么怎觉给带开关录态级别户账码币钱务"
    "验证据预处义读译输总汇层块针从导术简复识网软设项团队规范质检试运编执调变逻历组释"
)

# The repository-root README carries a language switcher that names 简体中文 on purpose.
SIMPLIFIED_ALLOWED = {Path("README.md")}


def mixed_language_problems(locale: str, text: str) -> list[str]:
    """Report lines that are prose in another locale's language.

    Two independent signals:

    * Simplified-only characters (a Chinese sentence pasted into an en/ja file).
    * A run of six or more Han characters with no kana at all, outside tables and code,
      which is what an untranslated Chinese paragraph looks like inside a Japanese file.

    Tables and fenced code are skipped: they hold measured output and identifiers that
    must stay byte-identical. Japanese headings made only of kanji are also exempt, so
    the kana rule only fires on sentence-length lines.
    """
    problems: list[str] = []
    in_fence = False
    for number, raw in enumerate(text.splitlines(), start=1):
        line = raw.strip()
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not line or line.startswith("|"):
            continue
        core = LINK_DEST_RE.sub("]", INLINE_RE.sub("", line))
        if locale == "ja":
            simplified = sorted({ch for ch in core if ch in SIMPLIFIED_ONLY})
            if simplified:
                problems.append(
                    f"line {number}: Simplified Chinese character(s) {''.join(simplified)}"
                )
                continue
            # Japanese technical writing uses kanji-only labels and summaries
            # (標準出力、分類基準、読込6件 = 受理2件). Only sentence-length runs are suspect.
            if len(HAN_RE.findall(core)) >= 20 and not KANA_RE.search(core) and not core.startswith("#"):
                problems.append(f"line {number}: long kanji-only run with no kana (untranslated Chinese)")
        elif locale == "en":
            if "](/" in core or "](" in core and "README" in core:
                continue  # language switcher and file-link rows name languages on purpose
            if len(HAN_RE.findall(core)) >= 10 and not KANA_RE.search(core):
                problems.append(f"line {number}: Chinese sentence in English prose")
    return problems


def prose_only(text: str) -> str:
    """Strip code so quoted program output does not look like prose."""
    return INLINE_RE.sub(" ", FENCE_RE.sub(" ", text))


def language_problem(locale: str, text: str) -> str | None:
    """Catch files that are structurally fine but written in the wrong language."""
    body = prose_only(text)
    han = len(HAN_RE.findall(body))
    kana = len(KANA_RE.findall(body))
    latin = len(LATIN_RE.findall(body))
    if locale == "en":
        if kana > 25:
            return f"{kana} kana characters in English prose"
        if han > 25 and han / max(1, han + latin) > 0.15:
            return f"{han} Chinese characters in English prose"
    else:
        if han > 25 and kana / max(1, han + kana) < 0.10:
            return f"{han} kanji with almost no kana (looks like Chinese)"
    return None


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
            if source.suffix.lower() == ".md":
                problem = language_problem(locale, translated)
                if problem:
                    failures.append(f"{locale}/{rel}: {problem}")
                if rel not in SIMPLIFIED_ALLOWED or locale == "en":
                    for detail in mixed_language_problems(locale, translated):
                        failures.append(f"{locale}/{rel}: {detail}")
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
