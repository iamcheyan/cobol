#!/usr/bin/env python3
"""R07 regression: the whole learner bundle must be runnable and answer-free.

This drives the real ``package-student.sh`` into a throwaway directory, unpacks
the tarball, and asserts two independent things:

* answer containment by role *and* content, not by filename alone;
* every module's documented build/run/check works inside the isolated bundle:
  - the shipped learner starter builds and fails closed (RC != 0, no publish);
  - once the learner's work is finished (the reference answer copied over the
    learner path, standing in for a completed submission) the module builds,
    runs and its ``scripts/check.sh`` passes.

The reference answers are used only *outside* the bundle, to simulate a finished
submission; nothing under ``instructor/`` ships, and no shipped file may equal a
classified exercise answer.
"""
from __future__ import annotations

import fnmatch
import hashlib
import os
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve()
REPO = HERE.parents[3]
PACKAGER = REPO / "curriculum" / "scripts" / "package-student.sh"

# Exercise answers that must never ship (role = current lab solution).  Shared
# canonical interfaces and provided harness components legitimately appear on
# both sides and are deliberately absent from this list (e.g. the module 08
# ESQL-PROBE/APPLY harness and the module 09 AMTCALC/CUSTVAL/LOGGER modules).
ANSWERS = [
    "instructor/modules/01-foundations/BANK-ENTRY.COB",
    "instructor/modules/02-data/CUSTLOAD.COB",
    "instructor/modules/03-bytes/M03BYTES.COB",
    "instructor/modules/04-structures/M04SHAPE.COB",
    "instructor/modules/04-structures/M04COPY.COB",
    "instructor/modules/04-structures/M04ENTERPRISE.COB",
    "instructor/modules/05-control/CLEANSE.COB",
    "instructor/modules/06-files/FILEVAL.COB",
    "instructor/modules/07/01-one-to-one/MATCH.COB",
    "instructor/modules/07/02-sort-merge/SORTTX.COB",
    "instructor/modules/07/02-sort-merge/MERGETX.COB",
    "instructor/modules/07/03-one-to-many/BATCHL2.COB",
    "instructor/modules/07/04-many-to-many/BATCHL3.COB",
    "instructor/modules/07/05-large-record/BATCHL4.COB",
    "instructor/modules/08-database/SNAPSHOT.COB",
    "instructor/modules/09-modular/BATCH09.COB",
    "curriculum/modules/12-capstone/system/cobol/CUSTV2.COB",
]

