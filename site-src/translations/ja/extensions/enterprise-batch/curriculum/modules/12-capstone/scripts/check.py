#!/usr/bin/env python3
"""End-to-end acceptance checks for module 12 (capstone).

Exercises the full 32-node nightly chain over the four contracted day types
(normal / abnormal / rerun / extension), the fail-safe broken day, the layout
guard, control reconciliation against an independent account, the crash/
recovery labs, the no-clobber/lock protections, the starter's RC12-no-publish
behaviour and the maintenance RED->GREEN.  Asserts against independently
accounted expected files; never treats a course program's own stdout as the
source of truth.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
REPO = MODULE.parents[2]
RUN = MODULE / "scripts/run.sh"
FIXTURES = MODULE / "fixtures"
EXPECTED = MODULE / "expected"
INSTRUCTOR = REPO / "instructor/modules/12-capstone"
DB_DATE = "20261010"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fail(message: str) -> None:
    raise AssertionError(message)


def run_night(input_dir: Path, output: Path, db: Path, run_id: str, layout: str,
              crash: str | None = None, cwd: Path | None = None,
              env: dict | None = None):
    command = ["bash", str(RUN), "--input", str(input_dir), "--output", str(output),
               "--db", str(db), "--business-date", DB_DATE, "--layout", layout,
               "--run-id", run_id]
    if crash:
        command += ["--crash-at", crash]
    full = dict(os.environ)
    if env:
        full.update(env)
    # 夜間チェーンは学習者の CUSTV2/BANKVAL を実行します。作成用リポジトリでは、
    # 学習者の完成版の代わりに参考実装を使います。学生向けバンドルでは環境変数で指定します。
    ref_custv2 = MODULE / "system/cobol/CUSTV2.COB"
    if "CAPSTONE_STUDENT_CUSTV2" not in full and ref_custv2.is_file():
        full["CAPSTONE_STUDENT_CUSTV2"] = str(ref_custv2)
    ref_bankval = REPO / "instructor/modules/10-jobs/BANKVAL.COB"
    if "CAPSTONE_STUDENT_BANKVAL" not in full and ref_bankval.is_file():
        full["CAPSTONE_STUDENT_BANKVAL"] = str(ref_bankval)
    return subprocess.run(command, text=True, capture_output=True, env=full,
                          cwd=cwd)


def expected_pairs(case: str, suffix: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in (EXPECTED / f"{case}.{suffix}").read_text().splitlines():
        key, _, value = line.partition("=")
        values[key] = value
    return values


def read_rows(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    rows = data[:-1].split(b"\n") if data.endswith(b"\n") else data.split(b"\n")
    rows = [r for r in rows if r]
    for row in rows:
        if len(row) != width:
            fail(f"{path} width {len(row)} != {width}")
    return rows


def signed(sign: bytes, digits: bytes) -> int:
    value = int(digits.decode("ascii"))
    return -value if sign == b"-" else value


def compute_control(run_dir: Path, db: Path) -> dict[str, int]:
    conf = {}
    for line in (run_dir / "work/validate/control.txt").read_text().splitlines():
        for item in line.split("|")[1:]:
            key, _, value = item.partition("=")
            if value.isdigit():
                conf[key] = int(value)
    accepted = read_rows(run_dir / "work/closing/accepted.dat", 55)
    rejected = [l for l in (run_dir / "work/closing/rejected.dat").read_text()
                .splitlines() if l.strip()]
    opening = read_rows(run_dir / "work/db/account_master.dat", 47)
    closing = read_rows(run_dir / "work/closing/master.dat", 47)
    ledger = [l for l in (db / "ledger.dat").read_text().splitlines()
              if l.startswith(DB_DATE + "|")]
    credits = sum(int(r[41:54]) for r in accepted if r[40:41] == b"C")
    debits = sum(int(r[41:54]) for r in accepted if r[40:41] == b"D")
    return {
        "received": conf["RECEIVED"],
        "validate_accepted": conf["ACCEPTED"],
        "validate_rejected": conf["REJECTED"],
        "match_accepted": len(accepted),
        "match_rejected": len(rejected),
        "ledger_applied": len(ledger),
        "accounts": len(opening),
        "opening_total": sum(signed(r[21:22], r[22:35]) for r in opening),
        "credit_total": credits,
        "debit_total": debits,
        "closing_total": sum(signed(r[21:22], r[22:35]) for r in closing),
    }


def verify_manifest(run_dir: Path, run_id: str) -> None:
    result = subprocess.run(
        ["python3", str(REPO / "curriculum/modules/10-jobs/lib/verify_publish.py"),
         "--dir", str(run_dir / "publish" / run_id), "--run-id", run_id,
         "--business-date", DB_DATE], text=True, capture_output=True)
    if result.returncode != 0:
        fail(f"manifest verify: {result.stderr}")


def compare_case(case: str, run_dir: Path, db: Path, run_id: str) -> None:
    expected = expected_pairs(case, "control.txt")
    got = compute_control(run_dir, db)
    for key, value in expected.items():
        if got[key] != int(value):
            fail(f"{case}: control {key} {got[key]} != {value}")
    exp_close = expected_pairs(case, "closing.txt")
    master = read_rows(run_dir / "publish" / run_id / "closing-master.dat", 47)
    got_close = {r[:10].decode(): r[21:35].decode() for r in master}
    if got_close != exp_close:
        fail(f"{case}: closing {got_close} != {exp_close}")
    exp_day: dict[str, str] = {}
    for line in (EXPECTED / f"{case}.customerday.txt").read_text().splitlines():
        parts = line.split("|")
        exp_day[parts[0]] = f"{parts[1]}|{parts[2]}|{parts[3]}"
    day = read_rows(run_dir / "publish" / run_id / "customer-day.dat", 30)
    got_day = {r[:8].decode(): f"{r[8:10].decode()}|{r[10:16].decode()}|"
                                f"{r[16:30].decode()}" for r in day}
    if got_day != exp_day:
        fail(f"{case}: customer-day {got_day} != {exp_day}")
    verify_manifest(run_dir, run_id)


def check_day(case: str, layout: str, rc: int) -> None:
    with tempfile.TemporaryDirectory(prefix=f"m12-{case}-") as temp:
        root = Path(temp)
        output, db = root / ("out " + case), root / "db"
        before = {p.name: sha256(p) for p in (FIXTURES / case).iterdir() if p.is_file()}
        result = run_night(FIXTURES / case, output, db, "d-" + case, layout)
        if result.returncode != rc:
            fail(f"{case}: rc {result.returncode} != {rc}\n{result.stderr[-800:]}")
        after = {p.name: sha256(p) for p in (FIXTURES / case).iterdir() if p.is_file()}
        if before != after:
            fail(f"{case}: run modified its fixture")
        if rc == 8:
            if output.exists():
                fail(f"{case}: failure published output")
            return
        compare_case(case, output, db, "d-" + case)
        if not (output / "state/complete.marker").is_file():
            fail(f"{case}: no completion marker")
        verified = subprocess.run(["sha256sum", "-c", "MANIFEST.sha256"],
                                  cwd=output / "publish" / ("d-" + case),
                                  text=True, capture_output=True)
        if verified.returncode != 0:
            fail(f"{case}: publish manifest: {verified.stderr}")


def check_fixture_manifest() -> None:
    result = subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=FIXTURES,
                            text=True, capture_output=True)
    if result.returncode != 0:
        fail("fixture SHA256SUMS: " + result.stdout + result.stderr)


def check_layout_guard() -> None:
    with tempfile.TemporaryDirectory(prefix="m12-guard-") as temp:
        root = Path(temp)
        output, db = root / "out", root / "db"
        result = run_night(FIXTURES / "extension", output, db, "g", "v1")
        if result.returncode != 8 or output.exists():
            fail(f"layout guard: rc={result.returncode} published={output.exists()}")


def check_rerun_idempotent() -> None:
    with tempfile.TemporaryDirectory(prefix="m12-rerun-") as temp:
        root = Path(temp)
        db = root / "db"
        first = run_night(FIXTURES / "normal", root / "o1", db, "first", "v1")
        if first.returncode != 0:
            fail("rerun first: " + first.stderr)
        before = (db / "account.table").read_bytes()
        ledger_before = (db / "ledger.dat").read_text()
        second = run_night(FIXTURES / "rerun", root / "o2", db, "second", "v1")
        if second.returncode != 0:
            fail("rerun second: " + second.stderr)
        if (db / "account.table").read_bytes() != before:
            fail("rerun double-debited")
        if (db / "ledger.dat").read_text() != ledger_before:
            fail("rerun changed the ledger")
        applied = json.loads((root / "o2/work/db/apply.json").read_text())
        if applied["new_transactions"] != 0:
            fail(f"rerun applied {applied['new_transactions']} transactions")
        if (root / "o2/publish/CURRENT").read_text().strip() != "second":
            fail("rerun CURRENT not updated")


def check_recovery() -> None:
    for point in ("before-db-commit", "mid-db-commit", "after-db-commit",
                  "during-publish", "after-publish"):
        with tempfile.TemporaryDirectory(prefix="m12-recover-") as temp:
            root = Path(temp)
            output, db, rid = root / "out", root / "db", "r-" + point
            crashed = run_night(FIXTURES / "normal", output, db, rid, "v1",
                                crash=point)
            if crashed.returncode != 97 or not output.is_dir():
                fail(f"{point}: crash rc={crashed.returncode}")
            recovered = run_night(FIXTURES / "normal", output, db, rid, "v1")
            if recovered.returncode != 0:
                fail(f"{point}: recover rc={recovered.returncode}\n"
                     + recovered.stderr[-500:])
            if (output / "publish/CURRENT").read_text().strip() != rid:
                fail(f"{point}: CURRENT mismatch")
            ledger = (db / "ledger.dat").read_text().splitlines()
            if len(ledger) != 6:
                fail(f"{point}: ledger {len(ledger)} != 6")
            verify_manifest(output, rid)


def check_no_clobber_and_lock() -> None:
    with tempfile.TemporaryDirectory(prefix="m12-protect-") as temp:
        root = Path(temp)
        db = root / "db"
        foreign = root / "foreign"
        foreign.mkdir()
        sentinel = foreign / "important.txt"
        sentinel.write_text("keep\n")
        result = run_night(FIXTURES / "normal", foreign, db, "x", "v1")
        if result.returncode != 12 or sentinel.read_text() != "keep\n":
            fail("no-clobber failed")
        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        (lock / "owner").write_text("other\n")
        result = run_night(FIXTURES / "normal", target, db, "x", "v1")
        if result.returncode != 12 or (lock / "owner").exists() is False:
            fail("output lock not honored")
        if target.exists():
            fail("locked target created")
        db.mkdir(parents=True, exist_ok=True)
        dblock = db / "locks" / f"{DB_DATE}.lock"
        dblock.mkdir(parents=True)
        (dblock / "pid").write_text(str(os.getpid()))
        result = run_night(FIXTURES / "normal", root / "concurrent", db, "live", "v1")
        if result.returncode != 12:
            fail("live business-date lock not honored")
        (dblock / "pid").write_text("999999")
        result = run_night(FIXTURES / "normal", root / "stale", db, "stale", "v1")
        if result.returncode != 0:
            fail("stale lock not reclaimed: " + result.stderr)


def check_system_failures() -> None:
    with tempfile.TemporaryDirectory(prefix="m12-sys-") as temp:
        root = Path(temp)
        shim = root / "bin"
        shim.mkdir()
        (shim / "mktemp").write_text("#!/bin/sh\nexit 1\n")
        (shim / "mktemp").chmod(0o755)
        output = root / "out spaces"
        result = run_night(FIXTURES / "normal", output, root / "db", "m", "v1",
                           env={"PATH": f"{shim}:{os.environ['PATH']}"})
        if result.returncode != 12 or output.exists():
            fail("mktemp failure not mapped to RC12 no-publish")
        if Path(str(output) + ".lock").exists():
            fail("lock leaked on system failure")
        result = run_night(root / "missinginput", root / "o2", root / "db3", "q", "v1")
        if result.returncode != 12:
            fail("missing input not RC12")


def check_starter() -> None:
    with tempfile.TemporaryDirectory(prefix="m12-starter-") as temp:
        root = Path(temp)
        build = subprocess.run(
            ["cobc", "-Wall", "-I", str(MODULE / "system/copybooks"), "-x",
             "-o", str(root / "custv2"), str(MODULE / "starter/CUSTV2.COB")],
            text=True, capture_output=True)
        if build.returncode != 0:
            fail("starter build failed: " + build.stderr)
        if not (root / "custv2").is_file():
            fail("starter build produced no binary")
        # v2 feed で未完成の starter が RC12 を返し、何も公開しないことを確認します。
        result = run_night(FIXTURES / "extension", root / "out", root / "db",
                           "s", "v2",
                           env={"CAPSTONE_STUDENT_CUSTV2":
                                str(MODULE / "starter/CUSTV2.COB")})
        if result.returncode != 12 or (root / "out").exists():
            fail(f"starter rc={result.returncode} published={(root / 'out').exists()}")


def check_control_gate() -> None:
    """A silently corrupted closing balance must be caught by report.py."""
    with tempfile.TemporaryDirectory(prefix="m12-gate-") as temp:
        root = Path(temp)
        work = root / "work"
        db = root / "db"
        (work / "validate").mkdir(parents=True)
        (work / "db").mkdir(parents=True)
        (work / "closing").mkdir(parents=True)
        db.mkdir()
        (work / "validate/control.txt").write_text(
            "CONTROL|RECEIVED=1|ACCEPTED=1|REJECTED=0\n")
        (work / "validate/accepted_tx.dat").write_bytes(b"")
        (work / "closing/accepted.dat").write_bytes(b"")
        (work / "closing/rejected.dat").write_bytes(b"")
        (work / "db/account_master.dat").write_bytes(
            b"000000000100000001JPY+0000000001000A20261010001\n")
        # close の申告値は 1500 ですが、期首(1000)+貸記(100) から算出できるのは 1100 までです。
        (work / "closing/master.dat").write_bytes(
            b"000000000100000001JPY+0000000001500A20261010001\n")
        (work / "closing/accepted.dat").write_bytes(
            ("0000000001" + "T000000000000001" + DB_DATE + "000001C"
             + f"{100:013d}" + "N" + "\n").encode())
        env = dict(os.environ, NIGHT_OUTPUT=str(root), NIGHT_DB=str(db),
                   NIGHT_DATE=DB_DATE)
        result = subprocess.run(
            ["python3", str(MODULE / "system/lib/report.py"), "amounts"],
            text=True, capture_output=True, env=env)
        if result.returncode != 8:
            fail(f"control gate did not catch corruption (rc={result.returncode})")


def check_source_format() -> None:
    sources = list((MODULE / "system/cobol").glob("*.COB")) + \
        list((MODULE / "system/copybooks").glob("*.CPY")) + \
        [MODULE / "starter/CUSTV2.COB"]
    for source in sources:
        for number, line in enumerate(source.read_text().splitlines(), 1):
            if not line.isascii():
                fail(f"{source}:{number} non-ASCII")
            if len(line) > 72:
                fail(f"{source}:{number} beyond column 72")
            if "\t" in line:
                fail(f"{source}:{number} tab")


def check_copybook_golden_bytes() -> None:
    """R08: freeze field offsets/PIC and the semantic byte positions.

    Parsing the copybooks (not trusting their comments) must reproduce the
    exact offsets of the frozen interfaces, and the extension feed's byte 27
    must be the record status, not a customer classification.
    """
    golden = {
        "CUSTOMER-V1.CPY": {
            "total": 27, "semantic": [("CV1-CUSTOMER-STATUS", 26, 1)]},
        "CAP-CUSTOMER-FEED-V1.CPY": {
            "total": 31,
            "semantic": [("EC1-RECORD-STATUS", 26, 1),
                         ("EC1-CUSTOMER-CLASSIFICATION", 27, 1),
                         ("EC1-LAYOUT-VERSION", 28, 3)]},
        "CAP-CUSTOMER-FEED-V2.CPY": {
            "total": 32,
            "semantic": [("EC2-RECORD-STATUS", 26, 1),
                         ("EC2-CUSTOMER-CLASSIFICATION", 27, 2),
                         ("EC2-LAYOUT-VERSION", 29, 3)]},
        "ACCOUNT-V1.CPY": {
            "total": 47, "semantic": [("AC1-BALANCE-SIGN", 21, 1),
                                      ("AC1-OPENING-BALANCE", 22, 13)]},
        "TRANSACTION-V1.CPY": {
            "total": 55, "semantic": [("TX1-DIRECTION", 40, 1),
                                      ("TX1-AMOUNT", 41, 13),
                                      ("TX1-STATUS", 54, 1)]},
    }
    for name, spec in golden.items():
        fields: list[tuple[str, int]] = []
        for line in (MODULE / "system/copybooks" / name).read_text().splitlines():
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0].isdigit() and parts[-2] == "PIC":
                name_part, pic = parts[1], parts[-1].rstrip(".")
                if pic.startswith("X("):
                    length = int(pic[2:-1])
                elif pic == "X":
                    length = 1
                else:
                    fail(f"{name}: unsupported PIC {pic}")
                fields.append((name_part, length))
        offsets: dict[str, tuple[int, int]] = {}
        cursor = 0
        for field_name, length in fields:
            offsets[field_name] = (cursor, length)
            cursor += length
        if cursor != spec["total"]:
            fail(f"{name}: field lengths sum to {cursor}, want {spec['total']}")
        for field_name, start, length in spec["semantic"]:
            if offsets.get(field_name) != (start, length):
                fail(f"{name}: {field_name} at {offsets.get(field_name)}, "
                     f"want {(start, length)}")

    # 意味上の golden bytes：extension v2 feed の第 27 バイトはレコード状態(A/D)、
    # 区分は第 28–29 バイトにあります。
    for row in read_rows(FIXTURES / "extension/customer.dat", 32):
        if row[26:27] not in (b"A", b"D"):
            fail(f"extension feed byte 27 not a status: {row[26:27]!r}")
        if row[27:29] not in (b"A1", b"B1", b"C1", b"D1"):
            fail(f"extension feed classification not A1..D1: {row[27:29]!r}")
    for row in read_rows(FIXTURES / "normal/customer.dat", 31):
        if row[26:27] not in (b"A", b"D"):
            fail(f"normal feed byte 27 not a status: {row[26:27]!r}")


def check_grader_rejects_empty() -> None:
    """R13: empty/unfilled deliverables must never be scored as complete.

    Imports the grader's own helpers (no subprocess, so no recursion into this
    acceptance script) and proves that empty files score zero, are listed as
    unfilled, and that an absent signoff keeps the manual outcomes pending.
    """
    import importlib.util
    grade_path = REPO / "instructor/modules/12-capstone/grading/grade.py"
    spec = importlib.util.spec_from_file_location("m12grade", grade_path)
    grader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(grader)
    with tempfile.TemporaryDirectory(prefix="m12-emptygrade-") as temp:
        sub = Path(temp)
        for rel in grader.MAINTENANCE_FILES + grader.MANUAL_ITEMS:
            path = sub / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("")            # 空ファイル
        score, missing, empty = grader.check_maintenance_files(sub)
        if missing or not empty:
            fail(f"empty files not flagged: missing={missing} empty={empty}")
        if score != 0:
            fail(f"empty deliverables scored {score} points")
        if grader.substantive(sub / "maintenance/impact-investigation.md"):
            fail("empty investigation counted as substantive")
        if grader.check_composition(sub)[0]:
            fail("empty composition counted as complete")
        # 見出し/placeholder のみのテンプレートも未完成です。
        (sub / "COMPOSITION.md").write_text("# 标题\nTODO 待填\n")
        if grader.substantive(sub / "COMPOSITION.md"):
            fail("placeholder-only template counted as substantive")
        if grader.check_signoff(sub / "missing-signoff.md"):
            fail("absent signoff accepted")
        # 外部から渡された見出しだけの signoff も合格してはいけません。
        bad_signoff = sub / "signoff.md"
        bad_signoff.write_text("# signoff\nTODO MANUAL-REVIEW-SIGNOFF G6\n")
        if grader.check_signoff(bad_signoff):
            fail("placeholder signoff accepted")


def check_red_green() -> None:
    """The maintenance change: RED (v1-only) then GREEN (v2) on a v2 feed."""
    with tempfile.TemporaryDirectory(prefix="m12-rg-") as temp:
        root = Path(temp)
        red = subprocess.run(
            ["bash", str(MODULE / "maintenance/regression/red-green.sh"), str(root)],
            text=True, capture_output=True)
        if red.returncode != 0:
            fail("RED->GREEN regression failed: " + red.stdout[-500:]
                 + red.stderr[-500:])
        red_rc = None
        for line in red.stdout.splitlines():
            if line.startswith("RED="):
                red_rc = int(line.split("=", 1)[1])
        if red_rc is None or red_rc == 0:
            fail("RED->GREEN: RED did not fail as expected: " + red.stdout)
        if "GREEN=0" not in red.stdout:
            fail("RED->GREEN: GREEN evidence missing: " + red.stdout)


def check_persistence_boundaries() -> None:
    """R02: no partial commit at any write-ahead boundary.

    The capstone idempotency ledger is written first and is authoritative;
    balances are derived from the frozen opening snapshot plus the ledger.
    Each boundary crash must recover with a single application, and an I/O
    failure of the ledger write must advance no balance.
    """
    capdb = MODULE / "system/lib/capdb.py"
    with tempfile.TemporaryDirectory(prefix="m12-bound-") as temp:
        root = Path(temp)
        setup = run_night(FIXTURES / "normal", root / "setup",
                          root / "setup-db", "seed", "v1",
                          crash="before-db-commit")
        assert setup.returncode == 97, setup.stderr
        accepted = root / "setup/work/closing/accepted.dat"
        candidate = root / "setup/work/closing/master.dat"
        assert accepted.is_file() and candidate.is_file()
        expected = expected_pairs("normal", "closing.txt")

        def fresh_db(name: str) -> Path:
            db = root / name
            for args in (
                ["seed", "--db", str(db),
                 "--account", str(FIXTURES / "normal/account_seed.dat"),
                 "--customer", str(FIXTURES / "normal/customer_seed.dat"),
                 "--business-date", DB_DATE, "--run-id", "bound",
                 "--layout", "v1"],
                ["snapshot", "--db", str(db), "--business-date", DB_DATE,
                 "--run-id", "bound"],
            ):
                done = subprocess.run(["python3", str(capdb)] + args,
                                      text=True, capture_output=True)
                assert done.returncode == 0, (args, done.stderr)
            return db

        def apply(db: Path, inject: str = ""):
            cmd = ["python3", str(capdb), "apply", "--db", str(db),
                   "--business-date", DB_DATE, "--run-id", "bound",
                   "--layout", "v1", "--accepted", str(accepted),
                   "--candidate-master", str(candidate)]
            if inject:
                cmd += ["--inject", inject]
            return subprocess.run(cmd, text=True, capture_output=True)

        for boundary in ("ledger", "mid", "after"):
            db = fresh_db("db-" + boundary)
            crashed = apply(db, boundary)
            assert crashed.returncode == 97, (boundary, crashed.stderr)
            recovered = apply(db)
            assert recovered.returncode == 0, (boundary, recovered.stderr)
            ledger = (db / "ledger.dat").read_text().splitlines()
            assert len(ledger) == 6, (boundary, ledger)
            balances = {row[:10].decode(): row[21:35].decode() for row in
                        read_rows(db / "account.table", 47)}
            assert balances == expected, (boundary, balances)
            again = apply(db)
            assert again.returncode == 0, again.stderr
            assert len((db / "ledger.dat").read_text().splitlines()) == 6, boundary

        db = fresh_db("db-ledger-io")
        opening = (db / "account.table").read_bytes()
        (db / "ledger.dat.tmp").mkdir()
        failed = apply(db)
        assert failed.returncode == 12, failed.stderr
        assert (db / "account.table").read_bytes() == opening, "partial commit!"
        assert not (db / "ledger.dat").exists()
        (db / "ledger.dat.tmp").rmdir()
        recovered = apply(db)
        assert recovered.returncode == 0, recovered.stderr
        balances = {row[:10].decode(): row[21:35].decode() for row in
                    read_rows(db / "account.table", 47)}
        assert balances == expected, balances


def check_publish_failure_preserved() -> None:
    """R03: a failure AFTER publish must not delete the published result.

    Crash during publish, then inject an I/O failure at the publish registry,
    completion marker and next-day preparation boundaries.  Each must return
    RC12 with the committed DB and published artifacts preserved, and a clean
    rerun must finish with no double debit.
    """
    with tempfile.TemporaryDirectory(prefix="m12-r03-") as temp:
        root = Path(temp)
        for point in ("registry", "complete", "nextday"):
            out = root / ("out-" + point)
            db = root / ("db-" + point)
            crashed = run_night(FIXTURES / "normal", out, db, "rid", "v1",
                                crash="during-publish")
            assert crashed.returncode == 97, (point, crashed.stderr)
            ledger = (db / "ledger.dat").read_text()
            committed = (db / "commit" / f"{DB_DATE}.json").is_file()
            faulted = run_night(FIXTURES / "normal", out, db, "rid", "v1",
                                env={"NIGHT_INJECT_FAIL": point})
            assert faulted.returncode == 12, (point, faulted.returncode)
            assert out.is_dir(), f"{point}: published output was deleted"
            assert (out / "publish" / "rid" / "manifest.json").is_file(), point
            assert (out / "publish/CURRENT").read_text().strip() == "rid", point
            assert committed, point
            assert (db / "ledger.dat").read_text() == ledger, point
            recovered = run_night(FIXTURES / "normal", out, db, "rid", "v1")
            assert recovered.returncode == 0, (point, recovered.stderr)
            assert (out / "state/complete.marker").is_file(), point
            assert (db / "ledger.dat").read_text() == ledger, point


def main() -> int:
    check_source_format()
    check_fixture_manifest()
    check_day("normal", "v1", 0)
    check_day("abnormal", "v1", 4)
    check_day("extension", "v2", 0)
    check_day("broken", "v1", 8)
    check_layout_guard()
    check_rerun_idempotent()
    check_recovery()
    check_persistence_boundaries()
    check_publish_failure_preserved()
    check_no_clobber_and_lock()
    check_system_failures()
    check_control_gate()
    # starter の RED 不変条件と講師採点器の検査は、完成版の隣に
    # 手付かずの starter がある作成者用リポジトリでのみ実行します。
    if INSTRUCTOR.is_dir():
        check_starter()
        check_grader_rejects_empty()
    check_copybook_golden_bytes()
    # RED->GREEN は、完成版と並んで手付かずの starter がある場合に必要です。
    if INSTRUCTOR.is_dir():
        check_red_green()
    print("PASS: module 12 capstone -- 4 day types, guard, rerun, recovery, "
          "persistence boundaries, locks, control gate, starter, RED->GREEN")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
