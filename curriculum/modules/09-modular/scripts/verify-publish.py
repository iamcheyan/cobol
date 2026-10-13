#!/usr/bin/env python3
"""Independent publication gate for module 09.

Recomputes the whole expected run from the *raw inputs* with oracle.py (a
model written from the business contract, not from the COBOL program) and
compares the four derived artifacts and the log byte for byte. Any drift
fails with RC 12 so a wrong result is never published.
"""
from pathlib import Path
import sys
import oracle


def fail(message: str) -> int:
    print(f"publish verification failed: {message}", file=sys.stderr)
    return 12


def main() -> int:
    if len(sys.argv) != 10:
        return fail("expected customer account transaction date report "
                    "ledger valid rejected log")
    (customer, account, transaction, date, report, ledger, valid,
     rejected, log) = sys.argv[1:10]
    try:
        want = oracle.compute(Path(customer).read_bytes(),
                              Path(account).read_bytes(),
                              Path(transaction).read_bytes(), date)
    except oracle.ContractError as error:
        return fail(f"input no longer satisfies the contract: {error}")
    checks = [
        ("report", want["report"].encode(), Path(report).read_bytes()),
        ("ledger", want["ledger"], Path(ledger).read_bytes()),
        ("valid", want["valid"], Path(valid).read_bytes()),
        ("rejected", want["rejected"], Path(rejected).read_bytes()),
        ("log", want["log"].encode(), Path(log).read_bytes()),
    ]
    for name, expected, actual in checks:
        if expected != actual:
            return fail(f"{name} differs from the independent model")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
