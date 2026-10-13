#!/usr/bin/env python3
"""Independent checker for module 04 (complex structures and layout).

It compiles the reference programs, runs every fixture through the runner, and
independently asks GnuCOBOL for ADDRESS OF / LENGTH OF for all 175 enterprise
leaf fields, comparing the measured layout against the catalog. Nothing here
copies the COBOL program's own output as the answer.
"""
import csv
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

lab = Path(__file__).resolve().parents[1]
repo = lab.parents[2]
INSTRUCTOR = repo / "instructor/modules/04-structures"
module = INSTRUCTOR
enterprise_dir = repo / "instructor/modules/07/05-large-record"
if not enterprise_dir.is_dir():
    # Student bundle: no instructor/, use the canonical shipped copybook.
    enterprise_dir = (repo / "curriculum/modules/07-matching/labs/05-large-record"
                      / "copybooks")
instructor_sources = [module / "M04SHAPE.COB", module / "M04COPY.COB",
                      module / "M04ENTERPRISE.COB"]
starters = [lab / "starter/M04SHAPE.COB", lab / "starter/M04COPY.COB",
            lab / "starter/M04ENTERPRISE.COB"]


def ref(name: str) -> Path:
    """Completed exercise source for a lesson: the instructor reference when
    present, else the learner's own starter (student bundle)."""
    candidate = module / name
    if candidate.is_file():
        return candidate
    return lab / "starter" / name


sources = [p for p in instructor_sources if p.is_file()]
copybook = enterprise_dir / "ENTERPRISE-CUSTOMER-V1.CPY"
catalog = lab / "FIELD-CATALOG.csv"
catalog_src = (repo / "curriculum/modules/07-matching/labs/05-large-record"
               / "FIELD-CATALOG.csv")
run = lab / "scripts/run.sh"
faults = [lab / "faults/odo-not-last.COB",
          lab / "faults/redefines-not-adjacent.COB"]


def check_format(paths):
    for path in paths:
        for n, line in enumerate(path.read_bytes().splitlines(), 1):
            assert line.isascii(), (path, n, "non-ASCII")
            assert b"\t" not in line, (path, n, "tab")
            assert len(line) <= 72, (path, n, "beyond column 72")


# ---- static checks ---------------------------------------------------------
check_format(sources + starters + faults)
assert catalog.read_bytes() == catalog_src.read_bytes(), (
    "module 04 catalog drifted from the module 07 canonical catalog")

fields = list(csv.DictReader(catalog.open()))
assert len(fields) == 175 and len({f["field_id"] for f in fields}) == 175
cursor = 1
for f in fields:
    assert int(f["offset_1_based"]) == cursor, f
    cursor += int(f["length_bytes"])
assert cursor == 1779, cursor

sums = subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=lab / "fixtures",
                      capture_output=True, text=True)
assert sums.returncode == 0, sums.stderr
for name in ("normal/enterprise-2.dat", "boundary/enterprise-1.dat",
             "boundary/enterprise-empty.dat"):
    size = (lab / "fixtures" / name).stat().st_size
    assert size % 1778 == 0, (name, size)

# RED: every starter must fail closed (RC12, nothing published).
# Authoring-only invariant (needs the pristine starter beside the reference);
# in a student bundle the learner completes the starter, so skip it there.
if INSTRUCTOR.exists():
    with tempfile.TemporaryDirectory(prefix="m04-red-") as td:
        root = Path(td)
        for lesson, starter in (("04.1", starters[0]), ("04.2", starters[1]),
                                ("04.3", starters[2])):
            out = root / lesson
            args = ["bash", str(run), lesson, str(out)]
            if lesson == "04.3":
                args.append(str(lab / "fixtures/normal/enterprise-2.dat"))
            result = subprocess.run(args, env=dict(os.environ,
                                   COURSE_SOURCE=str(starter)),
                                   capture_output=True, text=True)
            assert result.returncode == 12, (lesson, result.returncode,
                                             result.stderr)
            assert not out.exists(), (lesson, "starter published output")

# Reproducible compile faults: both files must be rejected by cobc.
for fault in faults:
    bad = subprocess.run(["cobc", "-fsyntax-only", str(fault)],
                         capture_output=True, text=True)
    assert bad.returncode != 0, fault

