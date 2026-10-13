#!/usr/bin/env python3
"""End-to-end acceptance checks for module 11 (incident investigation).

Exercises the frozen incident snapshot: the clean nightly, all incident
fixtures, the no-clobber/lock policy, the buildable starter, the two
RED->GREEN code-gap fixes, and the 11.5 enterprise-customer-class layout
(offsets, PICs and semantic golden bytes).  Assertions come from the
independently accounted expected/ files, never from a course program's
own output.
"""
from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
REPO = MODULE.parents[2]
SYSTEM = MODULE / "system"
RUN = MODULE / "scripts/run.sh"
FIXTURES = MODULE / "fixtures"
EXPECTED = MODULE / "expected"
INSTRUCTOR = REPO / "instructor/modules/11-incidents"
DATE = "20261009"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_kv(path: Path) -> dict[str, str]:
    values = {}
    for line in path.read_text().splitlines():
        key, _, value = line.partition("=")
        values[key] = value
    return values


def run_night(input_dir: Path, output: Path, db: Path, rid: str,
              keep: bool = False, system: Path | None = None,
              env: dict | None = None, cwd: Path | None = None):
    runner = RUN if system is None else system / "scripts/run.sh"
    command = ["bash", str(runner), "--input", str(input_dir),
               "--output", str(output), "--db", str(db),
               "--business-date", DATE, "--run-id", rid]
    if keep:
        command.append("--keep-scene")
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    return subprocess.run(command, text=True, capture_output=True,
                          env=full_env, cwd=cwd)


def verify_manifest(run_dir: Path, rid: str) -> None:
    result = subprocess.run(
        ["python3", str(SYSTEM / "lib/verify_publish.py"),
         "--dir", str(run_dir / "publish" / rid),
         "--run-id", rid, "--business-date", DATE],
        text=True, capture_output=True)
    assert result.returncode == 0, result.stderr


def incident_table() -> dict[str, dict]:
    table = {}
    for line in (EXPECTED / "incidents.txt").read_text().splitlines():
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        table[parts[0]] = {
            "as_found_rc": int(parts[1]), "desired_rc": int(parts[2]),
            "publish_before": parts[3] == "yes", "publish_after": parts[4] == "yes"}
    return table


def check_source_format() -> None:
    sources = list((SYSTEM / "cobol").glob("*.COB")) + \
        list((SYSTEM / "copybooks").glob("*.CPY")) + \
        list((MODULE / "maintenance/copybooks").glob("*.CPY")) + \
        list((MODULE / "starter").glob("*.COB"))
    # Instructor maintenance reference is an authoring artifact (bundle-safe:
    # absent in a student bundle).
    if INSTRUCTOR.is_dir():
        sources += list((INSTRUCTOR / "maintenance").glob("*.COB"))
    assert sources, "no COBOL sources found"
    for source in sources:
        for number, line in enumerate(source.read_text().splitlines(), 1):
            assert line.isascii(), (source, number, "non-ASCII")
            assert len(line) <= 72, (source, number, "beyond column 72")
            assert "\t" not in line, (source, number, "tab")
            if line.strip():
                assert line[:6] == " " * 6, (
                    source, number, "column 1-6 must stay blank")
                assert line[6:7] in (" ", "*", "-", "/"), (
                    source, number, "invalid column 7 indicator")


def check_fixture_manifest() -> None:
    result = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                            cwd=FIXTURES, text=True, capture_output=True)
    assert result.returncode == 0, result.stdout + result.stderr


FIELD_RE = re.compile(r"^\s*05\s+([A-Z0-9-]+)\s+PIC\s+X\((\d+)\)\.\s*$")


def parse_x_copybook(text: str) -> tuple[list[tuple[str, str, int, int]], int]:
    """Independently derive (name, pic, offset, length) from a simple
    copybook of 05-level PIC X(n) fields, and the total 1-based width.
    """
    fields: list[tuple[str, str, int, int]] = []
    offset = 1
    for raw in text.splitlines():
        code = raw.split("*>", 1)[0].rstrip()
        match = FIELD_RE.match(code)
        if not match:
            continue
        name, size = match.group(1), int(match.group(2))
        fields.append((name, f"X({size})", offset, size))
        offset += size
    return fields, offset - 1


