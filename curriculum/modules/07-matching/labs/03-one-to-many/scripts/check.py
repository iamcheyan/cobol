#!/usr/bin/env python3
"""End-to-end contract checks for the 1:N Boss L2 lab."""
from pathlib import Path
import hashlib
import os
import stat
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[4]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed_lf_records(path: Path, width: int) -> list[bytes]:
    data = path.read_bytes()
    records = data.split(b"\n")
    assert records[-1] == b"", f"missing final LF: {path}"
    records.pop()
    assert all(len(row) == width and b"\r" not in row for row in records), path
    return records


def run_case(case: str, rc: int, business_date: str = "20261009",
             source: Path | None = None) -> str:
    with tempfile.TemporaryDirectory(prefix="bank-l2-check-") as tmp:
        output = Path(tmp) / ("output with spaces" if case ==
                              "boundary-aggregate-over-13" else "published")
        input_dir = LAB / "fixtures" / case
        before = {name: digest(input_dir / name) for name in
                  ("account.dat", "transaction.dat", "reversal-link.dat")}
        env = dict(os.environ)
        if source is not None:
            env["COURSE_SOURCE"] = str(source)
        cmd = ["bash", str(LAB / "scripts/run.sh"),
               str(input_dir / "account.dat"),
               str(input_dir / "transaction.dat"),
               str(input_dir / "reversal-link.dat"),
               str(output), business_date]
        proc = subprocess.run(cmd, cwd=tmp, env=env, text=True,
                              capture_output=True)
        assert proc.returncode == rc, (proc.returncode, proc.stdout, proc.stderr)
        after = {name: digest(input_dir / name) for name in before}
        assert before == after, "run changed an original fixture"
        if rc in (8, 12):
            assert not output.exists(), "failed run published an output directory"
            return proc.stderr
        assert output.is_dir()
        expected_bytes = (LAB / "expected" / f"{case}.txt").read_bytes()
        expected = expected_bytes.decode("ascii")
        actual_bytes = (output / "report.txt").read_bytes()
        actual = actual_bytes.decode("ascii")
        assert actual == expected, f"report mismatch\n{actual}"
        expected_rows = {}
        for row in expected.splitlines():
            if row.startswith("TX|"):
                _, tx_id, result, value = row.split("|", 3)
                expected_rows[tx_id] = (result, value)
        tx_rows = fixed_lf_records(input_dir / "transaction.dat", 55)
        accepted = [row + b"\n" for row in tx_rows
                    if expected_rows[row[10:26].decode("ascii")][0] == "ACCEPT"]
        rejected = [row + b"|" +
                    expected_rows[row[10:26].decode("ascii")][1].encode("ascii")
                    + b"\n" for row in tx_rows
                    if expected_rows[row[10:26].decode("ascii")][0] == "REJECT"]
        assert (output / "accepted.dat").read_bytes() == b"".join(accepted)
        assert (output / "rejected.dat").read_bytes() == b"".join(rejected)
        account_rows = fixed_lf_records(input_dir / "account.dat", 47)
        balances = {row.split("|", 2)[1]: row.split("|", 2)[2]
                    for row in expected.splitlines()
                    if row.startswith("ACCOUNT|")}
        masters = []
        for row in account_rows:
            identifier = row[:10].decode("ascii")
            sign_amount = balances[identifier].encode("ascii")
            masters.append(row[:21] + sign_amount + row[35:] + b"\n")
        assert (output / "master.dat").read_bytes() == b"".join(masters)
        verified = subprocess.run(["sha256sum", "-c", "inputs.sha256"],
                                  cwd=output, text=True, capture_output=True)
        assert verified.returncode == 0, verified.stdout + verified.stderr
        outputs_verified = subprocess.run(["sha256sum", "-c", "outputs.sha256"],
                                          cwd=output, text=True,
                                          capture_output=True)
        assert outputs_verified.returncode == 0, (
            outputs_verified.stdout + outputs_verified.stderr)
        assert proc.stdout == "PASS: business and control totals verified\n"
        return actual