# ---- R05: 完成标志/占位/错误字段/跳过记录 不得发布 -----------------------
with tempfile.TemporaryDirectory(prefix="m04-r05-") as td:
    root = Path(td)
    # (a) 只把 WS-EXERCISES-DONE 改成 'Y'（占位报告）→ 拒绝且不发布
    # Authoring-only: needs the pristine starter; the bundle ships the
    # learner's (to-be-completed) source, so skip it there.
    if INSTRUCTOR.exists():
        for lesson, starter, extra in (
                ("04.1", starters[0], []),
                ("04.2", starters[1], []),
                ("04.3", starters[2],
                 [str(lab / "fixtures/normal/enterprise-2.dat")])):
            flag = root / f"flag-{lesson}.COB"
            flag.write_text(starter.read_text().replace(
                "WS-EXERCISES-DONE PIC X VALUE 'N'",
                "WS-EXERCISES-DONE PIC X VALUE 'Y'"))
            assert "VALUE 'Y'" in flag.read_text()
            out = root / ("flag-" + lesson)
            result = subprocess.run(
                ["bash", str(run), lesson, str(out), *extra],
                env=dict(os.environ, COURSE_SOURCE=str(flag)),
                capture_output=True, text=True)
            assert result.returncode == 8, ("flag-only", lesson,
                                            result.returncode, result.stderr)
            assert not out.exists(), ("flag-only", lesson, "published")

    ent = ref("M04ENTERPRISE.COB")
    # (b) 错误字段值（RISK 恒 0）→ 拒绝且不发布
    wrong = root / "wrong-field.COB"
    wrong.write_text(ent.read_text().replace(
        "MOVE RISK-SCORE TO WS-RISK", "MOVE 0 TO WS-RISK"))
    assert "MOVE 0 TO WS-RISK" in wrong.read_text()
    out = root / "wrong-field"
    result = subprocess.run(
        ["bash", str(run), "04.3", str(out),
         str(lab / "fixtures/normal/enterprise-2.dat")],
        env=dict(os.environ, COURSE_SOURCE=str(wrong)),
        capture_output=True, text=True)
    assert result.returncode == 8, (result.returncode, result.stderr)
    assert not out.exists(), "wrong-field source published"

    # (c) 跳过记录（只处理首条）→ 记录数不符，拒绝且不发布
    skip = root / "skip.COB"
    skip.write_text(ent.read_text().replace(
        "PERFORM UNTIL WS-STATUS = '10'",
        "PERFORM UNTIL WS-STATUS = '10' OR WS-N >= 1"))
    assert "OR WS-N >= 1" in skip.read_text()
    out = root / "skip"
    result = subprocess.run(
        ["bash", str(run), "04.3", str(out),
         str(lab / "fixtures/normal/enterprise-2.dat")],
        env=dict(os.environ, COURSE_SOURCE=str(skip)),
        capture_output=True, text=True)
    assert result.returncode == 8, (result.returncode, result.stderr)
    assert not out.exists(), "skip source published"

# ---- GREEN: run each lesson against the committed expected -----------------
with tempfile.TemporaryDirectory(prefix="m04-green-") as td:
    root = Path(td)
    for lesson, exp in (("04.1", "04.1-structures.txt"),
                        ("04.2", "04.2-copy-shift.txt")):
        out = root / lesson
        result = subprocess.run(["bash", str(run), lesson, str(out)],
                                capture_output=True, text=True)
        assert result.returncode == 0, (lesson, result.returncode,
                                        result.stderr)
        assert (out / "report.txt").read_text() == \
            (lab / "expected" / exp).read_text(), lesson

    good = [("normal/enterprise-2.dat", "04.3-normal.txt"),
            ("boundary/enterprise-1.dat", "04.3-one.txt"),
            ("boundary/enterprise-empty.dat", "04.3-empty.txt")]
    for name, exp in good:
        out = root / ("g-" + Path(name).name)
        result = subprocess.run(
            ["bash", str(run), "04.3", str(out), str(lab / "fixtures" / name)],
            capture_output=True, text=True)
        assert result.returncode == 0, (name, result.returncode, result.stderr)
        assert (out / "report.txt").read_text() == \
            (lab / "expected" / exp).read_text(), name

    for name in ("invalid/enterprise-bad-length.dat",
                 "invalid/enterprise-bad-version.dat",
                 "invalid/enterprise-bad-key.dat",
                 "invalid/enterprise-bad-abi.dat"):
        out = root / ("b-" + Path(name).name)
        result = subprocess.run(
            ["bash", str(run), "04.3", str(out), str(lab / "fixtures" / name)],
            capture_output=True, text=True)
        assert result.returncode == 8, (name, result.returncode, result.stderr)
        assert not out.exists(), (name, "published on bad structure")
        assert not Path(str(out) + ".lock").exists(), (name, "lock leaked")

    # ---- no-clobber / spaces / arbitrary cwd / reset ----------------------
    spaced = root / "dir with spaces"
    spaced.mkdir()
    dest = spaced / "out dir"
    result = subprocess.run(["bash", str(run), "04.1", str(dest)], cwd=str(root),
                            capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stderr)
    subprocess.run(["bash", str(lab / "scripts/reset.sh"), str(dest)],
                   check=True, capture_output=True, text=True)
    assert not dest.exists()
    existing = root / "existing"
    existing.mkdir()
    (existing / "keep.txt").write_text("preserve\n")
    refused = subprocess.run(["bash", str(run), "04.1", str(existing)],
                             capture_output=True, text=True)
    assert refused.returncode == 12
    assert (existing / "keep.txt").read_text() == "preserve\n"
    locked = root / "locked"
    Path(str(locked) + ".lock").mkdir()
    locked_run = subprocess.run(["bash", str(run), "04.1", str(locked)],
                                capture_output=True, text=True)
    assert locked_run.returncode == 12 and not locked.exists()