def decode_x(fields, record: str) -> dict[str, str]:
    return {name: record[start - 1:start - 1 + length]
            for name, _pic, start, length in fields}


# Golden semantic records (independent of any course program output).
CUSTOMER_V1_GOLDEN = "00000001ALICE     00000100A"          # 27 bytes
ENTERPRISE_CLASS_V1_GOLDEN = "00100000001AALICE     A"      # 23 bytes
ENTERPRISE_CLASS_V2_GOLDEN = "00200000001AALICE     A1"     # 24 bytes


def check_customer_contract() -> None:
    """Byte 27 of the 27-byte CUSTOMER v1 must be the record STATUS; the
    customer classification belongs to the separate, versioned enterprise
    layout and must never be moved onto that byte.  Also verifies field
    offsets, PICs and semantic golden bytes for the enterprise-class lab
    layout (distinct name from canonical ENTERPRISE-CUSTOMER-V1)."""
    # --- 27-byte CUSTOMER v1: last field is the status at byte 27. ---
    cust_fields, cust_width = parse_x_copybook(
        (SYSTEM / "copybooks/CUSTOMER-V1.CPY").read_text())
    assert cust_width == 27, f"CUSTOMER v1 must stay 27 bytes, got {cust_width}"
    assert cust_fields[-1][0] == "CUSTOMER-STATUS", cust_fields[-1]
    assert (cust_fields[-1][2], cust_fields[-1][3]) == (27, 1), cust_fields[-1]
    assert "CUSTOMER-CLASSIFICATION" not in dict(
        (n, p) for n, p, _, _ in cust_fields), "CUSTOMER v1 carries a class"
    canonical_fields, canonical_width = parse_x_copybook(
        (REPO / "curriculum/bank/copybooks/CUSTOMER-V1.CPY").read_text())
    assert canonical_width == 27, canonical_width
    assert canonical_fields[-1][0] == "CUSTOMER-STATUS"
    assert (canonical_fields[-1][2], canonical_fields[-1][3]) == (27, 1)
    assert len(CUSTOMER_V1_GOLDEN) == 27
    decoded = decode_x(cust_fields, CUSTOMER_V1_GOLDEN)
    assert decoded["CUSTOMER-ID"] == "00000001"
    assert decoded["CUSTOMER-NAME"] == "ALICE     "
    assert decoded["CUSTOMER-BALANCE-DEMO"] == "00000100"
    assert CUSTOMER_V1_GOLDEN[26] == "A", "byte 27 must be the status"

    # --- enterprise-class lab layout: distinct name, offsets, PICs. ---
    v1_text = (MODULE / "maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY").read_text()
    v2_text = (MODULE / "maintenance/copybooks/ENTERPRISE-CLASS-V2.CPY").read_text()
    assert "01 ENTERPRISE-CLASS-V1." in v1_text, "v1 must use the distinct name"
    assert "01 ENTERPRISE-CLASS-V2." in v2_text, "v2 must use the distinct name"
    assert "01 ENTERPRISE-CUSTOMER-V" not in v1_text, \
        "lab layout must not reuse the canonical ENTERPRISE-CUSTOMER-V* name"
    expected_v1 = [
        ("LAYOUT-VERSION", "X(3)", 1, 3),
        ("CUSTOMER-ID", "X(8)", 4, 8),
        ("RECORD-STATUS", "X(1)", 12, 1),
        ("CUSTOMER-NAME", "X(10)", 13, 10),
        ("CUSTOMER-CLASSIFICATION", "X(1)", 23, 1),
    ]
    expected_v2 = [
        ("LAYOUT-VERSION", "X(3)", 1, 3),
        ("CUSTOMER-ID", "X(8)", 4, 8),
        ("RECORD-STATUS", "X(1)", 12, 1),
        ("CUSTOMER-NAME", "X(10)", 13, 10),
        ("CUSTOMER-CLASSIFICATION", "X(2)", 23, 2),
    ]
    v1_fields, v1_width = parse_x_copybook(v1_text)
    v2_fields, v2_width = parse_x_copybook(v2_text)
    assert v1_fields == expected_v1 and v1_width == 23, (v1_fields, v1_width)
    assert v2_fields == expected_v2 and v2_width == 24, (v2_fields, v2_width)

    # --- semantic golden bytes (independent decode). ---
    decoded_v1 = decode_x(v1_fields, ENTERPRISE_CLASS_V1_GOLDEN)
    assert decoded_v1 == {
        "LAYOUT-VERSION": "001", "CUSTOMER-ID": "00000001",
        "RECORD-STATUS": "A", "CUSTOMER-NAME": "ALICE     ",
        "CUSTOMER-CLASSIFICATION": "A"}, decoded_v1
    decoded_v2 = decode_x(v2_fields, ENTERPRISE_CLASS_V2_GOLDEN)
    assert decoded_v2 == {
        "LAYOUT-VERSION": "002", "CUSTOMER-ID": "00000001",
        "RECORD-STATUS": "A", "CUSTOMER-NAME": "ALICE     ",
        "CUSTOMER-CLASSIFICATION": "A1"}, decoded_v2

    # --- committed v1 fixture must equal the golden first record. ---
    fixture_v1 = (FIXTURES / "enterprise-customer/customer.v1").read_text(
        ).splitlines()[0]
    assert fixture_v1 == ENTERPRISE_CLASS_V1_GOLDEN, fixture_v1


