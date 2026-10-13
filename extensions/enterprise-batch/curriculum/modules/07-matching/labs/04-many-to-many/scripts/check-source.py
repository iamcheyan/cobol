#!/usr/bin/env python3
"""Source format, starter, build-failure and workspace-reset checks."""
import os
from pathlib import Path
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[4]


def main():
    source = REPO / "instructor/modules/07/04-many-to-many/BATCHL3.COB"
    for path in (source, *source.parent.glob("*.CPY"),
                 *list((LAB / "copybooks").glob("*.CPY")),
                 LAB / "starter/BATCHL3.COB"):
        for number, line in enumerate(path.read_bytes().splitlines(), 1):
            assert line.isascii() and b"\t" not in line and len(line) <= 72, (
                path, number)

    with tempfile.TemporaryDirectory(prefix="b03-source-") as td:
        root = Path(td)
        bad = root / "bad.COB"
        bad.write_text("       THIS IS NOT COBOL\n")
        target = root / "compile-failure"
        fixture = LAB / "fixtures/normal"
        command = ["bash", str(LAB / "scripts/run.sh"),
                   str(fixture / "account.dat"),
                   str(fixture / "transaction.dat"),
                   str(fixture / "reversal-link.dat"),
                   str(fixture / "customer-snapshot.dat"),
                   str(fixture / "previous-day.dat"),
                   str(target), "20261009"]
        result = subprocess.run(command, env=dict(os.environ, COURSE_SOURCE=str(bad)),
                                text=True, capture_output=True)
        assert result.returncode == 12 and not target.exists(), (
            result.returncode, result.stdout, result.stderr)
        starter = LAB / "starter/BATCHL3.COB"
        built_starter = root / "starter-binary"
        build = subprocess.run(["bash", str(LAB / "scripts/build.sh"),
                                str(built_starter), str(starter)],
                               capture_output=True, text=True)
        assert build.returncode == 0 and built_starter.is_file(), (
            build.returncode, build.stdout, build.stderr)
        target = root / "starter"
        result = subprocess.run(command[:-2] + [str(target), "20261009"],
                                env=dict(os.environ,
                                         COURSE_SOURCE=str(starter)),
                                text=True, capture_output=True)
        assert result.returncode == 12 and not target.exists(), (
            result.returncode, result.stdout, result.stderr)

        workspace = root / "workspace"
        subprocess.run(["bash", str(LAB / "scripts/init-workspace.sh"),
                        str(workspace)], check=True)
        (workspace / "artifact.dat").write_bytes(b"keep")
        student_source = workspace / "BATCHL3.COB"
        student_source.write_text("student changes\n")
        student_notes = workspace / "NOTES.md"
        student_notes.write_text("retain this work\n")
        (workspace / "output").mkdir()
        (workspace / "output/result.dat").write_bytes(b"generated output")
        (workspace / "batchl3").write_text("generated binary\n")
        lock = workspace / "running.lock"
        lock.mkdir()
        result = subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                                 str(workspace)], capture_output=True)
        assert result.returncode == 12
        assert (workspace / "artifact.dat").read_bytes() == b"keep"
        assert lock.is_dir()
        lock.rmdir()
        subprocess.run(["bash", str(LAB / "scripts/reset.sh"),
                        str(workspace)], check=True)
        assert (workspace / ".b03-workspace").is_file()
        assert (workspace / "artifact.dat").read_bytes() == b"keep"
        assert not (workspace / "output").exists()
        assert student_source.read_text() == "student changes\n"
        assert student_notes.read_text() == "retain this work\n"
        assert not (workspace / "batchl3").exists()

        # Exercise malformed snapshot/previous bytes in the COBOL executable,
        # bypassing the Python runner's outer input handling.
        core = root / "core"
        built = subprocess.run(["bash", str(LAB / "scripts/build.sh"),
                                str(core), str(source)],
                               capture_output=True, text=True)
        assert built.returncode == 0, (built.returncode, built.stderr)
        l2 = root / "l2"
        l2run = REPO / "curriculum/modules/07-matching/labs/03-one-to-many/scripts/run.sh"
        l2_result = subprocess.run(["bash", str(l2run),
                                    str(fixture / "account.dat"),
                                    str(fixture / "transaction.dat"),
                                    str(fixture / "reversal-link.dat"),
                                    str(l2), "20261009"],
                                   capture_output=True, text=True)
        assert l2_result.returncode == 0, (l2_result.returncode,
                                           l2_result.stdout, l2_result.stderr)
        snapshot_source = (fixture / "customer-snapshot.dat").read_bytes()
        previous_source = (fixture / "previous-day.dat").read_bytes()
        malformed = {
            "snapshot-no-lf": (snapshot_source.rstrip(b"\n"), previous_source),
            "snapshot-crlf": (snapshot_source.replace(b"\n", b"\r\n"), previous_source),
            "snapshot-tab": (snapshot_source.replace(b"A", b"\t", 1), previous_source),
            "snapshot-nul": (snapshot_source.replace(b"A", b"\x00", 1), previous_source),
            "snapshot-short": (snapshot_source[:-2] + b"\n", previous_source),
            "snapshot-long": (snapshot_source.replace(b"\n", b"X\n", 1), previous_source),
            "previous-no-lf": (snapshot_source, previous_source.rstrip(b"\n")),
            "previous-crlf": (snapshot_source, previous_source.replace(b"\n", b"\r\n")),
            "previous-tab": (snapshot_source, previous_source.replace(b"+", b"\t", 1)),
            "previous-nul": (snapshot_source, previous_source.replace(b"+", b"\x00", 1)),
            "previous-short": (snapshot_source, previous_source[:-2] + b"\n"),
            "previous-long": (snapshot_source, previous_source.replace(b"\n", b"X\n", 1)),
        }
        for name, (snap_bytes, prev_bytes) in malformed.items():
            case_dir = root / name
            case_dir.mkdir()
            snap = case_dir / "snapshot.dat"
            prev = case_dir / "previous.dat"
            snap.write_bytes(snap_bytes)
            prev.write_bytes(prev_bytes)
            env = dict(os.environ, LC_ALL="C", COB_SORT_MEMORY="2M",
                       B03_ACCOUNT_FILE=str(fixture / "account.dat"),
                       B03_MASTER_FILE=str(l2 / "master.dat"),
                       B03_ACCEPT_FILE=str(l2 / "accepted.dat"),
                       B03_REJECT_FILE=str(l2 / "rejected.dat"),
                       B03_SNAPSHOT_FILE=str(snap), B03_PREVIOUS_FILE=str(prev),
                       B03_SNAPSHOT_NORMAL=str(case_dir / "snapshot.normal"),
                       B03_PREVIOUS_NORMAL=str(case_dir / "previous.normal"),
                       B03_ACCOUNT_FEED=str(case_dir / "account.feed"),
                       B03_TX_FEED=str(case_dir / "tx.feed"),
                       B03_SPOOL_FILE=str(case_dir / "spool"),
                       B03_ELIGIBLE_MASTER=str(case_dir / "master.out"),
                       B03_ELIGIBLE_TX=str(case_dir / "tx.out"),
                       B03_TOTALS_FILE=str(case_dir / "totals.out"),
                       B03_STATUS_FILE=str(case_dir / "status.out"),
                       B03_ISOLATION_FILE=str(case_dir / "isolation.out"),
                       B03_CONTROL_FILE=str(case_dir / "control.out"),
                       B03_BUSINESS_DATE="20261009", B03_L2_RC="0")
            direct = subprocess.run([str(core)], env=env,
                                     capture_output=True, text=True)
            assert direct.returncode == 8, (name, direct.returncode,
                                             direct.stdout, direct.stderr)

        # The real BATCHL3 executable writes each candidate to /dev/full;
        # the production runner must reject the incomplete candidate set.
        replacements = {
            "master": ('ACCEPT ELIGIBLE-MASTER-PATH FROM\n'
                       '               ENVIRONMENT "B03_ELIGIBLE_MASTER"',
                       'MOVE "/dev/full" TO ELIGIBLE-MASTER-PATH'),
            "transactions": ('ACCEPT ELIGIBLE-TX-PATH FROM ENVIRONMENT "B03_ELIGIBLE_TX"',
                             'MOVE "/dev/full" TO ELIGIBLE-TX-PATH'),
            "control": ('ACCEPT CONTROL-PATH FROM ENVIRONMENT "B03_CONTROL_FILE"',
                        'MOVE "/dev/full" TO CONTROL-PATH'),
        }
        original = source.read_text()
        for label, (needle, replacement) in replacements.items():
            assert original.count(needle) == 1, label
            variant = root / f"full-{label}.COB"
            variant.write_text(original.replace(needle, replacement))
            target = root / f"full-output-{label}"
            result = subprocess.run(command[:-2] + [str(target), "20261009"],
                                    env=dict(os.environ,
                                             COURSE_SOURCE=str(variant)),
                                    text=True, capture_output=True)
            assert result.returncode == 12 and not target.exists(), (
                label, result.returncode, result.stdout, result.stderr)

        fakebin = root / "fakebin"
        fakebin.mkdir()
        sha_shim = fakebin / "sha256sum"
        sha_shim.write_text("#!/usr/bin/env bash\n"
                            "for arg in \"$@\"; do\n"
                            "  [[ $arg == -c ]] && exit 1\n"
                            "done\n"
                            "exec /usr/bin/sha256sum \"$@\"\n")
        sha_shim.chmod(0o755)
        target = root / "checksum-failure"
        env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}")
        result = subprocess.run(command[:-2] + [str(target), "20261009"],
                                env=env, text=True, capture_output=True)
        assert result.returncode == 12 and not target.exists(), (
            "prepublish checksum failure", result.returncode,
            result.stdout, result.stderr)
    print("PASS: B03 source, starter, compile failure and reset guards")


if __name__ == "__main__":
    main()
