#!/usr/bin/env python3
"""Deterministic fixtures for module 02 (customer data).

Builds only input bytes; it implements no loading/validation logic.
Expected values live in expected/ and come from the CUSTOMER v1 contract
documented in DESIGN.md.
"""
from pathlib import Path

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"


def customer(cid, name, balance, status):
    record = f"{cid:0>8}{name:<10}{balance:08d}{status}"
    assert len(record) == 27, len(record)
    assert record.isascii()
    return record


def raw_record(cid, name, balance_text, status):
    record = f"{cid:0>8}{name:<10}{balance_text}{status}"
    assert len(record) == 27, len(record)
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
    alice = customer(1, "ALICE", 12345, "A")
    bob = customer(2, "BOB", 50, "D")
    carol = customer(3, "CAROL", 9999999, "A")
    write_records(FIXTURES / "normal" / "customer.dat", [alice, bob, carol])

    write_raw(FIXTURES / "boundary" / "empty.dat", b"")
    single = customer(42, "SOLO", 500, "A")
    write_records(FIXTURES / "boundary" / "single.dat", [single])
    write_records(FIXTURES / "boundary" / "max-balance.dat",
                  [customer(9, "MAX", 99999999, "A")])
    write_records(FIXTURES / "boundary" / "name-full.dat",
                  [customer(5, "ABCDEFGHIJ", 1000, "A")])
    write_records(FIXTURES / "boundary" / "no-final-lf.dat", [single],
                  final_lf=False)

    # Structural contract violations: RC8, nothing published.
    write_raw(FIXTURES / "invalid" / "short.dat",
              single[:26].encode("ascii") + b"\n")
    write_raw(FIXTURES / "invalid" / "long.dat",
              single.encode("ascii") + b"X\n")
    write_raw(FIXTURES / "invalid" / "crlf.dat",
              single.encode("ascii") + b"\r\n")
    write_raw(FIXTURES / "invalid" / "bad-id.dat",
              b"X" + alice[1:].encode("ascii") + b"\n")
    write_records(FIXTURES / "invalid" / "duplicate-id.dat",
                  [alice, customer(1, "SECOND", 0, "A")])
    write_records(FIXTURES / "invalid" / "unsorted.dat",
                  [customer(5, "FIVE", 0, "A"), customer(4, "FOUR", 0, "A")])

    # Business rejections: RC4, published with a reason.
    write_records(FIXTURES / "invalid" / "name-missing.dat",
                  [customer(6, "", 0, "A")])
    write_records(FIXTURES / "invalid" / "bad-amount.dat",
                  [raw_record(7, "BADBAL", "00000A00", "A")])
    write_records(FIXTURES / "invalid" / "unknown-status.dat",
                  [customer(8, "STATUS", 0, "Z")])


if __name__ == "__main__":
    main()
