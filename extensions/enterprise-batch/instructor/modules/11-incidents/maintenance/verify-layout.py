#!/usr/bin/env python3
"""Independent 11.5 layout verification: field offsets, PICs and semantic
golden bytes.

It does NOT trust any course program's output:

* it parses the copybooks to derive field order, PIC and derived offsets;
* it asks the real GnuCOBOL compiler/runtime for LENGTH OF the record and
  ADDRESS OF every leaf field (offsets), the same method used by module 07
  L4, so a drifted PIC/offset cannot pass;
* it decodes literal golden byte records field-by-field and checks the
  semantic values.

The enterprise-class lab layout deliberately uses a DISTINCT name
(ENTERPRISE-CLASS-V1/V2) from the canonical 175-field/1778-byte module 07
L4 record `ENTERPRISE-CUSTOMER-V1`, to avoid same-name/different-layout
version drift.

Exits 0 on success, 12 on any system error, 8 on a verification failure.
"""
from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[4]
MODULE = REPO / "curriculum/modules/11-incidents"
CB_DIR = MODULE / "maintenance/copybooks"
SYSTEM_CB = MODULE / "system/copybooks"
FIELD_RE = re.compile(r"^\s*05\s+([A-Z0-9-]+)\s+PIC\s+X\((\d+)\)\.\s*$")

# Expected layouts, derived by hand from the written contract (BANK-SYSTEM
# §2 for CUSTOMER v1; the 11.5 spec for the enterprise-class lab layout).
CUSTOMER_V1 = ("CUSTOMER-RECORD", [
    ("CUSTOMER-ID", "X(8)", 1, 8),
    ("CUSTOMER-NAME", "X(10)", 9, 10),
    ("CUSTOMER-BALANCE-DEMO", "X(8)", 19, 8),
    ("CUSTOMER-STATUS", "X(1)", 27, 1),
], 27)
ENTERPRISE_V1 = ("ENTERPRISE-CLASS-V1", [
    ("LAYOUT-VERSION", "X(3)", 1, 3),
    ("CUSTOMER-ID", "X(8)", 4, 8),
    ("RECORD-STATUS", "X(1)", 12, 1),
    ("CUSTOMER-NAME", "X(10)", 13, 10),
    ("CUSTOMER-CLASSIFICATION", "X(1)", 23, 1),
], 23)
ENTERPRISE_V2 = ("ENTERPRISE-CLASS-V2", [
    ("LAYOUT-VERSION", "X(3)", 1, 3),
    ("CUSTOMER-ID", "X(8)", 4, 8),
    ("RECORD-STATUS", "X(1)", 12, 1),
    ("CUSTOMER-NAME", "X(10)", 13, 10),
    ("CUSTOMER-CLASSIFICATION", "X(2)", 23, 2),
], 24)

GOLDEN_CUSTOMER_V1 = "00000001ALICE     00000100A"
GOLDEN_ENTERPRISE_V1 = "00100000001AALICE     A"
GOLDEN_ENTERPRISE_V2 = "00200000001AALICE     A1"


def parse_copybook(text: str):
    fields, offset = [], 1
    for raw in text.splitlines():
        code = raw.split("*>", 1)[0].rstrip()
        match = FIELD_RE.match(code)
        if not match:
            continue
        size = int(match.group(2))
        fields.append((match.group(1), f"X({size})", offset, size))
        offset += size
    return fields, offset - 1


def decode(fields, record: str):
    return {name: record[start - 1:start - 1 + length]
            for name, _pic, start, length in fields}


def compile_probe(root: Path, copybook: str, copy_dir: Path,
                  rec_name: str, fields) -> dict[str, int]:
    """Compile a probe that COPYs the copybook and DISPLAYs ADDRESS OF
    each leaf plus LENGTH OF the record; return {field: offset} (1-based)
    and {'__reclen__': n}."""
    probe = root / f"probe-{rec_name}.COB"
    lines = [
        "       IDENTIFICATION DIVISION.",
        "       PROGRAM-ID. LAYOUTPROBE.",
        "       DATA DIVISION.",
        "       WORKING-STORAGE SECTION.",
        f"          COPY '{copybook}'.",
        "       01 PTR USAGE POINTER.",
        "       PROCEDURE DIVISION.",
        f"           SET PTR TO ADDRESS OF {rec_name}",
        '           DISPLAY "BASE," PTR',
        f'           DISPLAY "RECLEN," LENGTH OF {rec_name}',
    ]
    for name, *_rest in fields:
        lines.append(f"           SET PTR TO ADDRESS OF {name}")
        lines.append(f'           DISPLAY "{name}," PTR')
    lines.append("           STOP RUN.")
    for number, line in enumerate(lines, 1):
        assert line.isascii() and len(line) <= 72, ("probe line", number, line)
    probe.write_text("\n".join(lines) + "\n")
    exe = root / f"probe-{rec_name}"
    build = subprocess.run(
        ["cobc", "-I", str(copy_dir), "-x", "-o", str(exe), str(probe)],
        capture_output=True, text=True)
    assert build.returncode == 0, build.stderr
    run = subprocess.run([str(exe)], capture_output=True, text=True)
    assert run.returncode == 0, run.stderr
    addresses, reclen = {}, None
    for line in run.stdout.splitlines():
        key, _, value = line.partition(",")
        if key == "BASE":
            base = int(value, 16)
        elif key == "RECLEN":
            reclen = int(value)
        else:
            addresses[key] = int(value, 16)
    result = {"__reclen__": reclen}
    for name, _pic, _start, _length in fields:
        result[name] = addresses[name] - base + 1
    return result


