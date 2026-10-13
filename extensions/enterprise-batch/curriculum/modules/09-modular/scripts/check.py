#!/usr/bin/env python3
"""End-to-end contract checks for module 09 (CALL/LINKAGE modularisation)."""
from pathlib import Path
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
SCRIPTS = LAB / "scripts"
INSTRUCTOR = REPO / "instructor" / "modules" / "09-modular"
# Shared subprograms shipped inside the learner bundle (provided modules, not
# the exercise answer).  The instructor tree wins when present.
LIB = LAB / "lib"
DATE = "20261010"


def lib_dir() -> Path:
    if (INSTRUCTOR / "AMTCALC.COB").is_file():
        return INSTRUCTOR
    return LIB


def ref_source() -> Path:
    """The completed BATCH09 source: explicit COURSE_SOURCE wins, else the
    instructor reference, else the learner's own starter."""
    env = os.environ.get("COURSE_SOURCE")
    if env:
        return Path(env)
    if (INSTRUCTOR / "BATCH09.COB").is_file():
        return INSTRUCTOR / "BATCH09.COB"
    return LAB / "starter" / "BATCH09.COB"

PROBE_EXPECTED = [
    "BY-REF     AFTER=BBBBB",
    "BY-CONTENT AFTER=BBBBB",
    "BY-VALUE   N-BEFORE=+0000000042",
    "BY-VALUE   N-AFTER=+0000000042",
    "STATIC     CALL1=0001",
    "STATIC     CALL2=0002",
    "INITIAL    CALL1=0001",
    "INITIAL    CALL2=0001",
    "AMT-OK     RC=000 BAL=+0000000001500 REASON=OK",
    "AMT-VER    RC=008 REASON=IFACE-VERSION",
    "AMT-LEN    RC=008 REASON=IFACE-LENGTH",
    "AMT-ZERO   RC=004 REASON=ZERO-AMOUNT",
    "AMT-OVERD  RC=004 REASON=OVERDRAFT",
    "AMT-OVFL   RC=004 REASON=OVERFLOW",
    "AMT-DIR    RC=004 REASON=BAD-DIRECTION",
    "AMT-NUM    RC=004 REASON=AMT-NOT-NUMERIC",
]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def case_inputs(case: str) -> list[Path]:
    import oracle
    d = oracle.case_dir(case)
    return [d / "customer.dat", d / "account.dat", d / "transaction.dat"]


def run_case(case: str, rc: int, expect_report: bool,
             source: Path | None = None, date: str = DATE) -> subprocess.CompletedProcess:
    with tempfile.TemporaryDirectory(prefix="bank09-check-") as tmp:
        output = Path(tmp) / ("output with spaces" if case == "normal" else "out")
        inputs = case_inputs(case)
        before = {p.name: digest(p) for p in inputs}
        env = dict(os.environ)
        if source is not None:
            env["COURSE_SOURCE"] = str(source)
        cmd = ["bash", str(SCRIPTS / "run.sh"), *(str(p) for p in inputs),
               str(output), date]
        proc = subprocess.run(cmd, cwd=tmp, env=env, text=True,
                              capture_output=True)
        assert proc.returncode == rc, (case, proc.returncode, proc.stdout,
                                       proc.stderr)
        after = {p.name: digest(p) for p in inputs}
        assert before == after, f"{case}: run changed an original fixture"
        if not expect_report:
            assert not output.exists(), f"{case}: failed run published output"
            return proc
        assert output.is_dir()
        expected = (LAB / "expected" / f"{case}.txt").read_text()
        actual = (output / "report.txt").read_text()
        assert actual == expected, f"{case}: report mismatch\n{actual}"
        for manifest in ("inputs.sha256", "outputs.sha256"):
            verified = subprocess.run(["sha256sum", "-c", manifest],
                                      cwd=output, text=True,
                                      capture_output=True)
            assert verified.returncode == 0, (case, manifest, verified.stdout,
                                              verified.stderr)
        return proc


def check_sources() -> None:
    files = [*LAB.rglob("*.COB"), *LAB.rglob("*.CPY")]
    if INSTRUCTOR.is_dir():
        files += [*INSTRUCTOR.rglob("*.COB"), *INSTRUCTOR.rglob("*.CPY")]
    assert files, "no sources found"
    headers = re.compile(
        r"^(DIVISION|SECTION|PROGRAM-ID|PROCEDURE|FD|SD)\b", re.IGNORECASE)
    paragraph = re.compile(r"^\d{4}-[A-Z0-9-]+\.$")
    for path in files:
        for n, line in enumerate(path.read_text().splitlines(), 1):
            assert line.isascii() and "\t" not in line, (path, n)
            assert len(line) <= 72, (path, n, "beyond column 72")
            if not line.strip() or line.lstrip().startswith("*"):
                continue
            col = len(line) - len(line.lstrip()) + 1
            assert 8 <= col <= 72, (path, n, "content before Area B")
            stripped = line.strip()
            level = re.match(r"^(\d\d)\s", stripped)
            if level:
                if level.group(1) in ("01", "77"):
                    assert 8 <= col <= 11, (path, n, "01/77 must be Area A")
                else:
                    assert col >= 12, (path, n, "level must be Area B")
            elif headers.match(stripped) or paragraph.match(stripped):
                assert 8 <= col <= 11, (path, n, "header must be Area A")


