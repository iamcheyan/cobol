#!/usr/bin/env python3
"""Independent recomputation of the module 01 batch entry contract.

The runner calls this only after the COBOL program returned 0 or 4. It
re-derives the expected control report, accepted rows and rejected rows
from the raw input bytes and the ACCOUNT v1 contract, then compares the
published bytes. It never trusts the COBOL program's own counts.
"""
import sys
from pathlib import Path


def fail(message):
    print("verify-publish: " + message, file=sys.stderr)
    sys.exit(12)


def read_records(path):
    data = path.read_bytes()
    if data == b"":
        return []
    if not data.endswith(b"\n"):
        fail("input missing final LF")
    rows = data[:-1].split(b"\n")
    for row in rows:
        if len(row) != 47:
            fail("input record width != 47")
        if b"\r" in row:
            fail("input record contains CR")
    return rows


def main():
    if len(sys.argv) != 6:
        fail("usage INPUT BUSINESS_DATE CONTROL ACCEPTED REJECTED")
    source, date = Path(sys.argv[1]), sys.argv[2].encode("ascii")
    control, accepted, rejected = (Path(sys.argv[3]), Path(sys.argv[4]),
                                   Path(sys.argv[5]))
    rows = read_records(source)
    accepted_rows, rejected_rows, previous = [], [], None
    for row in rows:
        aid, cur, sign = row[0:10], row[18:21], row[21:22]
        balance, status, row_date, layout = (row[22:35], row[35:36],
                                              row[36:44], row[44:47])
        if not aid.isdigit():
            fail("non-digit account id")
        if layout != b"001":
            fail("layout version != 001")
        if row_date != date:
            fail("record date != business date")
        if cur != b"JPY":
            fail("currency != JPY")
        if sign not in (b"+", b"-"):
            fail("balance sign not + or -")
        if not balance.isdigit():
            fail("balance not numeric")
        if previous is not None and aid <= previous:
            fail("account ids not strictly ascending")
        previous = aid
        if status in (b"A", b"F", b"C"):
            accepted_rows.append(row)
        else:
            rejected_rows.append(row)
    expected = (b"JOB|BANK-ENTRY|V1\n"
                b"BUSINESS-DATE|" + date + b"\n"
                b"CONTROL|READ=" + f"{len(rows):012d}".encode("ascii") +
                b"|ACCEPTED=" + f"{len(accepted_rows):012d}".encode("ascii") +
                b"|REJECTED=" + f"{len(rejected_rows):012d}".encode("ascii") +
                b"\n")
    if control.read_bytes() != expected:
        fail("control.txt mismatch")
    if accepted.read_bytes() != b"".join(r + b"\n" for r in accepted_rows):
        fail("accepted.dat mismatch")
    if rejected.read_bytes() != b"".join(
            r + b"|UNKNOWN-STATUS\n" for r in rejected_rows):
        fail("rejected.dat mismatch")
    if len(rows) != len(accepted_rows) + len(rejected_rows):
        fail("read != accepted + rejected")
    print("verify-publish: PASS", file=sys.stderr)


if __name__ == "__main__":
    main()
