#!/usr/bin/env python3
"""Module 12 capstone grader -- 15/25/20/20/20 with non-negotiable hard gates.

Automatic points come from commands actually run against the submission.  The
learning outcomes that need human judgement (impact investigation, change
boundary, test evidence, incident recovery, and "investigation precedes
modification") are NEVER auto-passed: an empty or unfilled template scores
zero, and such items are reported as "PENDING manual review" until a human
reviewer signs them off.

  grade.py [--submission DIR] [--signoff FILE]

Result and exit code:
  FAIL     an automatic gate failed, or a required deliverable is missing /
           empty / an unfilled template                     (exit 1)
  PENDING  automatic gates pass but the manual learning outcomes have not
           been signed off by a human reviewer              (exit 0)
  PASS     automatic gates pass AND every manual outcome is signed off
                                                           (exit 0)

The reference materials ship a signoff; a student submission does not, so a
green self-test of the answer key is NOT a student graduation.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

GRADING = Path(__file__).resolve().parent
REPO = GRADING.parents[3]
DEFAULT_SUBMISSION = REPO / "curriculum/modules/12-capstone"
DEFAULT_SIGNOFF = GRADING / "manual-review-signoff.md"
SIGNOFF_TOKEN = "MANUAL-REVIEW-SIGNOFF"

MAINTENANCE_FILES = [
    "maintenance/README.md", "maintenance/impact-investigation.md",
    "maintenance/change-list.md", "maintenance/change-policy.md",
    "maintenance/test-cases.md", "maintenance/evidence-plan.md",
    "maintenance/copybooks/CAP-CUSTOMER-FEED-V2.CPY",
    "maintenance/regression/red-green.sh",
]

# Learning outcomes that cannot be proven correct by a script: presence plus
# substance is required, and each still needs a reviewer's signoff.
MANUAL_ITEMS = [
    "maintenance/impact-investigation.md",
    "maintenance/change-list.md",
    "maintenance/change-policy.md",
    "maintenance/test-cases.md",
    "maintenance/evidence-plan.md",
    "evidence/README.md",
    "COMPOSITION.md",
]

PLACEHOLDERS = ("TODO", "TBD", "待填", "XXX", "<fill", "FILLME", "____",
                "占位", "placeholder")


def run(command: list[str], cwd: Path | None = None):
    return subprocess.run(command, text=True, capture_output=True, cwd=cwd)


def substantive(path: Path) -> bool:
    """True only for a file with real content: not empty, not a heading-only
    or placeholder-only template."""
    if not path.is_file():
        return False
    text = path.read_text(errors="replace")
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped.startswith("<!--"):
            continue
        if any(token in stripped for token in PLACEHOLDERS):
            continue
        if len(stripped) >= 20:
            return True
    return False


def check_maintenance_files(mod: Path) -> tuple[int, list[str], list[str]]:
    missing: list[str] = []
    empty: list[str] = []
    good = 0
    for rel in MAINTENANCE_FILES:
        path = mod / rel
        if not path.exists():
            missing.append(rel)
        elif not substantive(path):
            empty.append(rel)
        else:
            good += 1
    score = round(20 * good / len(MAINTENANCE_FILES))
    return score, missing, empty


def check_composition(mod: Path) -> tuple[bool, list[str]]:
    """R15: the graduation deliverables must include a de-duplicated system
    composition / dependency inventory, not just a raw line count."""
    if not substantive(mod / "COMPOSITION.md"):
        return False, ["COMPOSITION.md missing or unfilled (composition "
                       "inventory / dependency trace required)"]
    return True, []


def check_incident(mod: Path) -> tuple[int, list[str]]:
    notes = []
    score = 0
    incident = mod / "incidents/incident-01"
    materials = [
        "materials/params.txt", "materials/scheduler-state.txt",
        "materials/operator-notes.md", "materials/feed/transaction.dat",
        "materials/logs/nightly.log", "reproduce/reproduce.sh",
    ]
    present = all((incident / f).exists() for f in materials)
    if present:
        score += 8
    else:
        notes.append("incident materials incomplete")
    repro = incident / "reproduce/reproduce.sh"
    if repro.exists():
        result = run(["bash", str(repro), "/tmp/m12-grade-incident"])
        if "reproduce_rc=8" in result.stdout and "published=none" in result.stdout:
            score += 12
        else:
            notes.append("incident not reproducible as a safe failure")
    return score, notes


def parse_copybook(path: Path) -> dict[str, tuple[int, int]]:
    offsets: dict[str, tuple[int, int]] = {}
    cursor = 0
    for line in path.read_text().splitlines():
        parts = line.strip().split()
        if len(parts) >= 3 and parts[0].isdigit() and parts[-2] == "PIC":
            name, pic = parts[1], parts[-1].rstrip(".")
            if pic.startswith("X("):
                length = int(pic[2:-1])
            elif pic == "X":
                length = 1
            else:
                continue
            offsets[name] = (cursor, length)
            cursor += length
    return offsets


def check_byte_layout(mod: Path) -> tuple[int, list[str]]:
    notes: list[str] = []
    score = 0
    # (total width, {field: (offset, length)}) frozen by R08.
    golden = {
        "CUSTOMER-V1.CPY": (27, {"CV1-CUSTOMER-STATUS": (26, 1)}),
        "CAP-CUSTOMER-FEED-V1.CPY": (31, {"EC1-RECORD-STATUS": (26, 1),
                                          "EC1-CUSTOMER-CLASSIFICATION": (27, 1),
                                          "EC1-LAYOUT-VERSION": (28, 3)}),
        "CAP-CUSTOMER-FEED-V2.CPY": (32, {"EC2-RECORD-STATUS": (26, 1),
                                          "EC2-CUSTOMER-CLASSIFICATION": (27, 2),
                                          "EC2-LAYOUT-VERSION": (29, 3)}),
        "ACCOUNT-V1.CPY": (47, {"AC1-OPENING-BALANCE": (22, 13)}),
        "TRANSACTION-V1.CPY": (55, {"TX1-AMOUNT": (41, 13),
                                    "TX1-STATUS": (54, 1)}),
    }
    ok = 0
    for name, (width, fields) in golden.items():
        offsets = parse_copybook(mod / "system/copybooks" / name)
        total = sum(length for _start, length in offsets.values())
        if total != width:
            notes.append(f"{name}: declared width {total} != {width}")
            continue
        bad = [f for f, want in fields.items() if offsets.get(f) != want]
        if bad:
            notes.append(f"{name}: field offset/PIC drift {bad}")
            continue
        ok += 1
    score += round(15 * ok / len(golden))
    probe = run(["python3", str(mod / "system/lib/validate.py"), "length",
                 "--tx", str(mod / "fixtures/extension/transaction.dat"),
                 "--customer", str(mod / "fixtures/extension/customer.dat"),
                 "--layout", "v2"])
    if probe.returncode != 0 or "customer_width=32" not in probe.stdout:
        notes.append("byte probe did not confirm the enterprise v2 width")
        score = max(0, score - 5)
    return score, notes


def check_signoff(path: Path) -> bool:
    if not substantive(path):
        return False
    text = path.read_text(errors="replace")
    if SIGNOFF_TOKEN not in text or "G6" not in text:
        return False
    return all(Path(item).name in text for item in MANUAL_ITEMS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--submission", default=str(DEFAULT_SUBMISSION))
    parser.add_argument("--signoff", default=str(DEFAULT_SIGNOFF))
    args = parser.parse_args()
    mod = Path(args.submission).resolve()
    total = 0
    notes: list[str] = []

    # Rubric 2 + 3 (25 + 20) come from the real acceptance run.
    acceptance = run(["python3", str(mod / "scripts/check.py")])
    acceptance_ok = acceptance.returncode == 0 and "PASS: module 12" in acceptance.stdout
    if acceptance_ok:
        total += 25 + 20
    else:
        notes.append("acceptance (scripts/check.py) FAILED: "
                     + acceptance.stdout[-200:] + acceptance.stderr[-200:])

    b1, n1 = check_byte_layout(mod)
    total += b1
    notes += n1

    b4, missing, empty = check_maintenance_files(mod)
    total += max(0, b4)
    notes += [f"missing maintenance file {m}" for m in missing]
    notes += [f"empty/unfilled deliverable (no credit): {e}" for e in empty]

    comp_ok, comp_notes = check_composition(mod)
    notes += comp_notes

    b5, n5 = check_incident(mod)
    total += b5
    notes += n5

    # Automatic hard gates (probed against the release materials).
    gates: dict[str, bool] = {}
    redgreen = run(["bash", str(mod / "maintenance/regression/red-green.sh"),
                    "/tmp/m12-grade-rg"])
    gates["G4 version compatibility evidence"] = (
        redgreen.returncode == 0 and "GREEN=0" in redgreen.stdout
        and "RED=" in redgreen.stdout)
    gates["G1 no double debit"] = acceptance_ok
    gates["G2 amounts/counts reconcile"] = acceptance_ok
    gates["G3 failure publishes nothing"] = acceptance_ok
    gates["G5 incident root cause reproducible"] = b5 >= 20

    # G6 (investigation precedes modification) is a process outcome: a
    # reviewable, substantive record must exist, but ordering and quality are
    # a human call.  Never auto-PASS.
    investigation = mod / "maintenance/impact-investigation.md"
    evidence = mod / "evidence/README.md"
    gates["G6 investigation precedes modification"] = \
        substantive(investigation) and substantive(evidence)

    deliverables_ok = not missing and not empty and comp_ok
    auto_ok = acceptance_ok and all(gates.values()) and deliverables_ok

    signoff = Path(args.signoff)
    signoff_ok = check_signoff(signoff)

    print("=== module 12 capstone grade ===")
    print(f"submission: {mod}")
    print(f"rubric total: {total}/100 (threshold 80)")
    print("automatic hard gates:")
    for name, ok in gates.items():
        label = "PASS" if ok else "FAIL"
        if name.startswith("G6") and ok:
            label = "PASS(substance)/PENDING(manual)"
        print(f"  [{label}] {name}")
    print("manual-review learning outcomes (never auto-PASS):")
    for item in MANUAL_ITEMS:
        state = "substantive" if substantive(mod / item) else "EMPTY/UNFILLED"
        print(f"  [{state}] {item} -> requires human review")
    for note in notes:
        print(f"  note: {note}")

    if not auto_ok or total < 80:
        print(f"signoff: {'present' if signoff_ok else 'absent'} ({signoff})")
        print("RESULT: FAIL")
        return 1
    if signoff_ok:
        print(f"signoff: present ({signoff})")
        print("RESULT: PASS")
        return 0
    print(f"signoff: absent ({signoff})")
    print("RESULT: PENDING manual review (automatic checks pass; a green "
          "self-test is not a graduation)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
