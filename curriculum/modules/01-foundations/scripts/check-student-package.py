#!/usr/bin/env python3
"""R07 regression: the learner bundle must be runnable and answer-free.

This drives the real packaging script into a throwaway directory, unpacks the
tarball, and asserts two independent things:

* answer containment by role *and* content, not by filename alone;
* the module 01/05/06 JOBs still build and run inside the isolated bundle, so a
  learner never hits a missing instructor-only dependency.

The completed-source path is exercised by handing each JOB a reference copy as
a stand-in for the learner's finished work; the shipped starter must still fail
closed until the learner implements it.
"""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import tarfile
import tempfile

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
PACKAGER = REPO / "curriculum" / "scripts" / "package-student.sh"
ANSWER = REPO / "curriculum/modules/12-capstone/system/cobol/CUSTV2.COB"
ANSWER_STARTER = (REPO / "curriculum/modules/12-capstone/starter/CUSTV2.COB")

# module -> (lab, normal fixture, expected report name, expected file,
#            instructor reference, shipped starter)
JOBS = {
    "01": ("01-foundations", "fixtures/normal/account.dat",
           "control.txt", "expected/normal.control.txt",
           "01-foundations/BANK-ENTRY.COB", "01-foundations/BANK-ENTRY.COB"),
    "05": ("05-control", "fixtures/normal/clean.dat",
           "report.txt", "expected/normal-clean.txt",
           "05-control/CLEANSE.COB", "05-control/CLEANSE.COB"),
    "06": ("06-files", "fixtures/normal/valid.dat",
           "report.txt", "expected/normal-valid.txt",
           "06-files/FILEVAL.COB", "06-files/FILEVAL.COB"),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def leak_checks(unpacked: Path) -> None:
    shipped = [p for p in unpacked.rglob("*") if p.is_file()]
    assert shipped, "bundle is empty"
    # Role: no instructor material, by any path component.
    for path in shipped:
        parts = path.relative_to(unpacked).parts
        assert "instructor" not in parts, path
        assert path.name != "INSTRUCTOR.md", path
    rel = {p.relative_to(unpacked).as_posix() for p in shipped}
    # Role: the current exercise answer must be absent, its starter present.
    assert ANSWER.relative_to(REPO).as_posix() not in rel, "CUSTV2 answer shipped"
    assert ANSWER_STARTER.relative_to(REPO).as_posix() in rel, "starter missing"
    # Content: no shipped file may be a copy of the answer under any name.
    answer_digest = digest(ANSWER)
    for path in shipped:
        assert digest(path) != answer_digest, f"answer copy shipped as {path}"


def run_job(bundle: Path, lab: Path, fixture: str, output: Path, date: str,
            source: Path | None) -> subprocess.CompletedProcess:
    env = dict(os.environ)
    if source is not None:
        env["COURSE_SOURCE"] = str(source)
    return subprocess.run(
        ["bash", str(lab / "scripts/run.sh"), str(lab / fixture),
         str(output), date], env=env, text=True, capture_output=True)


def end_to_end(unpacked: Path, tmp: Path) -> None:
    for module, (name, fixture, report, expected, reference,
                 _starter) in JOBS.items():
        lab = unpacked / "curriculum/modules" / name
        # 1. The learner's exercise compiles from the bundle alone.
        binary = tmp / f"build-{module}"
        build = subprocess.run(
            ["bash", str(lab / "scripts/build.sh"), str(binary)],
            text=True, capture_output=True)
        assert build.returncode == 0 and binary.is_file(), (
            module, build.stdout, build.stderr)

        # 2. A finished learner source is acceptable: the reference stands in
        #    and must pass the full JOB against the shipped expected report.
        completed = tmp / f"completed-{module}.COB"
        shutil.copyfile(REPO / "instructor/modules" / reference, completed)
        output = tmp / f"out-{module}"
        done = run_job(unpacked, lab, fixture, output, "20261009", completed)
        assert done.returncode == 0, (
            module, done.returncode, done.stdout, done.stderr)
        assert (output / report).read_bytes() == \
            (lab / expected).read_bytes(), module

        # 3. The shipped starter still fails closed until the learner works.
        red = tmp / f"red-{module}"
        starter = run_job(unpacked, lab, fixture, red, "20261009", None)
        assert starter.returncode == 12 and not red.exists(), (
            module, starter.returncode, starter.stderr)

        # 4. 05/06 ship a self-contained acceptance harness; prove it runs in
        #    the bundle once the learner source is complete.  (Module 01's
        #    harness additionally drives the packager, which is a repo-only
        #    tool because it needs the answer to cross-check against.)
        if module in ("05", "06"):
            harness = subprocess.run(
                ["bash", str(lab / "scripts/check.sh")],
                env=dict(os.environ, COURSE_SOURCE=str(completed)),
                text=True, capture_output=True)
            assert harness.returncode == 0, (
                module, harness.stdout, harness.stderr)


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-bundle-") as temp:
        tmp = Path(temp)
        out = tmp / "bundle"
        pack = subprocess.run(["bash", str(PACKAGER), str(out)],
                              text=True, capture_output=True)
        assert pack.returncode == 0, pack.stdout + pack.stderr

        # MANIFEST integrity travels with the tarball.
        verified = subprocess.run(
            ["sha256sum", "-c", "MANIFEST.sha256"], cwd=out,
            text=True, capture_output=True)
        assert verified.returncode == 0, verified.stdout + verified.stderr

        unpacked = tmp / "unpacked"
        unpacked.mkdir()
        with tarfile.open(tmp / "bundle.tar.gz") as tar:
            tar.extractall(unpacked, filter="data")

        leak_checks(unpacked)
        end_to_end(unpacked, tmp)
    print("PASS: module 01/05/06 student bundle runnable and answer-free")


if __name__ == "__main__":
    main()