def check_layout(name, path: Path, spec, golden: str, expect_decoded: dict):
    rec_name, fields, width = spec
    parsed, parsed_width = parse_copybook(path.read_text())
    assert parsed == fields, (name, "copybook PIC/offset drift", parsed)
    assert parsed_width == width, (name, "width", parsed_width, width)
    assert len(golden) == width, (name, "golden width", len(golden))
    assert decode(fields, golden) == expect_decoded, (
        name, "golden decode", decode(fields, golden))
    print(f"  {name}: PIC/offsets (copybook) OK, width {width}B, golden decode OK")
    return rec_name, fields


def main() -> int:
    checks = []
    checks.append(("CUSTOMER v1 (27B, byte 27 = status)",
                   SYSTEM_CB / "CUSTOMER-V1.CPY", CUSTOMER_V1,
                   GOLDEN_CUSTOMER_V1,
                   {"CUSTOMER-ID": "00000001", "CUSTOMER-NAME": "ALICE     ",
                    "CUSTOMER-BALANCE-DEMO": "00000100",
                    "CUSTOMER-STATUS": "A"}))
    checks.append(("ENTERPRISE-CLASS v1 (23B)",
                   CB_DIR / "ENTERPRISE-CLASS-V1.CPY", ENTERPRISE_V1,
                   GOLDEN_ENTERPRISE_V1,
                   {"LAYOUT-VERSION": "001", "CUSTOMER-ID": "00000001",
                    "RECORD-STATUS": "A", "CUSTOMER-NAME": "ALICE     ",
                    "CUSTOMER-CLASSIFICATION": "A"}))
    checks.append(("ENTERPRISE-CLASS v2 (24B)",
                   CB_DIR / "ENTERPRISE-CLASS-V2.CPY", ENTERPRISE_V2,
                   GOLDEN_ENTERPRISE_V2,
                   {"LAYOUT-VERSION": "002", "CUSTOMER-ID": "00000001",
                    "RECORD-STATUS": "A", "CUSTOMER-NAME": "ALICE     ",
                    "CUSTOMER-CLASSIFICATION": "A1"}))

    with tempfile.TemporaryDirectory(prefix="m11-layout-") as temp:
        root = Path(temp)
        for title, path, spec, golden, decoded in checks:
            if not path.is_file():
                print(f"  {title}: MISSING {path}", file=sys.stderr)
                return 8
            rec_name, fields = check_layout(title, path, spec, golden, decoded)
            measured = compile_probe(root, path.name, path.parent,
                                     rec_name, fields)
            assert measured["__reclen__"] == spec[2], (
                title, "compiler LENGTH OF", measured["__reclen__"], spec[2])
            for field, _pic, start, _length in fields:
                assert measured[field] == start, (
                    title, field, "compiler offset", measured[field], start)
            print(f"  {title}: GnuCOBOL ADDRESS OF offsets + LENGTH OF OK")

    # Relationship to the canonical module 07 L4 large record (informational,
    # non-fatal: module 07 is a different owner).  Proves this lab layout is
    # a distinct name that only shares the CUSTOMER-CLASSIFICATION semantics.
    canonical = (REPO / "curriculum/modules/07-matching/labs/05-large-record"
                 / "copybooks/ENTERPRISE-CUSTOMER-V1.CPY")
    if canonical.is_file():
        text = canonical.read_text()
        head = text.splitlines()[0].strip()
        present = "CUSTOMER-CLASSIFICATION PIC X(1)." in text
        print(f"  canonical module 07 L4 record: {head}")
        print("  canonical CUSTOMER-CLASSIFICATION X(1): "
              + ("present (same semantics, distinct name)" if present
                 else "MISSING (semantics drifted)"))
    else:
        print("  canonical module 07 L4 copybook: not found (relationship "
              "unchecked; module 11 uses distinct name ENTERPRISE-CLASS)")

    print("PASS: 11.5 layout offsets/PIC/golden bytes and CUSTOMER v1 27B status")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(8)
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(12)