def check_normal() -> None:
    with tempfile.TemporaryDirectory(prefix="m11-normal-") as temp:
        root = Path(temp)
        before = {p.name: sha256(p) for p in (FIXTURES / "normal").iterdir()
                  if p.is_file()}
        result = run_night(FIXTURES / "normal", root / "out", root / "db", "n")
        assert result.returncode == 0, (result.returncode, result.stderr)
        after = {p.name: sha256(p) for p in (FIXTURES / "normal").iterdir()
                 if p.is_file()}
        assert before == after, "normal run modified its fixture"
        control = read_kv(root / "out/work/control/control.txt")
        expected = read_kv(EXPECTED / "normal.control.txt")
        assert control == expected, (control, expected)
        master = (root / "out/work/closing/master.dat").read_text().splitlines()
        got = {row[:10]: row[21:35] for row in master}
        expected_closing = read_kv(EXPECTED / "normal.closing.txt")
        assert got == expected_closing, (got, expected_closing)
        assert (root / "out/state/complete.marker").is_file()
        assert (root / "out/publish/CURRENT").read_text().strip() == "n"
        verify_manifest(root / "out", "n")
        customer = (root / "out/publish/n/customer-status.txt").read_text()
        assert customer == (EXPECTED / "customer-v1.txt").read_text(), customer
        verified = subprocess.run(
            ["sha256sum", "-c", "MANIFEST.sha256"],
            cwd=root / "out/publish/n", text=True, capture_output=True)
        assert verified.returncode == 0, verified.stderr


def check_incidents() -> None:
    table = incident_table()
    for fixture, want in table.items():
        if fixture == "normal":
            continue
        with tempfile.TemporaryDirectory(prefix="m11-inc-") as temp:
            root = Path(temp)
            before = {p.name: sha256(p) for p in (FIXTURES / fixture).iterdir()
                      if p.is_file()}
            env = None
            if fixture == "INC-2026-005":
                shim = root / "shim"
                shim.mkdir()
                (shim / "mktemp").write_text("#!/bin/sh\nexit 1\n")
                (shim / "mktemp").chmod(0o755)
                env = {"PATH": f"{shim}:{os.environ['PATH']}"}
            result = run_night(FIXTURES / fixture, root / "out", root / "db",
                               "i-" + fixture, keep=True, env=env)
            assert result.returncode == want["as_found_rc"], (
                fixture, result.returncode, result.stderr)
            after = {p.name: sha256(p) for p in (FIXTURES / fixture).iterdir()
                     if p.is_file()}
            assert before == after, f"{fixture}: run modified its fixture"
            published = (root / "out/publish" / ("i-" + fixture)).is_dir()
            assert published == want["publish_before"], (fixture, published)


