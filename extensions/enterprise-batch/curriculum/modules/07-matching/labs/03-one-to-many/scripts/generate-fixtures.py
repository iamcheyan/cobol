#!/usr/bin/env python3
"""Regenerate deterministic ASCII/LF L2 input fixtures only."""
from pathlib import Path
import hashlib

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
DATE = "20261009"


def account(number: int, balance: int, status: str = "A") -> str:
    sign = "+" if balance >= 0 else "-"
    return (f"{number:010d}00000001JPY{sign}{abs(balance):013d}"
            f"{status}{DATE}001")


def tx(account_id: int, tx_id: str, sequence: int,
       direction: str, amount: int) -> str:
    assert len(tx_id) == 16
    return (f"{account_id:010d}{tx_id}{DATE}{sequence:06d}"
            f"{direction}{amount:013d}N")


def link(account_id: int, sequence: int, reverse_id: str,
         original_id: str) -> str:
    return f"{account_id:010d}{sequence:06d}{reverse_id}{original_id}"


def save(name: str, accounts: list[str], transactions: list[str],
         relations: list[str]) -> None:
    folder = FIXTURES / name
    folder.mkdir(parents=True, exist_ok=True)
    for filename, rows in (("account.dat", accounts),
                           ("transaction.dat", transactions),
                           ("reversal-link.dat", relations)):
        (folder / filename).write_bytes(
            "".join(row + "\n" for row in rows).encode("ascii"))


def ident(letter: str, number: int) -> str:
    return f"{letter}{number:015d}"


def main() -> None:
    x, y, z, w, b = tuple(ident("A", i) for i in range(1, 5)) + (
        ident("B", 1),)
    save("normal", [account(1, 1000), account(2, 50, "F"), account(3, 0)],
         [tx(1, x, 1, "C", 500), tx(1, y, 2, "D", 200),
          tx(1, z, 3, "D", 500), tx(1, w, 4, "D", 900),
          tx(2, b, 1, "C", 100)], [link(1, 3, z, x)])
    save("duplicate-id-cross-account", [account(1, 1), account(2, 2)],
         [tx(1, x, 1, "C", 1), tx(2, x, 1, "C", 1)], [])
    save("short-transaction", [account(1, 1)],
         [tx(1, x, 1, "C", 1)[:-1]], [])
    save("bad-reversal-reference", [account(1, 1000), account(2, 50, "F"),
                                    account(3, 0)],
         [tx(1, x, 1, "C", 500), tx(1, y, 2, "D", 200),
          tx(1, z, 3, "D", 500), tx(1, w, 4, "D", 900),
          tx(2, b, 1, "C", 100)],
         [link(1, 3, z, ident("Z", 999999999999999))])
    save("unsorted-transactions", [account(1, 1000)],
         [tx(1, x, 2, "C", 1), tx(1, y, 1, "C", 1)], [])
    save("boundary-aggregate-over-13", [account(1, 0), account(2, 0)],
         [tx(1, x, 1, "C", 9000000000000),
          tx(1, y, 2, "D", 9000000000000),
          tx(1, z, 3, "C", 9000000000000),
          tx(1, w, 4, "D", 9000000000000),
          tx(2, b, 1, "C", 9000000000000)], [])
    save("boundary-no-transactions", [account(1, 1000),
         account(2, 50, "F"), account(3, 0)], [], [])
    save("boundary-empty-all", [], [], [])
    save("boundary-zero-amount", [account(1, 100)],
         [tx(1, x, 1, "C", 0)], [])
    save("boundary-overflow", [account(1, 9999999999999)],
         [tx(1, x, 1, "C", 1)], [])
    save("business-cross-account-reversal", [account(1, 100),
         account(2, 50)], [tx(1, x, 1, "C", 100),
         tx(2, y, 1, "D", 100)], [link(2, 1, y, x)])
    save("business-already-reversed", [account(1, 1000)],
         [tx(1, x, 1, "C", 100), tx(1, y, 2, "D", 100),
          tx(1, z, 3, "D", 100)], [link(1, 2, y, x),
                                   link(1, 3, z, x)])
    save("business-original-not-accepted", [account(1, 0)],
         [tx(1, x, 1, "D", 10), tx(1, y, 2, "C", 10)],
         [link(1, 2, y, x)])
    save("business-orphan-transaction", [account(1, 100)],
         [tx(2, x, 1, "C", 10)], [])
    save("business-orphan-linked", [],
         [tx(2, x, 1, "C", 100), tx(2, y, 2, "D", 100)],
         [link(2, 2, y, x)])
    save("business-closed-account", [account(1, 100, "C")],
         [tx(1, x, 1, "C", 10)], [])
    save("business-reversal-mismatch", [account(1, 100)],
         [tx(1, x, 1, "C", 50), tx(1, y, 2, "D", 49)],
         [link(1, 2, y, x)])
    save("business-future-reference", [account(1, 100)],
         [tx(1, x, 1, "D", 50), tx(1, y, 2, "C", 50)],
         [link(1, 1, x, y)])
    save("boundary-max-amount", [account(1, 0)],
         [tx(1, x, 1, "C", 9999999999999)], [])
    save("invalid-link-key", [account(1, 100)],
         [tx(1, x, 1, "C", 100), tx(1, y, 2, "D", 100)],
         [link(2, 2, y, x)])
    save("invalid-link-id", [account(1, 100)],
         [tx(1, x, 1, "C", 100), tx(1, y, 2, "D", 100)],
         [link(1, 2, y, "!000000000000001")])
    save("invalid-link-sequence", [account(1, 100)],
         [tx(1, x, 1, "C", 100), tx(1, y, 2, "D", 100)],
         [link(1, 3, y, x)])
    save("invalid-unused-link", [account(1, 100)],
         [tx(1, x, 1, "C", 100)], [link(1, 2, y, x)])
    manifest = []
    for path in sorted(p for p in FIXTURES.rglob("*")
                       if p.is_file() and p.name != "SHA256SUMS"):
        rel = path.relative_to(FIXTURES)
        manifest.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {rel}")
    (FIXTURES / "SHA256SUMS").write_text("\n".join(manifest) + "\n")


if __name__ == "__main__":
    main()
