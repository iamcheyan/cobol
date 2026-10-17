#!/usr/bin/env python3
"""End-to-end acceptance checks for module 10 (JOB operations).

Exercises the full JOB001..JOB009 chain, RC policy, locks, no-clobber,
snapshots, publication, idempotent rerun and the crash/recovery labs.
Asserts against independently accounted expected files; never treats a
course program's own stdout as the source of truth.
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
DATE = "20261009"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected_control(case: str) -> dict[str, int]:
    values = {}
    for line in (EXPECTED / f"{case}.control.txt").read_text().splitlines():
        key, _, value = line.partition("=")
        values[key] = int(value)
    return values


def actual_control(run_dir: Path) -> dict[str, int]:
    values = {}
    for line in (run_dir / "work/control/control.txt").read_text().splitlines():
        key, _, value = line.partition("=")
        values[key] = int(value)
    return values


def expected_closing(case: str) -> dict[str, str]:
    values = {}
    for line in (EXPECTED / f"{case}.closing.txt").read_text().splitlines():
        acct, _, value = line.partition("=")
        values[acct] = value
    return values


def run_night(input_dir: Path, output: Path, db: Path, run_id: str,
              crash: str | None = None, course_source: Path | None = None,
              env: dict | None = None, cwd: Path | None = None):
    command = ["bash", str(RUN), "--input", str(input_dir),
               "--output", str(output), "--db", str(db),
               "--business-date", DATE, "--run-id", run_id]
    if crash:
        command += ["--crash-at", crash]
    full_env = dict(os.environ)
    if course_source is not None:
        full_env["BANK_COURSE_SOURCE"] = str(course_source)
    if env:
        full_env.update(env)
    return subprocess.run(command, text=True, capture_output=True,
                          env=full_env, cwd=cwd)


def verify_manifest(run_dir: Path, run_id: str) -> None:
    result = subprocess.run(
        ["python3", str(MODULE / "lib/verify_publish.py"),
         "--dir", str(run_dir / "publish" / run_id),
         "--run-id", run_id, "--business-date", DATE],
        text=True, capture_output=True)
    assert result.returncode == 0, result.stderr


def check_fixture(case: str, rc: int) -> None:
    with tempfile.TemporaryDirectory(prefix="m10-check-") as temp:
        root = Path(temp)
        output = root / ("out " + case)
        db = root / "db"
        before = {p.name: sha256(p) for p in (FIXTURES / case).iterdir()
                  if p.is_file()}
        result = run_night(FIXTURES / case, output, db, "c-" + case)
        assert result.returncode == rc, (case, result.returncode, result.stderr)
        after = {p.name: sha256(p) for p in (FIXTURES / case).iterdir()
                 if p.is_file()}
        assert before == after, f"{case}: run modified its fixture"
        if rc in (8, 12):
            assert not output.exists(), f"{case}: failure published output"
            return
        assert actual_control(output) == expected_control(case), case
        assert (output / "state/complete.marker").is_file(), case
        verify_manifest(output, "c-" + case)
        master = (output / "publish" / ("c-" + case) /
                  "closing-master.dat").read_text().splitlines()
        got = {row[:10]: row[21:35] for row in master}
        assert got == expected_closing(case), (case, got)
        # SHA256SUMS in publish must verify.
        verified = subprocess.run(
            ["sha256sum", "-c", "MANIFEST.sha256"],
            cwd=output / "publish" / ("c-" + case), text=True,
            capture_output=True)
        assert verified.returncode == 0, verified.stderr


def check_fixture_manifest() -> None:
    result = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                            cwd=FIXTURES, text=True, capture_output=True)
    assert result.returncode == 0, result.stdout + result.stderr


def check_no_clobber_and_lock() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-protect-") as temp:
        root = Path(temp)
        db = root / "db"
        foreign = root / "foreign"
        foreign.mkdir()
        sentinel = foreign / "important.txt"
        sentinel.write_text("keep\n")
        result = run_night(FIXTURES / "normal", foreign, db, "x")
        assert result.returncode == 12 and sentinel.read_text() == "keep\n"
        # A pre-existing output lock is honored.
        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        (lock / "owner").write_text("other run\n")
        result = run_night(FIXTURES / "normal", target, db, "x")
        assert result.returncode == 12 and (lock / "owner").exists()
        assert not target.exists()
        # A live business-date lock rejects a concurrent same-day run.
        db.mkdir(parents=True, exist_ok=True)
        dblock = db / "locks" / f"{DATE}.lock"
        dblock.mkdir(parents=True)
        (dblock / "pid").write_text(str(os.getpid()))
        result = run_night(FIXTURES / "normal", root / "concurrent", db, "live-lock")
        assert result.returncode == 12, result.stderr
        # A stale lock (dead pid) is reclaimed.
        (dblock / "pid").write_text("999999")
        result = run_night(FIXTURES / "normal", root / "stale-lock", db, "stale-lock")
        assert result.returncode == 4, result.stderr


def check_system_failures() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-sys-") as temp:
        root = Path(temp)
        shim = root / "bin"
        shim.mkdir()
        (shim / "mktemp").write_text("#!/bin/sh\nexit 1\n")
        (shim / "mktemp").chmod(0o755)
        output = root / "out spaces"
        result = run_night(FIXTURES / "normal", output, root / "db", "m",
                           env={"PATH": f"{shim}:{os.environ['PATH']}"})
        assert result.returncode == 12 and not output.exists(), result.stderr
        assert not Path(str(output) + ".lock").exists()
        # Missing output parent.
        result = run_night(FIXTURES / "normal", root / "nope" / "deep",
                           root / "db2", "p")
        assert result.returncode == 12
        # Unreadable input.
        result = run_night(root / "missinginput", root / "out2", root / "db3", "q")
        assert result.returncode == 12


def check_starter() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-starter-") as temp:
        root = Path(temp)
        # The starter must build on its own in any bundle.
        target = root / "starter-bin"
        build = subprocess.run(
            ["bash", str(MODULE / "scripts/build.sh"), str(target),
             str(MODULE / "starter/BANKVAL.COB")],
            text=True, capture_output=True)
        assert build.returncode == 0 and target.is_file(), build.stderr
        # RED invariant: only meaningful with the pristine starter beside the
        # instructor reference. In a student bundle the learner completes the
        # starter, so skip it there.
        if not (REPO / "instructor/modules/10-jobs/BANKVAL.COB").exists():
            return
        output = root / "out"
        result = run_night(FIXTURES / "normal", output, root / "db", "s",
                           course_source=MODULE / "starter/BANKVAL.COB")
        assert result.returncode == 12 and not output.exists(), result.stderr


def check_recovery() -> None:
    for point in ("before-db-commit", "mid-db-commit", "after-db-commit",
                  "during-publish", "after-publish"):
        with tempfile.TemporaryDirectory(prefix="m10-recover-") as temp:
            root = Path(temp)
            output = root / "out"
            db = root / "db"
            rid = "r-" + point
            crashed = run_night(FIXTURES / "normal", output, db, rid,
                                crash=point)
            assert crashed.returncode == 97, (point, crashed.returncode,
                                              crashed.stderr)
            assert output.is_dir(), point
            recovered = run_night(FIXTURES / "normal", output, db, rid)
            assert recovered.returncode == 4, (point, recovered.returncode,
                                               recovered.stderr)
            assert (output / "state/complete.marker").is_file(), point
            assert (output / "publish/CURRENT").read_text().strip() == rid
            verify_manifest(output, rid)
            # No duplicate application: exactly the 4 accepted transactions.
            ledger = (db / "ledger.dat").read_text().splitlines()
            assert len(ledger) == 4, (point, ledger)
            balances = {row[:10]: row[21:35] for row in
                        (db / "account.table").read_text().splitlines()}
            assert balances == expected_closing("normal"), (point, balances)
            # Confirm resume worked: earlier stages were not re-executed.
            log = (output / "logs/nightly.log").read_text()
            assert "resume: already complete" in log, point


def check_rerun_idempotent() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-rerun-") as temp:
        root = Path(temp)
        db = root / "db"
        first = run_night(FIXTURES / "normal", root / "o1", db, "first")
        assert first.returncode == 4, first.stderr
        before = (db / "account.table").read_bytes()
        ledger_before = (db / "ledger.dat").read_text()
        second = run_night(FIXTURES / "normal", root / "o2", db, "second")
        assert second.returncode == 4, second.stderr
        assert (db / "account.table").read_bytes() == before, "double debit!"
        assert (db / "ledger.dat").read_text() == ledger_before
        applied = json.loads((root / "o2/work/db/apply.json").read_text())
        assert applied["new_transactions"] == 0, applied
        # Old results must not masquerade as this run: CURRENT is per --output.
        assert (root / "o2/publish/CURRENT").read_text().strip() == "second"


def check_snapshot_immutable() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-snap-") as temp:
        root = Path(temp)
        db = root / "db"
        first = run_night(FIXTURES / "normal", root / "o1", db, "s1")
        assert first.returncode == 4, first.stderr
        snap = db / "snapshots" / DATE / "account_master.dat"
        snap.write_bytes(snap.read_bytes().replace(b"0000000001000",
                                                   b"0000000002000", 1))
        result = run_night(FIXTURES / "normal", root / "o2", db, "s2")
        assert result.returncode == 12 and not (root / "o2").exists(), \
            result.stderr


def check_stale_result_rejected() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-stale-") as temp:
        root = Path(temp)
        db = root / "db"
        run_night(FIXTURES / "normal", root / "o", db, "good")
        manifest = root / "o/publish/good/manifest.json"
        data = json.loads(manifest.read_text())
        data["run_id"] = "someone-else"
        manifest.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
        result = subprocess.run(
            ["python3", str(MODULE / "lib/verify_publish.py"),
             "--dir", str(root / "o/publish/good"),
             "--run-id", "good", "--business-date", DATE],
            text=True, capture_output=True)
        assert result.returncode == 12, result.stderr
        # Rerunning into a completed output is refused.
        again = run_night(FIXTURES / "normal", root / "o", db, "good")
        assert again.returncode == 12


def check_precedence() -> None:
    with tempfile.TemporaryDirectory(prefix="m10-precedence-") as temp:
        root = Path(temp)
        db = root / "db"
        inputs = FIXTURES / "normal"
        cfg_a = root / "a.conf"
        cfg_a.write_text(f"input={inputs}\noutput={root / 'cfg-a'}\n"
                         f"db={db}\nbusiness_date={DATE}\nrun_id=a\n")
        cfg_b = root / "b.conf"
        cfg_b.write_text(f"input={inputs}\noutput={root / 'cfg-b'}\n"
                         f"db={db}\nbusiness_date={DATE}\nrun_id=b\n")
        # The config file alone supplies every required parameter.
        result = subprocess.run(["bash", str(RUN), "--config", str(cfg_a)],
                                text=True, capture_output=True)
        assert result.returncode == 4 and (root / "cfg-a").is_dir(), result.stderr
        # CLI overrides the config file.
        result = subprocess.run(
            ["bash", str(RUN), "--config", str(cfg_a), "--output", str(root / "cli")],
            text=True, capture_output=True)
        assert result.returncode == 4 and (root / "cli").is_dir(), result.stderr
        # Environment is lower priority than file/CLI: config output beats BANK_OUTPUT.
        env_out = root / "env"
        result = subprocess.run(
            ["bash", str(RUN), "--config", str(cfg_b)],
            text=True, capture_output=True,
            env=dict(os.environ, BANK_OUTPUT=str(env_out)))
        assert result.returncode == 4 and (root / "cfg-b").is_dir(), result.stderr
        assert not env_out.exists(), "env overrode the config file"


def check_source_format() -> None:
    sources = [MODULE / "starter/BANKVAL.COB",
               MODULE / "copybooks/CUSTOMER-V1.CPY"]
    # The instructor reference is an authoring artifact; absent in a bundle.
    instructor = REPO / "instructor/modules/10-jobs/BANKVAL.COB"
    if instructor.exists():
        sources.insert(1, instructor)
    for source in sources:
        for number, line in enumerate(source.read_text().splitlines(), 1):
            assert line.isascii(), (source, number, "non-ASCII")
            assert len(line) <= 72, (source, number, "beyond column 72")
            assert "\t" not in line, (source, number, "tab")


def check_persistence_boundaries() -> None:
    """R02: no partial commit at any write-ahead boundary.

    The idempotency ledger is written first and is authoritative; balances are
    derived from the frozen opening snapshot plus the ledger. For each boundary
    (after-ledger, after-balances, after-marker), a crash followed by one rerun
    must apply exactly once and leave balances == the candidate master. An I/O
    failure of the ledger write itself must not advance any balance.
    """
    with tempfile.TemporaryDirectory(prefix="m10-bound-") as temp:
        root = Path(temp)
        # A pre-commit crash gives us the day's accepted transactions + candidate.
        setup = run_night(FIXTURES / "normal", root / "setup", root / "setup-db",
                          "seed", crash="before-db-commit")
        assert setup.returncode == 97, setup.stderr
        accepted = root / "setup/work/closing/accepted.dat"
        candidate = root / "setup/work/closing/master.dat"
        assert accepted.is_file() and candidate.is_file()
        expected = expected_closing("normal")

        def fresh_db(name: str) -> Path:
            db = root / name
            for args in (
                ["seed", "--db", str(db),
                 "--account", str(FIXTURES / "normal/account_seed.dat"),
                 "--customer", str(FIXTURES / "normal/customer_seed.dat")],
                ["snapshot", "--db", str(db), "--business-date", DATE,
                 "--run-id", "bound"],
            ):
                done = subprocess.run(
                    ["python3", str(MODULE / "lib/db.py")] + args,
                    text=True, capture_output=True)
                assert done.returncode == 0, (args, done.stderr)
            return db

        def apply(db: Path, inject: str = ""):
            cmd = ["python3", str(MODULE / "lib/db.py"), "apply", "--db",
                   str(db), "--business-date", DATE, "--run-id", "bound",
                   "--accepted", str(accepted), "--candidate-master",
                   str(candidate)]
            if inject:
                cmd += ["--inject", inject]
            return subprocess.run(cmd, text=True, capture_output=True)

        for boundary in ("ledger", "mid", "after"):
            db = fresh_db("db-" + boundary)
            opening = (db / "account.table").read_bytes()
            crashed = apply(db, boundary)
            assert crashed.returncode == 97, (boundary, crashed.stderr)
            recovered = apply(db)
            assert recovered.returncode == 0, (boundary, recovered.stderr)
            ledger = (db / "ledger.dat").read_text().splitlines()
            assert len(ledger) == 4, (boundary, ledger)
            balances = {row[:10]: row[21:35] for row in
                        (db / "account.table").read_text().splitlines()}
            assert balances == expected, (boundary, balances)
            again = apply(db)
            assert again.returncode == 0, again.stderr
            assert len((db / "ledger.dat").read_text().splitlines()) == 4, boundary
            assert opening != b""  # sanity check: opening state was readable

        # I/O failure during ledger write must leave balances untouched.
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
        balances = {row[:10]: row[21:35] for row in
                    (db / "account.table").read_text().splitlines()}
        assert balances == expected, balances


def check_publish_failure_preserved() -> None:
    """R03: a failure AFTER publish must not delete the published result.

    Crash during publish (before anything is switched), then inject an I/O
    failure at each post-publish boundary (completion marker, next-day
    preparation). The run must return RC12 and keep the committed DB and
    published artifacts; a clean rerun must finish without a double debit.
    """
    with tempfile.TemporaryDirectory(prefix="m10-r03-") as temp:
        root = Path(temp)
        for point in ("complete", "nextday"):
            out = root / ("out-" + point)
            db = root / ("db-" + point)
            crashed = run_night(FIXTURES / "normal", out, db, "rid",
                                crash="during-publish")
            assert crashed.returncode == 97, (point, crashed.stderr)
            ledger = (db / "ledger.dat").read_text()
            assert (db / "commit" / f"{DATE}.json").is_file(), point
            faulted = run_night(FIXTURES / "normal", out, db, "rid",
                                env={"BANK_INJECT_FAIL": point})
            assert faulted.returncode == 12, (point, faulted.returncode)
            assert out.is_dir(), f"{point}: published output was deleted"
            assert (out / "publish" / "rid" / "manifest.json").is_file(), point
            assert (out / "publish/CURRENT").read_text().strip() == "rid", point
            assert (db / "ledger.dat").read_text() == ledger, point
            recovered = run_night(FIXTURES / "normal", out, db, "rid")
            assert recovered.returncode == 4, (point, recovered.stderr)
            assert (out / "state/complete.marker").is_file(), point
            assert (db / "ledger.dat").read_text() == ledger, point


def main() -> int:
    check_source_format()
    check_fixture_manifest()
    check_fixture("normal", 4)
    check_fixture("boundary-empty-tx", 0)
    check_fixture("boundary-single", 0)
    check_fixture("invalid-short-record", 8)
    check_fixture("invalid-long-record", 8)
    check_fixture("invalid-bad-digit", 8)
    check_no_clobber_and_lock()
    check_precedence()
    check_system_failures()
    check_starter()
    check_recovery()
    check_persistence_boundaries()
    check_publish_failure_preserved()
    check_rerun_idempotent()
    check_snapshot_immutable()
    check_stale_result_rejected()
    print("PASS: module 10 JOB chain, RC, lock, recovery, persistence "
          "boundaries and idempotency")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, ValueError, KeyError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