def check_fixture_manifest() -> None:
    verified = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                              cwd=LAB / "fixtures", text=True,
                              capture_output=True)
    assert verified.returncode == 0, verified.stdout + verified.stderr


def check_expected_selfconsistent() -> None:
    cases = json.loads((LAB / "expected" / "cases.json").read_text())
    sys.path.insert(0, str(SCRIPTS))
    import oracle
    for case, rc in cases.items():
        inputs = case_inputs(case)
        try:
            result = oracle.compute(inputs[0].read_bytes(),
                                    inputs[1].read_bytes(),
                                    inputs[2].read_bytes())
        except oracle.ContractError:
            result = None
        if rc in (0, 4):
            assert result is not None and result["rc"] == rc, case
            assert result["report"] == (
                LAB / "expected" / f"{case}.txt").read_text(), case
        else:
            assert result is None, f"{case} unexpectedly satisfied contract"


def check_all_cases() -> None:
    cases = json.loads((LAB / "expected" / "cases.json").read_text())
    for case, rc in cases.items():
        run_case(case, rc, expect_report=rc in (0, 4))


def check_starter_and_faults() -> None:
    # finished learner source (reference in the authoring repo)
    reference = ref_source().read_text()
    faults = [
        ("AMT-VERSION", "MOVE '001' TO AMT-IFACE-VERSION",
         "MOVE '002' TO AMT-IFACE-VERSION"),
        ("CUST-VERSION", "MOVE '001' TO CVL-IFACE-VERSION",
         "MOVE '002' TO CVL-IFACE-VERSION"),
        ("AMT-LENGTH", "MOVE LENGTH OF AMT-CALC-INTERFACE TO AMT-IFACE-LENGTH",
         "MOVE 1 TO AMT-IFACE-LENGTH"),
    ]
    with tempfile.TemporaryDirectory(prefix="bank09-fault-") as tmp:
        for name, old, new in faults:
            assert reference.count(old) == 1, name
            source = Path(tmp) / f"{name}.COB"
            source.write_text(reference.replace(old, new))
            proc = run_case("normal", 8, expect_report=False, source=source)
            assert "INTERFACE-MISMATCH" in proc.stderr, (name, proc.stderr)
    # RED: the pristine starter (with the instructor reference present) must
    # compile but return 12 and publish nothing.  Authoring-only invariant.
    if INSTRUCTOR.is_dir():
        run_case("normal", 12, expect_report=False,
                 source=LAB / "starter" / "BATCH09.COB")


def check_probe() -> None:
    with tempfile.TemporaryDirectory(prefix="bank09-probe-") as tmp:
        binary = Path(tmp) / "ifaceprobe"
        build = subprocess.run(
            ["cobc", "-Wall", "-I", str(LAB / "copybooks"), "-x",
             "-o", str(binary), str(SCRIPTS / "ifaceprobe.COB"),
             str(lib_dir() / "AMTCALC.COB")],
            text=True, capture_output=True)
        assert build.returncode == 0, build.stderr
        run = subprocess.run([str(binary)], text=True, capture_output=True)
        assert run.returncode == 0, run.stderr
        lines = run.stdout.splitlines()
        assert lines == PROBE_EXPECTED, (lines, PROBE_EXPECTED)


