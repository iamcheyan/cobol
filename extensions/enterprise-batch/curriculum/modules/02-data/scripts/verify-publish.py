#!/usr/bin/env python3
"""Independent recomputation of the module 02 CUSTOMER v1 contract.

The runner calls this only after the COBOL loader returned 0 or 4. It
re-derives accepted/rejected rows, the rejection reason and the balance
total from raw input bytes; it never trusts the program's own counts.
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
        if len(row) != 27:
            fail("input record width != 27")
        if b"\r" in row:
            fail("input record contains CR")
    return rows


def reason_for(row):
    if row[8:18] == b" " * 10:
        return b"NAME-MISSING"
    if not row[18:26].isdigit():
        return b"BAD-AMOUNT"
    if row[26:27] not in (b"A", b"D"):
        return b"UNKNOWN-STATUS"
    return None


def main():
    if len(sys.argv) != 5:
        fail("usage INPUT CONTROL ACCEPTED REJECTED")
    source = Path(sys.argv[1])
    control, accepted, rejected = (Path(sys.argv[2]), Path(sys.argv[3]),
                                   Path(sys.argv[4]))
    rows = read_records(source)
    accepted_rows, rejected_rows, previous, total = [], [], None, 0
    for row in rows:
        if not row[0:8].isdigit():
            fail("non-digit customer id")
        if previous is not None and row[0:8] <= previous:
            fail("customer ids not strictly ascending")
        previous = row[0:8]
        reason = reason_for(row)
        if reason is None:
            accepted_rows.append(row)
            total += int(row[18:26])
        else:
            rejected_rows.append((row, reason))
    expected = (b"JOB|CUSTLOAD|V1\n"
                b"CONTROL|READ=" + f"{len(rows):012d}".encode("ascii") +
                b"|ACCEPTED=" + f"{len(accepted_rows):012d}".encode("ascii") +
                b"|REJECTED=" + f"{len(rejected_rows):012d}".encode("ascii") +
                b"|BALANCE-TOTAL=" + f"{total:018d}".encode("ascii") + b"\n")
    if control.read_bytes() != expected:
        fail("control.txt mismatch")
    if accepted.read_bytes() != b"".join(r + b"\n" for r in accepted_rows):
        fail("accepted.dat mismatch")
    if rejected.read_bytes() != b"".join(
            r + b"|" + reason + b"\n" for r, reason in rejected_rows):
        fail("rejected.dat mismatch")
    if len(rows) != len(accepted_rows) + len(rejected_rows):
        fail("read != accepted + rejected")
    print("verify-publish: PASS", file=sys.stderr)


if __name__ == "__main__":
    main()