# Files that are a *current* exercise answer in one module but a deliberately
# vendored "existing system" dependency elsewhere.  Module 11 ships frozen
# snapshots of the module 10 system (DESIGN §6): once as the live system and
# once per incident scene.  The module 10 validator therefore appears verbatim
# as module 11's M11VAL.COB.  We still forbid it anywhere else, so a stray
# relocated copy is caught.
VENDORED = {
    "instructor/modules/10-jobs/BANKVAL.COB": [
        "curriculum/modules/11-incidents/system/cobol/M11VAL.COB",
        "curriculum/modules/11-incidents/INC-*/student/scene/source/M11VAL.COB",
    ],
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rel(path: str) -> Path:
    return REPO / path


def copy(src: str, bundle: Path, dst: str) -> None:
    shutil.copyfile(rel(src), bundle / dst)


def m07_inputs(bundle: Path) -> None:
    """Modules 10/12 reuse the canonical module 07 SORT/MERGE implementations;
    in the bundle those come from the learner's own (to-be-completed) lab."""
    copy("instructor/modules/07/02-sort-merge/SORTTX.COB", bundle,
         "curriculum/modules/07-matching/labs/02-sort-merge/01-sort/starter/SORTTX.COB")
    copy("instructor/modules/07/03-one-to-many/BATCHL2.COB", bundle,
         "curriculum/modules/07-matching/labs/03-one-to-many/starter/BATCHL2.COB")


CONFIGS = [
    dict(
        name="01-foundations", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/01-foundations/BANK-ENTRY.COB", b,
            "curriculum/modules/01-foundations/starter/BANK-ENTRY.COB"),
        build=lambda b, t: [b / "curriculum/modules/01-foundations/scripts/build.sh", t / "b01"],
        run=lambda b, t: [b / "curriculum/modules/01-foundations/scripts/run.sh",
                          b / "curriculum/modules/01-foundations/fixtures/normal/account.dat",
                          t / "o01", "20261009"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/01-foundations/scripts/check.sh"],
    ),
    dict(
        name="02-data", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/02-data/CUSTLOAD.COB", b,
            "curriculum/modules/02-data/starter/CUSTLOAD.COB"),
        build=lambda b, t: [b / "curriculum/modules/02-data/scripts/build.sh", t / "b02"],
        run=lambda b, t: [b / "curriculum/modules/02-data/scripts/run.sh",
                          b / "curriculum/modules/02-data/fixtures/normal/customer.dat",
                          t / "o02"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/02-data/scripts/check.sh"],
    ),
    dict(
        name="03-bytes", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/03-bytes/M03BYTES.COB", b,
            "curriculum/modules/03-bytes/starter/M03BYTES.COB"),
        build=lambda b, t: [b / "curriculum/modules/03-bytes/scripts/build.sh", t / "b03"],
        run=lambda b, t: [b / "curriculum/modules/03-bytes/scripts/run.sh", "03.1", t / "o03"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/03-bytes/scripts/check.sh"],
    ),
    dict(
        name="04-structures", docker=False,
        green=lambda b, t: [copy(f"instructor/modules/04-structures/{p}.COB", b,
                                 f"curriculum/modules/04-structures/starter/{p}.COB")
                            for p in ("M04SHAPE", "M04COPY", "M04ENTERPRISE")],
        build=None,
        run=lambda b, t: [b / "curriculum/modules/04-structures/scripts/run.sh", "04.1", t / "o04"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/04-structures/scripts/check.sh"],
    ),
    dict(
        name="05-control", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/05-control/CLEANSE.COB", b,
            "curriculum/modules/05-control/starter/CLEANSE.COB"),
        build=lambda b, t: [b / "curriculum/modules/05-control/scripts/build.sh", t / "b05"],
        run=lambda b, t: [b / "curriculum/modules/05-control/scripts/run.sh",
                          b / "curriculum/modules/05-control/fixtures/normal/clean.dat",
                          t / "o05", "20261009"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/05-control/scripts/check.sh"],
    ),
    dict(
        name="06-files", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/06-files/FILEVAL.COB", b,
            "curriculum/modules/06-files/starter/FILEVAL.COB"),
        build=lambda b, t: [b / "curriculum/modules/06-files/scripts/build.sh", t / "b06"],
        run=lambda b, t: [b / "curriculum/modules/06-files/scripts/run.sh",
                          b / "curriculum/modules/06-files/fixtures/normal/valid.dat",
                          t / "o06", "20261009"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/06-files/scripts/check.sh"],
    ),
    dict(
        name="08-database", docker=True,
        green=lambda b, t: copy(
            "instructor/modules/08-database/SNAPSHOT.COB", b,
            "curriculum/modules/08-database/starter/DBBATCH.COB"),
        build=lambda b, t: [b / "curriculum/modules/08-database/scripts/build.sh",
                            t / "b08", b / "curriculum/modules/08-database/starter/DBBATCH.COB"],
        run=lambda b, t: [b / "curriculum/modules/08-database/scripts/run.sh", t / "o08", "20261009"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/08-database/scripts/check.sh"],
    ),
    dict(
        name="09-modular", docker=False,
        green=lambda b, t: copy(
            "instructor/modules/09-modular/BATCH09.COB", b,
            "curriculum/modules/09-modular/starter/BATCH09.COB"),
        build=lambda b, t: [b / "curriculum/modules/09-modular/scripts/build.sh", t / "b09"],
        run=lambda b, t: [b / "curriculum/modules/09-modular/scripts/run.sh",
                          b / "curriculum/modules/09-modular/fixtures/normal/customer.dat",
                          b / "curriculum/modules/09-modular/fixtures/normal/account.dat",
                          b / "curriculum/modules/09-modular/fixtures/normal/transaction.dat",
                          t / "o09", "20261010"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/09-modular/scripts/check.sh"],
    ),
    dict(
        name="10-jobs", docker=False,
        green=lambda b, t: (m07_inputs(b), copy(
            "instructor/modules/10-jobs/BANKVAL.COB", b,
            "curriculum/modules/10-jobs/starter/BANKVAL.COB")),
        build=lambda b, t: [b / "curriculum/modules/10-jobs/scripts/build.sh", t / "b10"],
        run=lambda b, t: [b / "curriculum/modules/10-jobs/scripts/run.sh",
                          "--input", b / "curriculum/modules/10-jobs/fixtures/normal",
                          "--output", t / "o10", "--db", t / "db10",
                          "--business-date", "20261009"],
        rc=4,
        check=lambda b, t: [b / "curriculum/modules/10-jobs/scripts/check.sh"],
    ),
    dict(
        name="11-incidents", docker=False,
        green=lambda b, t: None,
        build=lambda b, t: [b / "curriculum/modules/11-incidents/scripts/build.sh", t / "b11"],
        run=lambda b, t: [b / "curriculum/modules/11-incidents/scripts/run.sh",
                          "--input", b / "curriculum/modules/11-incidents/fixtures/normal",
                          "--output", t / "o11", "--db", t / "db11",
                          "--business-date", "20261009", "--run-id", "bundle11"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/11-incidents/scripts/check.sh"],
    ),
    dict(
        name="12-capstone", docker=False,
        green=lambda b, t: (m07_inputs(b),
                            copy("instructor/modules/10-jobs/BANKVAL.COB", b,
                                 "curriculum/modules/10-jobs/starter/BANKVAL.COB"),
                            copy("curriculum/modules/12-capstone/system/cobol/CUSTV2.COB", b,
                                 "curriculum/modules/12-capstone/starter/CUSTV2.COB")),
        build=lambda b, t: [b / "curriculum/modules/12-capstone/scripts/build.sh", t / "b12"],
        run=lambda b, t: [b / "curriculum/modules/12-capstone/scripts/run.sh",
                          "--input", b / "curriculum/modules/12-capstone/fixtures/normal",
                          "--output", t / "o12", "--db", t / "db12",
                          "--business-date", "20261010", "--layout", "v1"],
        rc=0,
        check=lambda b, t: [b / "curriculum/modules/12-capstone/scripts/check.sh"],
    ),
]


def leak_checks(unpacked: Path) -> None:
    shipped = [p for p in unpacked.rglob("*") if p.is_file()]
    assert shipped, "bundle is empty"
    for path in shipped:
        parts = path.relative_to(unpacked).parts
        assert "instructor" not in parts, path
        assert path.name != "INSTRUCTOR.md", path
    relset = {p.relative_to(unpacked).as_posix() for p in shipped}
    answer_digests: dict[str, str] = {}
    for answer in ANSWERS:
        a = rel(answer)
        assert a.is_file(), f"classified answer missing: {answer}"
        assert answer not in relset, f"answer path shipped: {answer}"
        answer_digests[sha256(a)] = answer
    for path in shipped:
        d = sha256(path)
        assert d not in answer_digests, (
            f"answer copy shipped as {path} (= {answer_digests[d]})")
    for src, allowed in VENDORED.items():
        d = sha256(rel(src))
        for path in shipped:
            if sha256(path) != d:
                continue
            r = path.relative_to(unpacked).as_posix()
            assert any(fnmatch.fnmatch(r, pat) for pat in allowed), (
                f"vendored component {src} shipped at unexpected {r}")
        print(f"NOTE: {src} ships verbatim as a vendored system component "
              f"(only at allowed module 11 paths)")


def _run(argv, **kw):
    args = [str(a) for a in argv]
    # Enumerate scripts explicitly: the shipped entry points are invoked via
    # "bash <script>" everywhere and the bundle does not rely on exec bits.
    if args and args[0].endswith(".sh"):
        args = ["bash", *args]
    return subprocess.run(args, text=True, capture_output=True, **kw)


def red_check(bundle: Path, tmp: Path, cfg: dict) -> None:
    if cfg["build"] is not None:
        built = _run(cfg["build"](bundle, tmp))
        assert built.returncode == 0, (cfg["name"], "starter build", built.stderr)
    if cfg["name"] == "11-incidents":
        return  # the incident system ships complete; no learner RED state
    run = _run(cfg["run"](bundle, tmp))
    assert run.returncode != 0, (cfg["name"], "starter run published", run.stdout)
    for out in tmp.glob("o*"):
        assert not out.exists(), (cfg["name"], "starter published", out)


def green_check(bundle: Path, tmp: Path, cfg: dict) -> None:
    cfg["green"](bundle, tmp)
    if cfg["build"] is not None:
        built = _run(cfg["build"](bundle, tmp))
        assert built.returncode == 0, (cfg["name"], "completed build", built.stderr)
    run = _run(cfg["run"](bundle, tmp))
    assert run.returncode == cfg["rc"], (
        cfg["name"], "completed run", run.returncode, run.stdout, run.stderr)
    checked = _run(cfg["check"](bundle, tmp), cwd=bundle)
    assert checked.returncode == 0, (
        cfg["name"], "completed check", checked.stdout, checked.stderr)


def docker_available() -> bool:
    try:
        return subprocess.run(["docker", "info"], capture_output=True).returncode == 0
    except FileNotFoundError:
        return False


def main() -> int:
    skip = os.environ.get("STUDENT_BUNDLE_SKIP_DOCKER") == "1"
    have_docker = docker_available() and not skip
    with tempfile.TemporaryDirectory(prefix="student-bundle-") as temp:
        tmp = Path(temp)
        out = tmp / "bundle"
        pack = _run(["bash", str(PACKAGER), str(out)])
        assert pack.returncode == 0, pack.stdout + pack.stderr
        verified = _run(["sha256sum", "-c", "MANIFEST.sha256"], cwd=out)
        assert verified.returncode == 0, verified.stdout + verified.stderr

        unpacked = tmp / "unpacked"
        unpacked.mkdir()
        with tarfile.open(tmp / "bundle.tar.gz") as tar:
            tar.extractall(unpacked, filter="data")
        leak_checks(unpacked)

        skipped = []
        for cfg in CONFIGS:
            if cfg["docker"] and not have_docker:
                skipped.append(cfg["name"])
                continue
            red = tmp / ("red-" + cfg["name"])
            red.mkdir()
            red_check(unpacked, red, cfg)

        # A separate unpack so the completed-source copy cannot pollute RED.
        green = tmp / "green"
        green.mkdir()
        with tarfile.open(tmp / "bundle.tar.gz") as tar:
            tar.extractall(green, filter="data")
        for cfg in CONFIGS:
            if cfg["docker"] and not have_docker:
                continue
            gw = tmp / ("g-" + cfg["name"])
            gw.mkdir()
            green_check(green, gw, cfg)

        if skipped:
            print(f"UNVERIFIED (no Docker; not run): {', '.join(skipped)}")

    print(f"PASS: student bundle runnable and answer-free "
          f"({len(CONFIGS)} modules, {len(ANSWERS)} classified answers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