def check_lock_and_output_protection() -> None:
    fixture = LAB / "fixtures" / "normal"
    command_base = ["bash", str(LAB / "scripts" / "run.sh"),
                    str(fixture / "account.dat"),
                    str(fixture / "transaction.dat"),
                    str(fixture / "reversal-link.dat")]
    with tempfile.TemporaryDirectory(prefix="bank-l2-protect-") as temp:
        root = Path(temp)
        existing = root / "existing"
        existing.mkdir()
        sentinel = existing / "keep.txt"
        sentinel.write_text("preserve\n")
        failed = subprocess.run(command_base + [str(existing), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and sentinel.read_text() == "preserve\n"

        target = root / "locked"
        lock = Path(str(target) + ".lock")
        lock.mkdir()
        marker = lock / "owner"
        marker.write_text("another run owns this lock\n")
        failed = subprocess.run(command_base + [str(target), "20261009"],
                                text=True, capture_output=True)
        assert failed.returncode == 12 and marker.exists() and not target.exists()

        concurrent = root / "concurrent output"
        commands = command_base + [str(concurrent), "20261009"]
        first = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
        second = subprocess.Popen(commands, text=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE)
        p1 = first.communicate()
        p2 = second.communicate()
        assert sorted((first.returncode, second.returncode)) == [4, 12], (p1, p2)
        assert (concurrent / "report.txt").read_text() == (
            LAB / "expected" / "normal.txt").read_text()
        assert not Path(str(concurrent) + ".lock").exists()


def check_build_and_reset() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-l2-build-reset-") as temp:
        root = Path(temp)
        binary = root / "batchl2"
        build = subprocess.run(["bash", str(LAB / "scripts/build.sh"),
                                str(binary)], text=True, capture_output=True)
        assert build.returncode == 0 and binary.is_file(), build.stderr
        broken_source = root / "broken.COB"
        broken_source.write_text("not COBOL\n")
        failed_target = root / "must-not-exist"
        failed_build = subprocess.run(
            ["bash", str(LAB / "scripts/build.sh"), str(failed_target),
             str(broken_source)], text=True, capture_output=True)
        assert failed_build.returncode == 12 and not failed_target.exists()
        unmarked = root / "keep"
        unmarked.mkdir()
        marker = unmarked / "important.txt"
        marker.write_text("keep\n")
        refused = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                  str(unmarked)], text=True, capture_output=True)
        assert refused.returncode == 12 and marker.read_text() == "keep\n"
        output = root / "course-output"
        fixture = LAB / "fixtures" / "normal"
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture / "account.dat"),
                              str(fixture / "transaction.dat"),
                              str(fixture / "reversal-link.dat"),
                              str(output), "20261009"],
                             text=True, capture_output=True)
        assert run.returncode == 4 and output.is_dir()
        verifier_args = ["python3", str(LAB / "scripts/verify-publish.py"),
                         str(fixture / "account.dat"),
                         str(fixture / "transaction.dat"),
                         str(output / "report.txt"), str(output / "master.dat"),
                         str(output / "accepted.dat"), str(output / "rejected.dat")]
        valid = subprocess.run(verifier_args, text=True, capture_output=True)
        assert valid.returncode == 0, valid.stderr
        accepted_file = output / "accepted.dat"
        accepted_bytes = accepted_file.read_bytes()
        accepted_file.write_bytes(accepted_bytes[:-1])
        truncated = subprocess.run(verifier_args, text=True, capture_output=True)
        assert truncated.returncode == 12
        accepted_file.write_bytes(accepted_bytes)
        master_file = output / "master.dat"
        master_bytes = master_file.read_bytes()
        master_file.write_bytes(master_bytes.replace(b"\n", b"\r\n", 1))
        crlf_master = subprocess.run(verifier_args, text=True, capture_output=True)
        assert crlf_master.returncode == 12
        master_file.write_bytes(master_bytes)
        rejected_file = output / "rejected.dat"
        rejected_bytes = rejected_file.read_bytes()
        rejected_file.write_bytes(rejected_bytes[:-1])
        unterminated_reject = subprocess.run(verifier_args, text=True,
                                             capture_output=True)
        assert unterminated_reject.returncode == 12
        rejected_file.write_bytes(rejected_bytes)
        report_file = output / "report.txt"
        report_bytes = report_file.read_bytes()
        bad_report = report_bytes.replace(b"ACCOUNT|0000000001|+0000000000800",
                                          b"ACCOUNT|0000000001|+0000000000801", 1)
        assert bad_report != report_bytes
        report_file.write_bytes(bad_report)
        bad_amount = subprocess.run(verifier_args, text=True, capture_output=True)
        assert bad_amount.returncode == 12
        report_file.write_bytes(report_bytes)
        reset = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                str(output)], text=True, capture_output=True)
        assert reset.returncode == 0 and not output.exists(), reset.stderr


