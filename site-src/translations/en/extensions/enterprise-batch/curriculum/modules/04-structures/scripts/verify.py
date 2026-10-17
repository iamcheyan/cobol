#!/usr/bin/env python3
"""Independent semantic verification for Module 04 (called before run.sh publishes; do not trust program output).

  * 04.1: Recompute REDEFINES/RENAMES/OCCURS/ODO lengths and values from structure semantics.
  * 04.2: Recompute V1/V2 lengths, offsets, and COPY REPLACING results from the canonical layout.
  * 04.3: Recompute each record's located values (ID/STATUS/SURNAME/CLASS/RISK/SYNC) and
          record count from raw input bytes using FIELD-CATALOG offsets and PICs.

Any mismatch (placeholder report, skipped record, incorrect field value/offset, wrong count) fails;
the caller does not publish.
Usage: verify.py LESSON OUTPUT_DIR
04.3 reads OUTPUT_DIR/input.dat (copied by run.sh).
"""
from __future__ import annotations
import sys
from pathlib import Path

EXPECTED = Path(__file__).resolve().parents[1] / "expected"

REC_LEN = 1778            # ENTERPRISE-CUSTOMER-V1 canonical record length
V2_LEN = 1779            # Only CUSTOMER-CLASSIFICATION X(1)->X(2)
# FIELD-CATALOG.csv offsets (1-based) and PICs:
#   CUSTOMER-ID 12 X(10); RECORD-STATUS 22 X(1); LEGAL-SURNAME 59 X(32);
#   CUSTOMER-CLASSIFICATION 460 X(1); RISK-SCORE 1467 S9(9) COMP;
#   SYNC-STATE 1778 X(1). Record layout_version 1 X(3), ABI 4 X(8).


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(8)


def lesson1_report() -> str:
    payload = 8 + 7 + 3                       # PL-DATE + PL-AMT + PL-CODE
    rab = 3 + 4                               # R-A(3) THRU R-B(4)
    return "\n".join([
        "LESSON,04.1",
        f"REDEFINES,WRAP-LEN,{payload:03d}",
        f"REDEFINES,PAYLOAD-LEN,{payload:03d}",
        f"REDEFINES,VIEW-LEN,{payload:03d}",
        "REDEFINES,NO-DOUBLE-COUNT,OK",
        f"RENAMES,R-AB-LEN,{rab:03d}",
        "RENAMES,R-AB-VALUE,AAABBBB",
        "OCCURS,ITEM-COUNT,005",
        "OCCURS,INDEX-3,CCC",
        f"ODO,COUNT-03,LEN,{2 + 3 * 5:03d}",
        f"ODO,COUNT-07,LEN,{2 + 7 * 5:03d}",
    ]) + "\n"


def lesson2_report() -> str:
    shift = V2_LEN - REC_LEN
    return "\n".join([
        "LESSON,04.2",
        f"LEN,V1,{REC_LEN}",
        f"LEN,V2,{V2_LEN}",
        f"SHIFT,V2-V1,{shift:04d}",
        "CLASSIFICATION,V1,A",
        "CLASSIFICATION,V2,B",
        "REFMOD,CUSTOMER-ID,FIRST4,0000",
        "REFMOD,CUSTOMER-ID,LAST6,000001",
    ]) + "\n"


def lesson3_report(payload: bytes) -> str:
    if len(payload) % REC_LEN:
        fail(f"input length {len(payload)} not a multiple of {REC_LEN}")
    lines = ["LESSON,04.3", f"LAYOUT,ENTERPRISE-CUSTOMER-V1,{REC_LEN}"]
    n = 0
    for i in range(0, len(payload), REC_LEN):
        rec = payload[i:i + REC_LEN]
        layout = rec[0:3].decode()
        abi = rec[3:11].decode()
        cid = rec[11:21].decode()
        if layout != "001" or abi != "GCOB32BE" or not cid.isdigit():
            fail("input has a bad structure but the program published a report")
        n += 1
        risk = int.from_bytes(rec[1466:1470], "big", signed=True)
        lines += [
            f"REC,{n:04d},ID,{cid}",
            f"  STATUS,{rec[21:22].decode()}",
            f"  SURNAME,{rec[58:90].decode().strip()}",
            f"  CLASS,{rec[459:460].decode().strip()}",
            f"  RISK,{risk:+010d}",
            f"  SYNC,{rec[1777:1778].decode()}",
        ]
    lines.append(f"RECORDS,{n:04d}")
    return "\n".join(lines) + "\n"


def verify(lesson: str, outdir: Path) -> None:
    report = outdir / "report.txt"
    if not report.is_file():
        fail(f"report.txt missing in {outdir}")
    text = report.read_text()
    if lesson == "04.1":
        want = lesson1_report()
        if text != want:
            fail(f"04.1 report mismatch\n--- got ---\n{text}--- want ---\n{want}")
        if text != (EXPECTED / "04.1-structures.txt").read_text():
            fail("04.1 report differs from committed expected")
    elif lesson == "04.2":
        want = lesson2_report()
        if text != want:
            fail(f"04.2 report mismatch\n--- got ---\n{text}--- want ---\n{want}")
        if text != (EXPECTED / "04.2-copy-shift.txt").read_text():
            fail("04.2 report differs from committed expected")
    elif lesson == "04.3":
        inp = outdir / "input.dat"
        if not inp.is_file():
            fail("04.3 input.dat snapshot missing")
        want = lesson3_report(inp.read_bytes())
        if text != want:
            fail(f"04.3 report mismatch (fields/offsets/records)\n"
                 f"--- got ---\n{text}--- want ---\n{want}")
    else:
        fail(f"unknown lesson {lesson}")


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: verify.py LESSON OUTPUT_DIR", file=sys.stderr)
        sys.exit(12)
    verify(sys.argv[1], Path(sys.argv[2]))
    print("PASS: module04 independent semantic verification")


if __name__ == "__main__":
    main()
