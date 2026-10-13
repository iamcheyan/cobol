#!/usr/bin/env python3
"""Deterministic fixtures for module 01 (foundations).

This generator only builds input bytes. It implements no batch logic:
the independent expectations live in expected/ and are computed from
the ACCOUNT v1 contract documented in DESIGN.md.
"""
from pathlib import Path

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
DATE = "20261009"


def account(aid, cust, cur="JPY", sign="+", bal=0, status="A",
            date=DATE, layout="001"):
    record = (f"{aid:0>10}{cust:0>8}{cur}{sign}{bal:013d}"
              f"{status}{date}{layout}")
    assert len(record) == 47, len(record)
    assert record.isascii()
    return record


def write_records(path, records, final_lf=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = b"".join(r.encode("ascii") + b"\n" for r in records)
    if records and not final_lf:
        data = data[:-1]
    path.write_bytes(data)


def write_raw(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def main():
    normal = account(1, 1, bal=1000, status="A")
    frozen = account(2, 2, sign="-", bal=250, status="F")
    closed = account(3, 1, bal=0, status="C")
    write_records(FIXTURES / "normal" / "account.dat",
                  [normal, frozen, closed])

    write_raw(FIXTURES / "boundary" / "empty.dat", b"")
    single = account(42, 7, bal=500, status="A")
    write_records(FIXTURES / "boundary" / "single.dat", [single])
    # Last record of the file with no terminating LF.
    write_records(FIXTURES / "boundary" / "no-final-lf.dat", [single],
                  final_lf=False)

    # Structural contract violations: RC8, nothing published.
    write_raw(FIXTURES / "invalid" / "short.dat",
              normal[:46].encode("ascii") + b"\n")
    write_raw(FIXTURES / "invalid" / "long.dat",
              normal.encode("ascii") + b"X\n")
    write_raw(FIXTURES / "invalid" / "crlf.dat",
              normal.encode("ascii") + b"\r\n")
    write_raw(FIXTURES / "invalid" / "bad-id.dat", b"X" + normal[1:].encode("ascii") + b"\n")
    write_raw(FIXTURES / "invalid" / "bad-layout.dat",
              (normal[:44] + "002").encode("ascii") + b"\n")
    write_raw(FIXTURES / "invalid" / "bad-date.dat",
              (normal[:36] + "20261008" + normal[44:]).encode("ascii") + b"\n")
    write_records(FIXTURES / "invalid" / "duplicate-id.dat",
                  [normal, normal[:10] + "00000002" + normal[18:]])
    write_records(FIXTURES / "invalid" / "unsorted.dat",
                  [account(5, 1, bal=0), account(4, 1, bal=0)])

    # Business rejection: RC4, published with reason UNKNOWN-STATUS.
    unknown = account(7, 3, bal=0, status="Z")
    write_records(FIXTURES / "invalid" / "unknown-status.dat", [unknown])


if __name__ == "__main__":
    main()
