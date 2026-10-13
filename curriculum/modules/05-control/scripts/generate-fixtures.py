#!/usr/bin/env python3
"""Deterministically regenerate the module 05 CUSTOMER v1 fixtures.

Only builds synthetic ASCII/LF input bytes; never implements cleansing,
normalisation or rejection classification.
"""
from pathlib import Path

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"

# CUSTOMER v1 = 27 bytes: id(8) name(10) balance(8) status(1); LF not counted.
WIDTH = 27


def cust(identifier: str, name: str, balance: str, status: str) -> bytes:
    record = f"{identifier:<8}{name:<10}{balance:<8}{status:<1}"
    assert len(record) == WIDTH, (record, len(record))
    return record.encode("ascii")


def write(group: str, name: str, payload: bytes) -> None:
    folder = FIXTURES / group
    folder.mkdir(parents=True, exist_ok=True)
    (folder / name).write_bytes(payload)


def lines(records: list[bytes]) -> bytes:
    return b"".join(record + b"\n" for record in records)


def main() -> None:
    # normal: every record valid; lower-case status is normalised up.
    write("normal", "clean.dat", lines([
        cust("00000001", "  Alice", "00000050", "a"),
        cust("00000002", "Bob", "00000010", "D"),
        cust("00000003", "   Carol", "00000000", "A"),
    ]))

    # boundary: 0 records, single record, minimum and maximum allowed amount.
    write("boundary", "empty.dat", b"")
    write("boundary", "single.dat", lines([
        cust("00000001", "  Alice", "00000001", "A"),
    ]))
    write("boundary", "min-amount.dat", lines([
        cust("00000001", "  Alice", "00000000", "A"),
    ]))
    write("boundary", "max-amount.dat", lines([
        cust("00000001", "  Alice", "50000000", "A"),
        cust("00000002", "Bob", "00000001", "D"),
    ]))

    # invalid business rows: each yields one rejection reason, RC4.
    write("invalid", "missing-name.dat", lines([
        cust("00000001", "", "00000050", "A"),
    ]))
    write("invalid", "bad-id.dat", lines([
        cust("0000000X", "  Alice", "00000050", "A"),
    ]))
    write("invalid", "non-numeric-amount.dat", lines([
        cust("00000001", "  Alice", "00000ABC", "A"),
    ]))
    write("invalid", "amount-over-cap.dat", lines([
        cust("00000001", "  Alice", "50000001", "A"),
    ]))
    write("invalid", "unknown-status.dat", lines([
        cust("00000001", "  Alice", "00000050", "X"),
    ]))
    write("invalid", "duplicate-id.dat", lines([
        cust("00000001", "  Alice", "00000050", "A"),
        cust("00000001", "  Alice2", "00000060", "A"),
    ]))
    # mixed proves read = accept + reject in one run and reason priority.
    write("invalid", "mixed.dat", lines([
        cust("00000001", "  Alice", "00000050", "a"),
        cust("00000002", "", "00000100", "A"),
        cust("00000003", "   Carol", "50000001", "D"),
        cust("00000004", "Dave", "00000XYZ", "A"),
        cust("00000005", "Eve", "00000007", "Q"),
        cust("00000005", "Eve2", "00000008", "A"),
    ]))

    # invalid structural rows: contract errors, RC8, no publication.
    write("invalid", "unsorted.dat", lines([
        cust("00000002", "Bob", "00000010", "A"),
        cust("00000001", "  Alice", "00000050", "A"),
    ]))
    write("invalid", "short-record.dat", b"0000\n")
    write("invalid", "long-record.dat", lines([
        b"00000001  Alice   00000050A" + b"A",
    ]))
    write("invalid", "no-trailing-lf.dat",
          cust("00000001", "  Alice", "00000050", "A"))
    write("invalid", "crlf.dat",
          cust("00000001", "  Alice", "00000050", "A") + b"\r\n")

    print("regenerated module 05 fixtures under", FIXTURES)


if __name__ == "__main__":
    main()
