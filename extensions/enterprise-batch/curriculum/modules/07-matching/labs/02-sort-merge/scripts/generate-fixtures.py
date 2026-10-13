#!/usr/bin/env python3
"""Generate B02's ASCII fixed-record inputs; expected results are hand-authored."""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
DATE = "20261009"


def tx(account: int, identifier: str, sequence: int, direction: str,
       amount: int) -> bytes:
    assert len(identifier) == 16
    return (f"{account:010d}{identifier}{DATE}{sequence:06d}{direction}"
            f"{amount:013d}N").encode("ascii")


def ident(letter: str, n: int) -> str:
    return f"{letter}{n:015d}"


def save(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def rows(name: str, values: list[bytes], ending: bytes = b"\n") -> None:
    save(ROOT / name, ending.join(values) + (ending if ending else b""))


def main() -> None:
    z1 = tx(1, ident("Z", 1), 1, "C", 500)
    a2 = tx(1, ident("A", 2), 2, "C", 100)
    m3 = tx(1, ident("M", 3), 2, "D", 50)
    a4 = tx(1, ident("A", 4), 3, "D", 500)
    b5 = tx(2, ident("B", 5), 1, "C", 10)
    a6 = tx(2, ident("A", 6), 1, "D", 10)
    rows("01-sort/fixtures/normal/transaction.dat",
         [b5, a4, z1, a6, m3, a2])
    rows("02-merge/fixtures/normal/feed-a.dat", [z1, m3, b5])
    rows("02-merge/fixtures/normal/feed-b.dat", [a2, a4, a6])
    rows("02-merge/fixtures/invalid/reversed-feed-a.dat", [m3, z1, b5])
    duplicate = tx(2, ident("Z", 1), 2, "C", 1)
    rows("01-sort/fixtures/invalid/duplicate-global-id.dat",
         [z1, a2, tx(2, ident("A", 3), 1, "C", 1), duplicate])
    rows("02-merge/fixtures/invalid/duplicate-feed-a.dat", [z1])
    rows("02-merge/fixtures/invalid/duplicate-feed-b.dat", [duplicate])
    for lesson in ("01-sort", "02-merge"):
        root = ROOT / lesson / "fixtures"
        valid = (root / "normal/transaction.dat" if lesson == "01-sort"
                 else root / "normal/feed-a.dat")
        data = valid.read_bytes()
        first = data.split(b"\n", 1)[0]
        rows(f"{lesson}/fixtures/invalid/short.dat", [first[:-1]])
        rows(f"{lesson}/fixtures/invalid/long.dat", [first + b"X"])
        (root / "invalid/no-final-lf.dat").write_bytes(first)
        (root / "invalid/crlf.dat").write_bytes(first + b"\r\n")
        bad_date = first[:26] + b"20260230" + first[34:]
        rows(f"{lesson}/fixtures/invalid/invalid-calendar.dat", [bad_date])
        bad_direction = first[:40] + b"X" + first[41:]
        rows(f"{lesson}/fixtures/invalid/invalid-direction.dat", [bad_direction])
    rows("01-sort/fixtures/boundary/single-record.dat", [z1])
    leap = z1[:26] + b"20240229" + z1[34:]
    rows("01-sort/fixtures/boundary/leap-day.dat", [leap])
    rows("02-merge/fixtures/boundary/single-a.dat", [z1])
    save(ROOT / "01-sort/fixtures/boundary/empty.dat", b"")
    rows("01-sort/fixtures/invalid/invalid-calendar-month.dat",
         [z1[:26] + b"20261301" + z1[34:]])
    rows("01-sort/fixtures/invalid/bad-account.dat",
         [b"X" + z1[1:]])
    rows("01-sort/fixtures/invalid/bad-id.dat",
         [z1[:10] + b"A" + b"-" + z1[12:]])

    rows("01-sort/fixtures/invalid/bad-status.dat",
         [z1[:54] + b"X"])
    rows("01-sort/fixtures/invalid/status-r-not-reversal.dat",
         [z1[:54] + b"R"])
    rows("01-sort/fixtures/invalid/lowercase-id.dat",
         [z1[:10] + b"z" + z1[11:]])
    rows("01-sort/fixtures/invalid/space-id.dat",
         [z1[:10] + b" " + z1[11:]])
    rows("01-sort/fixtures/boundary/zero-amount.dat",
         [z1[:41] + b"0000000000000" + z1[54:]])
    save(ROOT / "02-merge/fixtures/boundary/empty-a.dat", b"")
    save(ROOT / "02-merge/fixtures/boundary/empty-b.dat", b"")
    save(ROOT / "02-merge/fixtures/boundary/single-a.dat", z1 + b"\n")
    save(ROOT / "02-merge/fixtures/boundary/single-b.dat", b"")
    rows("02-merge/fixtures/invalid/invalid-calendar-month.dat",
         [z1[:26] + b"20261301" + z1[34:]])
    rows("02-merge/fixtures/invalid/bad-account.dat",
         [b"X" + z1[1:]])
    rows("02-merge/fixtures/invalid/bad-id.dat",
         [z1[:10] + b"A" + b"-" + z1[12:]])

    rows("02-merge/fixtures/invalid/bad-status.dat",
         [z1[:54] + b"X"])
    rows("02-merge/fixtures/invalid/status-r-not-reversal.dat",
         [z1[:54] + b"R"])
    rows("02-merge/fixtures/invalid/lowercase-id.dat",
         [z1[:10] + b"z" + z1[11:]])
    rows("02-merge/fixtures/invalid/space-id.dat",
         [z1[:10] + b" " + z1[11:]])
    rows("02-merge/fixtures/boundary/zero-amount.dat",
         [z1[:41] + b"0000000000000" + z1[54:]])

    common = ROOT / "common/fixtures/integration"
    common.mkdir(parents=True, exist_ok=True)
    master1 = f"000000000100000001JPY+0000000001000A{DATE}001\n"
    master2 = f"000000000200000002JPY+0000000000100A{DATE}001\n"
    (common / "account.dat").write_text(master1 + master2, encoding="ascii")
    link = f"{1:010d}{3:06d}{ident('A',4)}{ident('Z',1)}\n"
    (common / "reversal-link.dat").write_text(link, encoding="ascii")
    manifest = []
    fixture_roots = [ROOT / "01-sort/fixtures", ROOT / "02-merge/fixtures",
                     ROOT / "common/fixtures", ROOT / "common/expected",
                     ROOT / "01-sort/expected",
                     ROOT / "02-merge/expected"]
    paths = (path for folder in fixture_roots for path in folder.rglob("*")
             if path.is_file() and path.name != "SHA256SUMS")
    for path in sorted(paths):
        manifest.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  "
                        f"{path.relative_to(ROOT)}")
    (ROOT / "SHA256SUMS").write_text("\n".join(manifest) + "\n",
                                     encoding="ascii")


if __name__ == "__main__":
    main()
