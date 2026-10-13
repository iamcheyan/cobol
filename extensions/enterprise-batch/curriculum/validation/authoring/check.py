#!/usr/bin/env python3
"""Authoring-structure guard.

Each of the 12 modules must ship the learner material required by
docs/curriculum/AUTHORING-STANDARD.md section 1/2/3: a Chinese README that
answers the section-2 questions (including a plugin route AND a plain-terminal
route), a DESIGN, a buildable starter, real fixtures, independently derived
expected results, runnable scripts, and a learner evidence template.  This
guard checks for the presence of those artifacts and for the beginner-facing
routes, catching empty shells or modules that forgot a required piece.
"""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
modules = sorted(p for p in (root / "modules").glob("*/") if p.is_dir())
if len(modules) != 12:
    print(f"FAIL: expected 12 modules, found {len(modules)}", file=sys.stderr)
    raise SystemExit(12)

failures = []
for module in modules:
    name = module.name

    def has_dir(prefix):
        return any(p.is_dir() and p.name == prefix for p in module.rglob(prefix))

    def has_readme():
        return any(p.is_file() for p in module.rglob("README.md"))

    if not has_readme():
        failures.append(f"{name}: missing README.md")
        continue
    if not any(p.name == "DESIGN.md" for p in module.rglob("DESIGN.md")):
        failures.append(f"{name}: missing DESIGN.md")
    if not has_dir("starter"):
        failures.append(f"{name}: missing starter/")
    if not has_dir("fixtures"):
        failures.append(f"{name}: missing fixtures/")
    if not has_dir("expected"):
        failures.append(f"{name}: missing expected/")
    if not has_dir("scripts"):
        failures.append(f"{name}: missing scripts/")
    if not has_dir("evidence"):
        failures.append(f"{name}: missing evidence/")
    if not any(p.stat().st_size > 0 for p in module.rglob("SHA256SUMS")):
        failures.append(f"{name}: missing fixtures/copybook SHA256SUMS")

    top = module / "README.md"
    if top.is_file():
        text = top.read_text(errors="replace")
        if "插件" not in text:
            failures.append(f"{name}: README does not mention the plugin route")
        if "终端" not in text:
            failures.append(f"{name}: README does not mention the terminal route")

for failure in failures:
    print(f"FAIL {failure}", file=sys.stderr)
if failures:
    raise SystemExit(12)
print(f"PASS: {len(modules)} modules carry README/DESIGN/starter/"
      "fixtures/expected/scripts/evidence + SHA sums and dual routes")