def check_red_green() -> None:
    table = incident_table()
    with tempfile.TemporaryDirectory(prefix="m11-rg-") as temp:
        root = Path(temp)
        # inc-02: DB unique constraint.
        system = root / "inc02-system"
        shutil.copytree(SYSTEM, system)
        red = run_night(FIXTURES / "INC-2026-002", root / "inc02-red",
                        root / "inc02-red-db", "red02", keep=True, system=system)
        assert red.returncode == table["INC-2026-002"]["as_found_rc"], red.stderr
        assert (root / "inc02-red-db/ledger.dat").read_text().count(
            "A000000000000001") == 2, "RED: duplicate ledger row expected"
        shutil.copy(INSTRUCTOR / "inc-02/fix/db.py", system / "lib/db.py")
        green = run_night(FIXTURES / "INC-2026-002", root / "inc02-green",
                          root / "inc02-green-db", "green02", keep=True,
                          system=system)
        assert green.returncode == table["INC-2026-002"]["desired_rc"], \
            green.stderr
        assert not (root / "inc02-green/publish/green02").exists()
        # inc-06: declared control reconciliation.
        system = root / "inc06-system"
        shutil.copytree(SYSTEM, system)
        red = run_night(FIXTURES / "INC-2026-006", root / "inc06-red",
                        root / "inc06-red-db", "red06", keep=True, system=system)
        assert red.returncode == table["INC-2026-006"]["as_found_rc"], red.stderr
        assert (root / "inc06-red/publish/red06/control-report.txt").is_file(), \
            "RED: as-found published the wrong total"
        shutil.copy(INSTRUCTOR / "inc-06/fix/control.py",
                    system / "lib/control.py")
        green = run_night(FIXTURES / "INC-2026-006", root / "inc06-green",
                          root / "inc06-green-db", "green06", keep=True,
                          system=system)
        assert green.returncode == table["INC-2026-006"]["desired_rc"], \
            green.stderr
        assert not (root / "inc06-green/publish/green06").exists()


def check_no_clobber_and_lock() -> None:
    with tempfile.TemporaryDirectory(prefix="m11-protect-") as temp:
        root = Path(temp)
        foreign = root / "foreign"
        foreign.mkdir()
        sentinel = foreign / "important.txt"
        sentinel.write_text("keep\n")
        result = run_night(FIXTURES / "normal", foreign, root / "db", "x")
        assert result.returncode == 12 and sentinel.read_text() == "keep\n"
        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        (lock / "owner").write_text("other run\n")
        result = run_night(FIXTURES / "normal", target, root / "db2", "x")
        assert result.returncode == 12 and not target.exists()
        db = root / "db3"
        db.mkdir(parents=True)
        dblock = db / "locks" / f"{DATE}.lock"
        dblock.mkdir(parents=True)
        (dblock / "pid").write_text(str(os.getpid()))
        result = run_night(FIXTURES / "normal", root / "concurrent", db, "live")
        assert result.returncode == 12, result.stderr
        (dblock / "pid").write_text("999999")
        result = run_night(FIXTURES / "normal", root / "stale", db, "stale")
        assert result.returncode == 0, result.stderr


def check_starter() -> None:
    starter = MODULE / "starter/M11CUST2.COB"
    with tempfile.TemporaryDirectory(prefix="m11-starter-") as temp:
        root = Path(temp)
        target = root / "starter-bin"
        build = subprocess.run(
            ["bash", str(MODULE / "scripts/build.sh"), str(target),
             str(starter)], text=True, capture_output=True)
        assert build.returncode == 0 and target.is_file(), build.stderr


def main() -> int:
    check_source_format()
    check_fixture_manifest()
    check_customer_contract()
    check_normal()
    check_incidents()
    check_no_clobber_and_lock()
    check_starter()
    # RED->GREEN uses the instructor incident fixes; authoring-only.
    if INSTRUCTOR.is_dir():
        check_red_green()
    print("PASS: module 11 snapshot, incidents, layout offsets/PIC/golden, "
          "RED->GREEN, lock/no-clobber")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