def check_lock_and_protection() -> None:
    inputs = [str(p) for p in case_inputs("normal")]
    base = ["bash", str(SCRIPTS / "run.sh"), *inputs]
    with tempfile.TemporaryDirectory(prefix="bank09-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(base + [str(existing), DATE],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"

        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        (lock / "owner").write_text("owned\n")
        failed = subprocess.run(base + [str(target), DATE],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and not target.exists()

        concurrent = root / "concurrent out"
        commands = base + [str(concurrent), DATE]
        first = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        second = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE)
        first.communicate()
        second.communicate()
        assert sorted((first.returncode, second.returncode)) == [0, 12], (
            first.returncode, second.returncode)
        assert (concurrent / "report.txt").read_text() == (
            LAB / "expected" / "normal.txt").read_text()
        assert not Path(str(concurrent) + ".lock").exists()


def check_verifier_rejects_tampering() -> None:
    with tempfile.TemporaryDirectory(prefix="bank09-tamper-") as temp:
        root = Path(temp)
        output = root / "out"
        inputs = case_inputs("normal")
        run = subprocess.run(["bash", str(SCRIPTS / "run.sh"),
                              *(str(p) for p in inputs), str(output), DATE],
                             text=True, capture_output=True)
        assert run.returncode == 0, run.stderr
        verify = ["python3", str(SCRIPTS / "verify-publish.py"),
                  *(str(p) for p in inputs), DATE,
                  str(output / "report.txt"), str(output / "ledger.dat"),
                  str(output / "customers-valid.dat"),
                  str(output / "customers-rejected.dat"),
                  str(output / "batch09.log")]
        assert subprocess.run(verify, text=True,
                              capture_output=True).returncode == 0
        for name in ("report.txt", "ledger.dat", "batch09.log"):
            path = output / name
            original = path.read_bytes()
            path.write_bytes(original.replace(b"0", b"1", 1))
            bad = subprocess.run(verify, text=True, capture_output=True)
            assert bad.returncode == 12, (name, bad.stdout)
            path.write_bytes(original)
        reset = subprocess.run(["bash", str(SCRIPTS / "reset.sh"),
                                str(output)], text=True, capture_output=True)
        assert reset.returncode == 0 and not output.exists(), reset.stderr


def check_build_and_reset() -> None:
    with tempfile.TemporaryDirectory(prefix="bank09-build-") as temp:
        root = Path(temp)
        binary = root / "batch09"
        build = subprocess.run(["bash", str(SCRIPTS / "build.sh"),
                                str(binary)], text=True, capture_output=True)
        assert build.returncode == 0 and binary.is_file(), build.stderr
        broken = root / "broken.COB"
        broken.write_text("not COBOL\n")
        failed_target = root / "must-not-exist"
        failed = subprocess.run(["bash", str(SCRIPTS / "build.sh"),
                                 str(failed_target), str(broken)],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and not failed_target.exists()
        unmarked = root / "keep"
        unmarked.mkdir()
        marker = unmarked / "important.txt"
        marker.write_text("keep\n")
        refused = subprocess.run(["bash", str(SCRIPTS / "reset.sh"),
                                  str(unmarked)], text=True,
                                 capture_output=True)
        assert refused.returncode == 12 and marker.read_text() == "keep\n"


def check_no_partial_publish() -> None:
    """A system-level LOGGER failure must map to RC12 with no output."""
    with tempfile.TemporaryDirectory(prefix="bank09-failclosed-") as temp:
        root = Path(temp)
        source = ref_source().read_text()
        old = "           ACCEPT R-PATH FROM ENVIRONMENT 'REJECT_OUTPUT'"
        new = "           MOVE '/nonexistent-dir/reject.dat' TO R-PATH"
        assert source.count(old) == 1
        bad_source = root / "badpath.COB"
        bad_source.write_text(source.replace(old, new))
        output = root / "must-not-publish"
        env = dict(os.environ, COURSE_SOURCE=str(bad_source))
        proc = subprocess.run(
            ["bash", str(SCRIPTS / "run.sh"),
             *(str(p) for p in case_inputs("normal")), str(output), DATE],
            env=env, text=True, capture_output=True)
        assert proc.returncode == 12 and not output.exists(), (
            proc.returncode, proc.stderr)


def check_global_dup_txid() -> None:
    """R04: global transaction_id duplicates are fatal RC8 and never published.
    The JOB-level uniqueness gate is not bypassable by COURSE_SOURCE."""
    for case in ("dup-global-txid", "dup-cross-account"):
        proc = run_case(case, 8, expect_report=False)
        assert "duplicate global transaction_id" in proc.stderr, (case, proc.stderr)
        # any student source still cannot bypass the JOB gate
        proc = run_case(case, 8, expect_report=False,
                        source=ref_source())
        assert "duplicate global transaction_id" in proc.stderr, (case, proc.stderr)

    # the review's exact counterexample: normal run, 3rd transaction id
    # replaced by the 1st. Was RC0+publish before the global check.
    with tempfile.TemporaryDirectory(prefix="bank09-dup-repro-") as temp:
        root = Path(temp)
        rows = [t for t in (LAB / "fixtures/normal/transaction.dat")
                .read_bytes().split(b"\n") if t]
        rows[2] = rows[2][:10] + rows[0][10:26] + rows[2][26:]
        dup = root / "transaction.dat"
        dup.write_bytes(b"\n".join(rows) + b"\n")
        customer = (LAB / "fixtures/normal/customer.dat").read_bytes()
        account = (LAB / "fixtures/normal/account.dat").read_bytes()
        out = root / "out"
        proc = subprocess.run(
            ["bash", str(SCRIPTS / "run.sh"),
             str(LAB / "fixtures/normal/customer.dat"),
             str(LAB / "fixtures/normal/account.dat"), str(dup),
             str(out), DATE], text=True, capture_output=True)
        assert proc.returncode == 8, (proc.returncode, proc.stderr)
        assert not out.exists(), "duplicate txid published"
        assert "duplicate global transaction_id" in proc.stderr, proc.stderr
        sys.path.insert(0, str(SCRIPTS))
        import oracle
        try:
            oracle.compute(customer, account, dup.read_bytes())
            raise AssertionError("oracle accepted a duplicate global txid")
        except oracle.ContractError:
            pass


def main() -> None:
    check_sources()
    check_fixture_manifest()
    check_expected_selfconsistent()
    check_all_cases()
    check_global_dup_txid()
    check_starter_and_faults()
    check_probe()
    check_lock_and_protection()
    check_verifier_rejects_tampering()
    check_build_and_reset()
    check_no_partial_publish()
    print("PASS: module 09 CALL/LINKAGE contracts and failure paths")


if __name__ == "__main__":
    main()