def check_full_device_fail_closed() -> None:
    full = Path("/dev/full")
    if not full.exists() or not stat.S_ISCHR(full.stat().st_mode):
        return
    source_text = """       IDENTIFICATION DIVISION.
       PROGRAM-ID. FULL-OUTPUT-PROBE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT P-FILE ASSIGN TO DYNAMIC P-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS P-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD P-FILE.
       01 P-RECORD PIC X.
       WORKING-STORAGE SECTION.
       01 P-PATH PIC X(4096).
       01 P-STATUS PIC XX.
       PROCEDURE DIVISION.
           ACCEPT P-PATH FROM ENVIRONMENT 'FULL_PATH'
           OPEN OUTPUT P-FILE
           MOVE 'X' TO P-RECORD
           WRITE P-RECORD
           CLOSE P-FILE
           DISPLAY 'PROBE-STATUS=' P-STATUS UPON STDERR
           MOVE 4 TO RETURN-CODE
           GOBACK.
"""
    with tempfile.TemporaryDirectory(prefix="bank-l2-full-device-") as temp:
        root = Path(temp)
        reference = root / "batchl2"
        subprocess.run(["cobc", "-Wall", "-I",
                        str(REPO / "curriculum/bank/copybooks"), "-x",
                        "-o", str(reference),
                        str(REPO / "instructor/modules/07/03-one-to-many/BATCHL2.COB")],
                       check=True)
        fixture = LAB / "fixtures" / "normal"
        for failed_output in ("MASTER_OUTPUT_FILE", "ACCEPT_OUTPUT_FILE",
                              "REJECT_OUTPUT_FILE"):
            env = dict(os.environ, ACCOUNT_FILE=str(fixture / "account.dat"),
                       TRANSACTION_FILE=str(fixture / "transaction.dat"),
                       REVERSAL_FILE=str(fixture / "reversal-link.dat"),
                       BUSINESS_DATE="20261009", LEDGER_FILE=str(root / f"{failed_output}.ledger"),
                       LINKS_FILE=str(root / f"{failed_output}.links"),
                       MASTER_OUTPUT_FILE=str(root / f"{failed_output}.master"),
                       ACCEPT_OUTPUT_FILE=str(root / f"{failed_output}.accepted"),
                       REJECT_OUTPUT_FILE=str(root / f"{failed_output}.rejected"))
            env[failed_output] = "/dev/full"
            core = subprocess.run([str(reference)], env=env, capture_output=True)
            assert core.returncode == 4, (failed_output, core.returncode,
                                          core.stderr)
        source = root / "full-probe.COB"
        source.write_text(source_text)
        output = root / "must-not-publish"
        env = dict(os.environ, COURSE_SOURCE=str(source), FULL_PATH="/dev/full")
        run = subprocess.run(["bash", str(LAB / "scripts/run.sh"),
                              str(fixture / "account.dat"),
                              str(fixture / "transaction.dat"),
                              str(fixture / "reversal-link.dat"),
                              str(output), "20261009"],
                             env=env, text=True, capture_output=True)
        assert run.returncode == 12 and not output.exists(), (
            run.returncode, run.stderr)
        assert "PROBE-STATUS=00" in run.stderr, run.stderr
        core_source = (REPO / "instructor/modules/07/03-one-to-many/BATCHL2.COB").read_text()
        fields = {"MASTER_OUTPUT_FILE": "O-PATH",
                  "ACCEPT_OUTPUT_FILE": "A-PATH",
                  "REJECT_OUTPUT_FILE": "J-PATH"}
        env_names = {"MASTER_OUTPUT_FILE": "master.dat",
                     "ACCEPT_OUTPUT_FILE": "accepted.dat",
                     "REJECT_OUTPUT_FILE": "rejected.dat"}
        for environment_name, cobol_path in fields.items():
            assignment = (f"           ACCEPT {cobol_path} FROM ENVIRONMENT "
                          f"'{environment_name}'")
            assert core_source.count(assignment) == 1
            failed_source = root / f"{environment_name}.COB"
            failed_source.write_text(core_source.replace(
                assignment, f"           MOVE '/dev/full' TO {cobol_path}"))
            failed_target = root / f"must-not-publish-{environment_name}"
            failed_env = dict(os.environ, COURSE_SOURCE=str(failed_source))
            failed = subprocess.run(
                ["bash", str(LAB / "scripts/run.sh"),
                 str(fixture / "account.dat"),
                 str(fixture / "transaction.dat"),
                 str(fixture / "reversal-link.dat"),
                 str(failed_target), "20261009"],
                env=failed_env, text=True, capture_output=True)
            assert failed.returncode == 12 and not failed_target.exists(), (
                environment_name, failed.returncode, failed.stderr)
            assert "publish verification failed" in failed.stderr
            assert env_names[environment_name] in failed.stderr


