#!/usr/bin/env python3
"""B03 permanent end-to-end contract suite."""
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[4]
BASE = LAB / "fixtures/normal"
CASES = LAB / "fixtures/cases"
RUN = LAB / "scripts/run.sh"


def digest(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def invoke(snapshot: Path, previous: Path, expected_rc: int, label: str,
           target: Path, extra_env: dict[str, str] | None = None,
           account: Path | None = None, transaction: Path | None = None,
           reversal: Path | None = None, business_date: str = "20261009"
           ) -> subprocess.CompletedProcess:
    command = ["bash", str(RUN), str(account or BASE / "account.dat"),
               str(transaction or BASE / "transaction.dat"),
               str(reversal or BASE / "reversal-link.dat"),
               str(snapshot), str(previous), str(target), business_date]
    env = dict(os.environ, COB_SORT_MEMORY="2M")
    if extra_env:
        env.update(extra_env)
    result = subprocess.run(command, text=True, capture_output=True, env=env)
    assert result.returncode == expected_rc, (
        label, result.returncode, result.stdout, result.stderr)
    if expected_rc in (0, 4):
        assert target.is_dir(), (label, "publish expected")
        assert (target / "manifest.sha256").is_file()
    else:
        assert not target.exists(), (label, "fail-closed expected")
    return result


def test_nonmonotone_normal():
    with tempfile.TemporaryDirectory(prefix="b03-normal-") as td:
        out = Path(td) / "normal"
        before = {p.name: digest(p) for p in BASE.glob("*.dat")}
        invoke(BASE / "customer-snapshot.dat", BASE / "previous-day.dat",
               0, "nonmonotone normal", out)
        assert (out / "eligible-master.dat").read_bytes() == (
            LAB / "expected/normal-master.dat").read_bytes()
        assert (out / "customer-totals.csv").read_bytes() == (
            LAB / "expected/normal-customer-totals.csv").read_bytes()
        assert {p.name: digest(p) for p in BASE.glob("*.dat")} == before


def test_independent_business_matrix():
    cases = json.loads((CASES / "case-expectations.json").read_text())[
        "cases"]
    for case in cases:
        snap = BASE / "customer-snapshot.dat"
        prev = BASE / "previous-day.dat"
        if case["override_stream"] == "snapshot":
            snap = CASES / case["override_file"]
        else:
            prev = CASES / case["override_file"]
        with tempfile.TemporaryDirectory(prefix="b03-case-") as td:
            target = Path(td) / case["case"]
            invoke(snap, prev, case["expected_rc"], case["case"], target)
            if case["expected_rc"] == 4:
                eligible = {int(row[:10]) for row in
                            (target / "eligible-master.dat").read_bytes().splitlines()}
                assert eligible == set(case["eligible_account_ids"]), case["case"]
                txseq = {int(row[11:26]) for row in
                         (target / "eligible-transaction.dat").read_bytes().splitlines()}
                assert txseq == set(case["eligible_transaction_ordinals"]), case["case"]


def test_rc_is_idempotent_and_l2_reject_is_separate():
    for isolated_count in (2, 3, 4):
        with tempfile.TemporaryDirectory(prefix="b03-many-isolated-") as td:
            root = Path(td)
            base_snap = (BASE / "customer-snapshot.dat").read_bytes()
            rows = base_snap.splitlines()
            rows = [row[:19] + b"D" + row[20:] for row in rows]
            if isolated_count >= 3:
                rows.append(b"0000000320261009001D0010000000008000")
            if isolated_count >= 4:
                rows.append(b"0000000420261009001D0010000000008000")
            snap = root / "snapshot.dat"
            snap.write_bytes(b"\n".join(rows) + b"\n")
            prev_rows = (BASE / "previous-day.dat").read_bytes().splitlines()
            if isolated_count >= 3:
                prev_rows.append(b"0000000320261008001000000+0000000000000")
            if isolated_count >= 4:
                prev_rows.append(b"0000000420261008001000000+0000000000000")
            prev = root / "previous.dat"
            prev.write_bytes(b"\n".join(prev_rows) + b"\n")
            out = root / "isolated"
            invoke(snap, prev, 4, f"{isolated_count} isolated customers", out)
            fields = dict(zip((out / "control.txt").read_bytes()
                              .rstrip(b" \n").decode().split("|")[::2],
                              (out / "control.txt").read_bytes()
                              .rstrip(b" \n").decode().split("|")[1::2]))
            assert int(fields["CUSTOMERS-ISOLATED"]) == isolated_count
            assert int(fields["ACCOUNTS"]) == 3

    with tempfile.TemporaryDirectory(prefix="b03-l2-reject-") as td:
        root = Path(td)
        txs = (BASE / "transaction.dat").read_bytes().splitlines()
        txs.append(b"0000000001P00000000000000520261009000003D0000000009999N")
        txs.sort(key=lambda row: (row[:10], row[34:40], row[10:26]))
        tx = root / "tx.dat"
        tx.write_bytes(b"\n".join(txs) + b"\n")
        out = root / "l2-rejected"
        command = ["bash", str(RUN), str(BASE / "account.dat"), str(tx),
                   str(BASE / "reversal-link.dat"),
                   str(BASE / "customer-snapshot.dat"),
                   str(BASE / "previous-day.dat"), str(out), "20261009"]
        result = subprocess.run(command, text=True, capture_output=True)
        assert result.returncode == 4, (result.returncode, result.stdout,
                                        result.stderr)
        assert out.is_dir() and (out / "rejected-l2.dat").stat().st_size > 0
        assert (out / "control.txt").read_bytes().find(b"L2-REJECT|1") >= 0


def test_locked_no_clobber_and_bad_physical_record():
    with tempfile.TemporaryDirectory(prefix="b03-guards-") as td:
        root = Path(td)
        locked = root / "locked"
        lock = Path(str(locked) + ".lock")
        lock.mkdir()
        invoke(BASE / "customer-snapshot.dat", BASE / "previous-day.dat",
               12, "existing lock", locked)
        assert lock.is_dir()
        lock.rmdir()
        bad = root / "no-lf.dat"
        bad.write_bytes((BASE / "customer-snapshot.dat").read_bytes().rstrip(b"\n"))
        invoke(bad, BASE / "previous-day.dat", 8, "missing final LF",
               root / "bad")

        source = (BASE / "customer-snapshot.dat").read_bytes()
        first, second = source.splitlines()
        variants = {
            "short": first[:-1] + b"\n" + second + b"\n",
            "long": first + b"X\n" + second + b"\n",
            "crlf": source.replace(b"\n", b"\r\n"),
            "tab": source.replace(b"A", b"\t", 1),
            "nul": source.replace(b"A", b"\x00", 1),
            "version": source.replace(b"001A", b"002A", 1),
            "duplicate": source + first + b"\n",
            "reverse": second + b"\n" + first + b"\n",
        }
        for name, data in variants.items():
            candidate = root / f"{name}.dat"
            candidate.write_bytes(data)
            invoke(candidate, BASE / "previous-day.dat", 8,
                   f"raw snapshot {name}", root / f"reject-{name}")


def test_all_16_input_eof_combinations():
    with tempfile.TemporaryDirectory(prefix="b03-eof-matrix-") as td:
        root = Path(td)
        account_row = b"000000000100000001JPY+0000000000100A20261009001\n"
        tx_row = b"0000000001T00000000000000120261009000001C0000000000010N\n"
        snapshot_row = b"0000000120261009001A0010000000001000\n"
        previous_row = b"0000000120261008001000001+0000000000100\n"
        for mask in range(16):
            a, t, s, p = (bool(mask & (1 << bit)) for bit in range(4))
            account = root / f"account-{mask}.dat"
            transaction = root / f"tx-{mask}.dat"
            reversal = root / f"link-{mask}.dat"
            snapshot = root / f"snapshot-{mask}.dat"
            previous = root / f"previous-{mask}.dat"
            account.write_bytes(account_row if a else b"")
            transaction.write_bytes(tx_row if t else b"")
            reversal.write_bytes(b"")
            snapshot.write_bytes(snapshot_row if s else b"")
            previous.write_bytes(previous_row if p else b"")
            if not a and not t and not s and not p:
                expected = 0
            elif not a and not s and not p and t:
                expected = 4
            elif a and s and p and (not t or t):
                expected = 0
            else:
                expected = 4
            invoke(snapshot, previous, expected, f"EOF mask {mask:04b}",
                   root / f"out-{mask}", account=account,
                   transaction=transaction, reversal=reversal)


def test_calendar_boundaries():
    cases = (("20240229", "20240228"),
             ("20240301", "20240229"),
             ("20240101", "20231231"),
             ("20260301", "20260228"))
    with tempfile.TemporaryDirectory(prefix="b03-calendar-") as td:
        root = Path(td)
        for index, (today, yesterday) in enumerate(cases):
            copies = {}
            for name, start, end, date in (
                ("account", 36, 44, today),
                ("transaction", 26, 34, today),
                ("customer-snapshot", 8, 16, today),
                ("previous-day", 8, 16, yesterday),
            ):
                raw = (BASE / f"{name}.dat").read_bytes()
                updated = raw
                original = raw.splitlines()[0][start:end]
                updated = updated.replace(original, date.encode())
                copies[name] = root / f"{name}-{index}.dat"
                copies[name].write_bytes(updated)
            invoke(copies["customer-snapshot"], copies["previous-day"],
                   0, f"calendar {today}", root / f"out-{index}",
                   account=copies["account"],
                   transaction=copies["transaction"],
                   reversal=BASE / "reversal-link.dat",
                   business_date=today)
        invoke(BASE / "customer-snapshot.dat", BASE / "previous-day.dat",
               8, "non-Gregorian date", root / "bad-date",
               business_date="20230229")



if __name__ == "__main__":
    test_nonmonotone_normal()
    test_independent_business_matrix()
    test_rc_is_idempotent_and_l2_reject_is_separate()
    test_locked_no_clobber_and_bad_physical_record()
    test_all_16_input_eof_combinations()
    test_calendar_boundaries()
    print("PASS: B03 four-stream N:N suite")