# ---- compiler-measured layout: ADDRESS OF for all 175 leaves ---------------
def compile_and_run(lines, prefix, includes):
    with tempfile.TemporaryDirectory(prefix=prefix) as td:
        root = Path(td)
        probe = root / "probe.COB"
        probe.write_text("\n".join(lines) + "\n")
        for n, line in enumerate(probe.read_bytes().splitlines(), 1):
            assert line.isascii() and len(line) <= 72, ("probe", n)
        exe = root / "probe"
        cmd = ["cobc"]
        for inc in includes:
            cmd += ["-I", str(inc)]
        cmd += ["-x", "-o", str(exe), str(probe)]
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        out = subprocess.run([str(exe)], check=True, capture_output=True,
                             text=True).stdout.splitlines()
        decimal_keys = {"RECLEN", "L1", "L2"}
        result = {}
        for ln in out:
            key, value = ln.split(",", 1)
            result[key] = int(value) if key in decimal_keys else int(value, 16)
        return result


lines = ["       IDENTIFICATION DIVISION.", "       PROGRAM-ID. PROBE.",
         "       DATA DIVISION.", "       WORKING-STORAGE SECTION.",
         "       01 REC.", "          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.",
         "       01 PTR USAGE POINTER.", "       PROCEDURE DIVISION.",
         "           SET PTR TO ADDRESS OF REC", '           DISPLAY "BASE," PTR',
         '           DISPLAY "RECLEN," LENGTH OF REC']
for f in fields:
    name = f["cobol_name"].replace("_", "-")
    lines.append(f"           SET PTR TO ADDRESS OF {name} OF REC")
    lines.append(f'           DISPLAY "{f["field_id"]}," PTR')
lines.append("           STOP RUN.")
addr = compile_and_run(lines, "m04-layout-", [enterprise_dir])
record_len = addr.pop("RECLEN")
base = addr.pop("BASE")
assert record_len == 1778, record_len
for f in fields:
    actual = addr[f["field_id"]] - base + 1
    assert actual == int(f["offset_1_based"]), (f["field_id"], actual,
                                                f["offset_1_based"])
assert len(addr) == 175

# ---- V1 vs V2: widening one field shifts every later offset by 1 -----------
shift_lines = ["       IDENTIFICATION DIVISION.", "       PROGRAM-ID. SHIFTPROBE.",
               "       DATA DIVISION.", "       WORKING-STORAGE SECTION.",
               "       01 REC1.", "          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.",
               "       01 REC2.",
               "          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'",
               "            REPLACING ==CUSTOMER-CLASSIFICATION PIC X(1)==",
               "                      BY ==CUSTOMER-CLASSIFICATION PIC X(2)==.",
               "       01 PTR USAGE POINTER.", "       PROCEDURE DIVISION.",
               "           SET PTR TO ADDRESS OF REC1", '           DISPLAY "B1," PTR',
               "           SET PTR TO ADDRESS OF REC2", '           DISPLAY "B2," PTR',
               "           SET PTR TO ADDRESS OF CUSTOMER-CLASSIFICATION OF REC1",
               '           DISPLAY "C1," PTR',
               "           SET PTR TO ADDRESS OF CUSTOMER-CLASSIFICATION OF REC2",
               '           DISPLAY "C2," PTR',
               "           SET PTR TO ADDRESS OF SYNC-STATE OF REC1",
               '           DISPLAY "S1," PTR',
               "           SET PTR TO ADDRESS OF SYNC-STATE OF REC2",
               '           DISPLAY "S2," PTR',
               '           DISPLAY "L1," LENGTH OF REC1',
               '           DISPLAY "L2," LENGTH OF REC2', "           STOP RUN."]
sp = compile_and_run(shift_lines, "m04-shift-", [enterprise_dir])
assert sp["L1"] == 1778 and sp["L2"] == 1779, sp
assert sp["C1"] - sp["B1"] == sp["C2"] - sp["B2"] == 459, sp  # classification
assert sp["S1"] - sp["B1"] + 1 == 1778, sp
assert sp["S2"] - sp["B2"] + 1 == 1779, sp
assert (sp["S2"] - sp["B2"]) - (sp["S1"] - sp["B1"]) == 1, sp

# ---- evidence --------------------------------------------------------------
version = subprocess.run(["cobc", "-V"], check=True, capture_output=True,
                         text=True).stdout.splitlines()[0]
evidence = {
    "compiler": version,
    "copybook_sha256": hashlib.sha256(copybook.read_bytes()).hexdigest(),
    "catalog_sha256": hashlib.sha256(catalog.read_bytes()).hexdigest(),
    "record_bytes": record_len,
    "field_offsets_checked": len(addr),
    "classification_offset_1_based": sp["C1"] - sp["B1"] + 1,
    "sync_state_offset_v1": sp["S1"] - sp["B1"] + 1,
    "sync_state_offset_v2": sp["S2"] - sp["B2"] + 1,
    "offset_method": "GnuCOBOL ADDRESS OF each leaf minus ADDRESS OF group",
}
(lab / "evidence/M04-layout-author.json").write_text(
    __import__("json").dumps(evidence, indent=2) + "\n")

print("PASS: module 04 structures, COPY shift, 175-field measured layout")