def main() -> None:
    for source in (REPO / "instructor/modules/07/03-one-to-many/BATCHL2.COB",
                   LAB / "starter/BATCHL2.COB",
                   LAB / "scripts/indexed-probe.COB"):
        lines = source.read_text().splitlines()
        assert all("\t" not in line and len(line) <= 72 for line in lines), source
    manifest = subprocess.run(["sha256sum", "-c", "SHA256SUMS"],
                              cwd=LAB / "fixtures", text=True,
                              capture_output=True)
    assert manifest.returncode == 0, manifest.stdout + manifest.stderr
    for name, expected_rc in (
        ("normal", 4), ("bad-reversal-reference", 4),
        ("business-cross-account-reversal", 4),
        ("business-already-reversed", 4),
        ("business-original-not-accepted", 4),
        ("business-orphan-transaction", 4),
        ("business-orphan-linked", 4),
        ("business-closed-account", 4),
        ("business-reversal-mismatch", 4),
        ("business-future-reference", 4),
        ("boundary-zero-amount", 4), ("boundary-overflow", 4),
        ("boundary-max-amount", 0),
        ("boundary-aggregate-over-13", 0),
        ("boundary-no-transactions", 0), ("boundary-empty-all", 0),
    ):
        run_case(name, expected_rc)
    for name in ("duplicate-id-cross-account", "short-transaction",
                 "unsorted-transactions", "invalid-link-key",
                 "invalid-link-id", "invalid-link-sequence",
                 "invalid-unused-link"):
        run_case(name, 8)
    run_case("boundary-empty-all", 0, "20240229")
    run_case("boundary-empty-all", 8, "20260230")
    run_case("normal", 12, source=LAB / "starter" / "BATCHL2.COB")
    check_lock_and_output_protection()
    check_build_and_reset()
    check_full_device_fail_closed()
    subprocess.run(["python3", str(LAB / "scripts" / "check-indexed.py")],
                   check=True)
    print("PASS: L2 normal and invalid contracts")


if __name__ == "__main__":
    main()
