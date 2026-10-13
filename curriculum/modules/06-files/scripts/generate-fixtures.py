#!/usr/bin/env python3
"""Deterministically regenerate the module 06 ACCOUNT v1 fixtures.

Only builds synthetic ASCII/LF input bytes; never implements validation.
"""
from pathlib import Path

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
DATE = "20261009"
WIDTH = 47


def acct(identifier: int, customer: int, currency: str, sign: str,
         balance: int, status: str, date: str = DATE,
         layout: str = "001") -> bytes:
    record = (f"{identifier:010d}{customer:08d}{currency}{sign}"
              f"{balance:013d}{status}{date}{layout}")
    assert len(record) == WIDTH, (record, len(record))
    return record.encode("ascii")


def write(group: str, name: str, payload: bytes) -> None:
    folder = FIXTURES / group
    folder.mkdir(parents=True, exist_ok=True)
    (folder / name).write_bytes(payload)


def lines(records: list) -> bytes:
    return b"".join(
        (record.encode("ascii") if isinstance(record, str) else record) + b"\n"
        for record in records)


def main() -> None:
    write("normal", "valid.dat", lines([
        acct(1, 1, "JPY", "+", 1000, "A"),
        acct(2, 1, "JPY", "+", 50, "F"),
        acct(3, 2, "JPY", "-", 500, "C"),
    ]))

    write("boundary", "empty.dat", b"")
    write("boundary", "single.dat", lines([
        acct(1, 1, "JPY", "+", 1, "A"),
    ]))
    write("boundary", "negative-balance.dat", lines([
        acct(1, 1, "JPY", "-", 9999999999999, "A"),
    ]))
    write("boundary", "zero-balance.dat", lines([
        acct(1, 1, "JPY", "+", 0, "A"),
    ]))

    base = acct(1, 1, "JPY", "+", 1000, "A")
    text = base.decode("ascii")
    write("invalid", "bad-account-id.dat",
          lines([text[:0] + "00000000X1" + text[10:]]))
    write("invalid", "bad-customer-id.dat",
          lines([text[:10] + "0000000X" + text[18:]]))
    write("invalid", "unknown-currency.dat",
          lines([text[:18] + "USD" + text[21:]]))
    write("invalid", "bad-sign.dat", lines([text[:21] + "*" + text[22:]]))
    write("invalid", "bad-balance.dat",
          lines([text[:22] + "00000000000XY" + text[35:]]))
    write("invalid", "bad-date.dat", lines([text[:36] + "20260230" + text[44:]]))
    write("invalid", "date-mismatch.dat",
          lines([text[:36] + "20261008" + text[44:]]))
    write("invalid", "unknown-status.dat",
          lines([text[:35] + "Z" + text[36:]]))
    write("invalid", "duplicate-id.dat", lines([
        acct(1, 1, "JPY", "+", 1000, "A"),
        acct(1, 1, "JPY", "+", 2000, "A"),
    ]))
    write("invalid", "mixed.dat", lines([
        acct(1, 1, "JPY", "+", 1000, "A"),
        acct(2, 1, "USD", "+", 100, "A"),
        acct(3, 2, "JPY", "*", 100, "A"),
        acct(4, 2, "JPY", "+", 100, "Z"),
        acct(5, 3, "JPY", "+", 100, "A", "20261008"),
        acct(6, 3, "JPY", "+", 100, "A"),
    ]))

    write("invalid", "bad-layout.dat", lines([
        acct(1, 1, "JPY", "+", 1000, "A", layout="002"),
    ]))
    write("invalid", "unsorted.dat", lines([
        acct(2, 1, "JPY", "+", 1000, "A"),
        acct(1, 1, "JPY", "+", 2000, "A"),
    ]))
    write("invalid", "short-record.dat", b"0000\n")
    write("invalid", "long-record.dat",
          lines([base + b"X"]))
    write("invalid", "no-trailing-lf.dat", base)
    write("invalid", "crlf.dat", base + b"\r\n")

    print("regenerated module 06 fixtures under", FIXTURES)


if __name__ == "__main__":
    main()
