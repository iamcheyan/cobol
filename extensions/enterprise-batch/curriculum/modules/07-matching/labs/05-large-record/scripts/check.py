#!/usr/bin/env python3
"""Independent catalog, source-format, fixture and execution smoke checks."""
import csv
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

lab = Path(__file__).resolve().parents[1]
repo = lab.parents[4]
source = repo / "instructor/modules/07/05-large-record/BATCHL4.COB"
copybook = repo / "instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY"
course_copybook = lab / "copybooks/ENTERPRISE-CUSTOMER-V1.CPY"
fields = list(csv.DictReader((lab / "FIELD-CATALOG.csv").open()))
assert copybook.read_bytes() == course_copybook.read_bytes(), (
    "course/reference Copybook drift")
assert len(fields) == 175 and len({f['field_id'] for f in fields}) == 175
cursor = 1
for f in fields:
    assert int(f['offset_1_based']) == cursor, f
    cursor += int(f['length_bytes'])
assert cursor == 1779
for path in (source, copybook, lab / "starter/BATCHL4.COB"):
    for number, line in enumerate(path.read_bytes().splitlines(), 1):
        assert line.isascii() and b"\t" not in line and len(line) <= 72, (path, number)
# Ask the real GnuCOBOL runtime for every ADDRESS OF value, then subtract
# the record base. This checks each leaf offset, not just LENGTH OF the group.
with tempfile.TemporaryDirectory(prefix="b04-layout-") as td:
    root = Path(td)
    probe = root / "layout.COB"
    lines = ["       IDENTIFICATION DIVISION.", "       PROGRAM-ID. LAYOUTPROBE.",
             "       DATA DIVISION.", "       WORKING-STORAGE SECTION.",
             "       01 REC.", "          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.",
             "       01 PTR USAGE POINTER.", "       PROCEDURE DIVISION.",
             "           SET PTR TO ADDRESS OF REC", "           DISPLAY \"BASE,\" PTR",
             "           DISPLAY \"RECLEN,\" LENGTH OF REC"]
    for field in fields:
        cobol = field["cobol_name"].replace("_", "-")
        lines.append(f"           SET PTR TO ADDRESS OF {cobol} OF REC")
        lines.append(f"           DISPLAY \"{field['field_id']},\" PTR")
    lines.append("           STOP RUN.")
    probe.write_text("\n".join(lines) + "\n")
    for n, line in enumerate(probe.read_bytes().splitlines(), 1):
        assert line.isascii() and len(line) <= 72, ("generated layout probe", n)
    exe = root / "layout"
    subprocess.run(["cobc", "-I", str(copybook.parent), "-x", "-o", str(exe),
                    str(probe)], check=True, capture_output=True, text=True)
    measured = subprocess.run([str(exe)], check=True, capture_output=True,
                              text=True).stdout.splitlines()
    addresses = {}
    actual_record_length = None
    for line in measured:
        name, value = line.split(",", 1)
        if name == "RECLEN":
            actual_record_length = int(value)
        else:
            addresses[name] = int(value, 16)
    base = addresses.pop("BASE")
    assert actual_record_length == 1778, actual_record_length
    for f in fields:
        actual = addresses[f["field_id"]] - base + 1
        assert actual == int(f["offset_1_based"]), (f["field_id"], actual,
                                                     f["offset_1_based"])
    assert len(addresses) == 175
    version = subprocess.run(["cobc", "-V"], check=True, capture_output=True,
                             text=True).stdout.splitlines()[0]
    offsets = {f["field_id"]: addresses[f["field_id"]] - base + 1
               for f in fields}
    lengths = {}
    for index, field in enumerate(fields):
        next_offset = (offsets[fields[index + 1]["field_id"]]
                       if index + 1 < len(fields) else actual_record_length + 1)
        lengths[field["field_id"]] = next_offset - offsets[field["field_id"]]
        assert lengths[field["field_id"]] == int(field["length_bytes"]), (
            field["field_id"], lengths[field["field_id"]],
            field["length_bytes"])
    evidence = {"compiler": version, "record_bytes": cursor - 1,
                "compiler_record_bytes": actual_record_length,
                "catalog_sha256": hashlib.sha256(
                    (lab / "FIELD-CATALOG.csv").read_bytes()).hexdigest(),
                "copybook_sha256": hashlib.sha256(copybook.read_bytes()).hexdigest(),
                "core_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                "field_offsets_checked": len(addresses),
                "offset_method": "GnuCOBOL ADDRESS OF each leaf minus ADDRESS OF group",
                "offsets_match_catalog": True,
                "measured_offsets_1_based": offsets,
                "measured_lengths_bytes": lengths}
    (lab / "evidence/B04-layout-author.json").write_text(
        json.dumps(evidence, indent=2) + "\n")
for name in ("old", "new"):
    payload = (lab / f"fixtures/{name}.dat").read_bytes()
    assert len(payload) % 1778 == 0
with tempfile.TemporaryDirectory(prefix="b04-check-") as td:
    root = Path(td)
    binary = root / "batchl4"
    build = subprocess.run(["bash", str(lab / "scripts/build.sh"), str(binary)],
                           capture_output=True, text=True)
    assert build.returncode == 0, (build.returncode, build.stderr)
    output = root / "result"
    env = dict(os.environ, COURSE_SOURCE=str(source))
    run = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                          str(lab / "fixtures/old.dat"),
                          str(lab / "fixtures/new.dat"), str(output)],
                         env=env, capture_output=True, text=True)
    assert run.returncode == 4, (run.returncode, run.stdout, run.stderr)
    actual_report = (output / "report.txt").read_text()
    run_id = actual_report.splitlines()[0].split(",", 1)[1]
    expected_report = (lab / "expected/normal.txt").read_text().replace(
        "{{RUNID}}", run_id)
    assert actual_report == expected_report
    # Every FIELD/AUDIT line carries run id, layout version and record context.
    assert f",{run_id},001," in actual_report
    assert ",******0001,B04-HEA-008,REVISION_NO,55,4,NUMERIC" in actual_report
    subprocess.run(["python3", str(lab / "scripts/verify.py"),
                    str(output / "old.dat"), str(output / "new.dat"),
                    str(output / "report.txt")], check=True,
                   capture_output=True, text=True)
    assert "[REDACTED]" in (output / "report.txt").read_text()
    assert (output / "inputs.sha256").is_file() and (output / "manifest.sha256").is_file()
    # A one-byte tail is rejected before COBOL can pad a fixed record.
    short = root / "short.dat"
    short.write_bytes((lab / "fixtures/old.dat").read_bytes()[:-1])
    rejected = root / "rejected"
    bad = subprocess.run(["bash", str(lab / "scripts/run.sh"), str(short),
                          str(lab / "fixtures/new.dat"), str(rejected)],
                         capture_output=True, text=True)
    assert bad.returncode == 8 and not rejected.exists(), (bad.returncode, bad.stderr)
    # The runner compiles and executes the learner's COURSE_SOURCE.
    starter_out = root / "starter-output"
    student = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                              str(lab / "fixtures/old.dat"),
                              str(lab / "fixtures/new.dat"), str(starter_out)],
                             env=dict(os.environ,
                                      COURSE_SOURCE=str(lab / "starter/BATCHL4.COB")),
                             capture_output=True, text=True)
    assert student.returncode == 12 and not starter_out.exists(), (
        student.returncode, student.stdout, student.stderr)
    old_record = (lab / "fixtures/old.dat").read_bytes()[:1778]
    new_record = (lab / "fixtures/new.dat").read_bytes()[:1778]

    def case(name, old_bytes, new_bytes, expected_rc, contains=(), excludes=()):
        old_path, new_path = root / f"{name}-old.dat", root / f"{name}-new.dat"
        target = root / f"{name}-result"
        old_path.write_bytes(old_bytes)
        new_path.write_bytes(new_bytes)
        result = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                                 str(old_path), str(new_path), str(target)],
                                capture_output=True, text=True)
        assert result.returncode == expected_rc, (
            name, result.returncode, result.stdout, result.stderr)
        if expected_rc in (0, 4):
            report = (target / "report.txt").read_text()
            assert all(value in report for value in contains), (name, report)
            assert all(value not in report for value in excludes), (name, report)
        else:
            assert not target.exists(), (name, "failed run published")
            assert not Path(str(target) + ".lock").exists(), (name, "lock leaked")
        return target

    # Case-folding plus right-space normalization is semantically equal.
    norm_old, norm_new = bytearray(old_record), bytearray(old_record)
    norm_old[58:90] = b"ALICE".ljust(32)
    norm_new[58:90] = b"alice".ljust(32)
    norm = case("normalized-equal", bytes(norm_old), bytes(norm_new), 0,
                contains=("SUMMARY,NORMALIZED-EQUAL,000000001",),
                excludes=("B04-IDE-001",))
    # C/D packed zero has different bytes but equal mathematical value.
    packed_old, packed_new = bytearray(old_record), bytearray(old_record)
    packed_old[1533] = 0x0C
    packed_new[1533] = 0x0D
    packed = case("packed-positive-negative-zero", bytes(packed_old),
                  bytes(packed_new), 0,
                  contains=("SUMMARY,NUMERIC-REPRESENTATION-EQUAL,000000001",),
                  excludes=("B04-RIS-020",))
    # Audit changes are located and counted without changing the business RC.
    audit_old, audit_new = bytearray(old_record), bytearray(old_record)
    audit_old[1777], audit_new[1777] = ord("P"), ord("S")
    case("audit-only", bytes(audit_old), bytes(audit_new), 0,
         contains=(",B04-AUD-012,", ",1778,1,IGNORE-AUDIT",
                   "SUMMARY,AUDIT-ONLY,000000001"))

    bad_code = bytearray(old_record); bad_code[21] = ord("Z")
    case("invalid-domain", bytes(bad_code), bytes(old_record), 8)
    required_null = bytearray(old_record); required_null[21] = ord(" ")
    case("required-null", bytes(required_null), bytes(old_record), 8)
    bad_key = bytearray(old_record); bad_key[11] = ord("X")
    case("nondigit-key", bytes(bad_key), bytes(old_record), 8)
    zero_key = bytearray(old_record); zero_key[11:21] = b"0000000000"
    case("zero-key", bytes(zero_key), bytes(old_record), 8)
    bad_display_number = bytearray(old_record); bad_display_number[54:58] = b"00A1"
    case("invalid-display-number", bytes(bad_display_number), bytes(old_record), 8)
    bad_date = bytearray(old_record); bad_date[26:34] = b"20260230"
    case("invalid-gregorian-date", bytes(bad_date), bytes(old_record), 8)
    nullable_date = bytearray(old_record); nullable_date[338:346] = b" " * 8
    case("nullable-date", bytes(nullable_date), bytes(old_record), 4,
         contains=(",B04-IDE-009,", ",339,8,RAW,[REDACTED]"))
    nullable_mask = bytearray(old_record); nullable_mask[363:387] = b" " * 24
    case("nullable-document-mask", bytes(nullable_mask), bytes(old_record), 4,
         contains=(",B04-IDE-017,", ",364,24,RAW,[REDACTED]"))
    bad_mask = bytearray(old_record); bad_mask[363] = ord("%")
    case("invalid-document-mask", bytes(bad_mask), bytes(old_record), 8)
    bad_packed = bytearray(old_record); bad_packed[1533] = 0x0F
    case("invalid-packed-sign", bytes(bad_packed), bytes(old_record), 8)
    bad_digit = bytearray(old_record); bad_digit[1528] = 0xA0
    case("invalid-packed-digit", bytes(bad_digit), bytes(old_record), 8)
    bad_limit = bytearray(old_record)
    bad_limit[1534:1540] = bytes((0, 0, 0, 0, 1, 0x0D))
    case("negative-limit", bytes(bad_limit), bytes(old_record), 8)
    risk_over = bytearray(old_record); risk_over[1466:1470] = bytes.fromhex("000186A1")
    case("risk-score-range", bytes(risk_over), bytes(old_record), 8)
    bad_abi = bytearray(old_record); bad_abi[3:11] = b"BADABI  "
    case("abi-mismatch", bytes(bad_abi), bytes(old_record), 8)
    bad_version = bytearray(old_record); bad_version[0:3] = b"002"
    case("version-mismatch", bytes(bad_version), bytes(old_record), 8)
    bad_ascii = bytearray(old_record); bad_ascii[58] = 0xFF
    case("non-ascii-display", bytes(bad_ascii), bytes(old_record), 8)
    bad_time = bytearray(old_record); bad_time[1262:1266] = b"2460"
    case("invalid-contact-time", bytes(bad_time), bytes(old_record), 8)
    bad_timestamp = bytearray(old_record)
    bad_timestamp[1683:1689] = b"240000"
    case("invalid-audit-time", bytes(bad_timestamp), bytes(old_record), 8)
    partial_phone = bytearray(old_record); partial_phone[1063:1066] = b"001"
    case("partial-phone-null", bytes(partial_phone), bytes(old_record), 8)
    optional_null = bytearray(old_record); optional_null[1309:1312] = b" " * 3
    case("nullable-enum", bytes(optional_null), bytes(old_record), 4,
         contains=(",B04-CON-020,", ",1310,3,RAW,[REDACTED]"))
    optional_reason = bytearray(old_record); optional_reason[1524:1528] = b" " * 4
    case("nullable-reason-code", bytes(optional_reason), bytes(old_record), 4,
         contains=(",B04-RIS-019,", ",1525,4,RAW,[REDACTED]"))
    duplicate = bytearray((lab / "fixtures/old.dat").read_bytes())
    duplicate[1778 + 11:1778 + 21] = duplicate[11:21]
    case("duplicate-key", bytes(duplicate), (lab / "fixtures/new.dat").read_bytes(), 8)
    # Binary COMP contains high bytes; they are not subjected to DISPLAY ASCII checks.
    comp_old, comp_new = bytearray(old_record), bytearray(old_record)
    comp_old[1466:1470] = comp_new[1466:1470] = b"\x00\x00\x01\x00"
    case("binary-high-bytes", bytes(comp_old), bytes(comp_new), 0,
         excludes=("B04-RIS-001",))
    comp_change = bytearray(old_record)
    comp_change[1466:1470] = b"\x00\x00\x01\x00"
    case("binary-numeric-change", old_record, bytes(comp_change), 4,
         contains=(",B04-RIS-001,", ",1467,4,NUMERIC,[REDACTED]"))
    case("both-empty", b"", b"", 0,
         contains=("SUMMARY,OLD-RECORDS,000000000",))
    case("one-sided", old_record, b"", 4,
         contains=("OLD-ONLY,******0001",))
    # Exact packed decimal change is a business difference and retains scale.
    amount_old, amount_new = bytearray(old_record), bytearray(old_record)
    amount_new[1534:1540] = bytes((0, 0, 0, 0, 0x10, 0x0C))
    amount = case("scaled-numeric-change", bytes(amount_old), bytes(amount_new), 4,
                  contains=(",B04-LIM-001,", ",1535,6,NUMERIC",
                            "OLD|+000000000.00", "NEW|+000000001.00"))
    # The final business date field is checked independently of the audit tail.
    tail_old, tail_new = bytearray(old_record), bytearray(old_record)
    tail_new[1657:1665] = b"20261011"
    case("last-business-field", bytes(tail_old), bytes(tail_new), 4,
         contains=(",B04-CHA-016,", ",1658,8,RAW"))
    # R09: two customers change the SAME field to different values; each diff
    # line must be uniquely attributable via the redacted key + old/new seq.
    rec1 = (lab / "fixtures/old.dat").read_bytes()
    first, third = rec1[:1778], rec1[1778:3556]
    c1, c3 = bytearray(first), bytearray(third)
    c1[54:58], c3[54:58] = b"0002", b"0003"
    two = case("two-customers-same-field", first + third, bytes(c1) + bytes(c3),
               4, contains=(",******0001,B04-HEA-008,REVISION_NO,55,4,NUMERIC",
                            ",******0003,B04-HEA-008,REVISION_NO,55,4,NUMERIC",
                            ",001,000000001,000000001,******0001,",
                            ",001,000000002,000000002,******0003,",
                            "SUMMARY,FIELD-DIFFERENCES,000000002"))
    two_report = (two / "report.txt").read_text()
    assert two_report.count(",B04-HEA-008,REVISION_NO,55,4,NUMERIC") == 2
    workspace = root / "workspace"
    subprocess.run(["bash", str(lab / "scripts/init-workspace.sh"),
                    str(workspace)], check=True)
    (workspace / "NOTES.md").write_text("keep learner notes\n")
    student_source = workspace / "BATCHL4.COB"
    student_source.write_text(student_source.read_text() + "* learner edit\n")
    work_output = workspace / "output"
    work = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                           str(lab / "fixtures/old.dat"),
                           str(lab / "fixtures/new.dat"), str(work_output)],
                          capture_output=True, text=True)
    assert work.returncode == 4
    subprocess.run(["bash", str(lab / "scripts/reset.sh"), str(workspace)],
                   check=True)
    assert not work_output.exists()
    assert (workspace / "NOTES.md").read_text() == "keep learner notes\n"
    assert "learner edit" in student_source.read_text()
    work_output.mkdir()
    (work_output / "unknown.txt").write_text("preserve\n")
    protected = subprocess.run(["bash", str(lab / "scripts/reset.sh"),
                                str(workspace)], capture_output=True, text=True)
    assert protected.returncode == 12
    assert (work_output / "unknown.txt").read_text() == "preserve\n"
    # Rebuild a complete, hash-verified output to exercise the lock protocol.
    (work_output / "unknown.txt").unlink()
    work_output.rmdir()
    work2 = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                            str(lab / "fixtures/old.dat"),
                            str(lab / "fixtures/new.dat"), str(work_output)],
                           capture_output=True, text=True)
    assert work2.returncode == 4, work2.stderr
    # A live directory lock (same protocol as run.sh) refuses reset, keeps all.
    (workspace / "output.lock").mkdir()
    locked = subprocess.run(["bash", str(lab / "scripts/reset.sh"),
                             str(workspace)], capture_output=True, text=True)
    assert locked.returncode == 12
    assert (work_output / "report.txt").is_file()
    assert (workspace / "output.lock").is_dir()
    (workspace / "output.lock").rmdir()
    # A symlink lock (here dangling) is equally refused.
    (workspace / "output.lock").symlink_to(workspace / "no-such-lock")
    symlocked = subprocess.run(["bash", str(lab / "scripts/reset.sh"),
                                str(workspace)], capture_output=True, text=True)
    assert symlocked.returncode == 12
    assert (work_output / "report.txt").is_file()
    assert (workspace / "output.lock").is_symlink()
    (workspace / "output.lock").unlink()
    # With no lock, the complete output is removed and learner files survive.
    subprocess.run(["bash", str(lab / "scripts/reset.sh"), str(workspace)],
                   check=True)
    assert not work_output.exists()
    assert (workspace / "NOTES.md").read_text() == "keep learner notes\n"
    assert "learner edit" in student_source.read_text()
    fakebin = root / "fakebin"
    fakebin.mkdir()
    sha_shim = fakebin / "sha256sum"
    sha_shim.write_text("#!/usr/bin/env bash\n"
                        "for arg in \"$@\"; do [[ $arg == -c ]] && exit 1; done\n"
                        "exec /usr/bin/sha256sum \"$@\"\n")
    sha_shim.chmod(0o755)
    failed_target = root / "hash-failure"
    env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}")
    failed = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                             str(lab / "fixtures/old.dat"),
                             str(lab / "fixtures/new.dat"), str(failed_target)],
                            env=env, capture_output=True, text=True)
    assert failed.returncode == 12 and not failed_target.exists(), (
        failed.returncode, failed.stdout, failed.stderr)
    assert not Path(str(failed_target) + ".lock").exists()
    bad_source = root / "broken.COB"
    bad_source.write_text("       THIS IS NOT COBOL\n")
    compile_target = root / "compile-failure"
    compile_failed = subprocess.run(
        ["bash", str(lab / "scripts/run.sh"),
         str(lab / "fixtures/old.dat"), str(lab / "fixtures/new.dat"),
         str(compile_target)],
        env=dict(os.environ, COURSE_SOURCE=str(bad_source)),
        capture_output=True, text=True)
    assert compile_failed.returncode == 12 and not compile_target.exists(), (
        compile_failed.returncode, compile_failed.stdout, compile_failed.stderr)
    existing = root / "existing"
    existing.mkdir()
    (existing / "keep.txt").write_text("preserve\n")
    refused = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                              str(lab / "fixtures/old.dat"),
                              str(lab / "fixtures/new.dat"), str(existing)],
                             capture_output=True, text=True)
    assert refused.returncode == 12
    assert (existing / "keep.txt").read_text() == "preserve\n"
    locked_target = root / "locked"
    Path(str(locked_target) + ".lock").mkdir()
    locked_run = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                                 str(lab / "fixtures/old.dat"),
                                 str(lab / "fixtures/new.dat"), str(locked_target)],
                                capture_output=True, text=True)
    assert locked_run.returncode == 12 and not locked_target.exists()
    assert Path(str(locked_target) + ".lock").is_dir()
    large_input = root / "resource-limit-old.dat"
    large_input.write_bytes(old_record * 600)
    empty_input = root / "resource-limit-new.dat"
    empty_input.write_bytes(b"")
    limited_target = root / "file-limit"
    limited = subprocess.run(
        ["bash", "-c",
         'ulimit -f 512; exec bash "$1" "$2" "$3" "$4"',
         "b04-limit", str(lab / "scripts/run.sh"), str(large_input),
         str(empty_input), str(limited_target)],
        capture_output=True, text=True)
    assert limited.returncode == 12 and not limited_target.exists(), (
        limited.returncode, limited.stdout, limited.stderr)
    assert not Path(str(limited_target) + ".lock").exists()
    spaced = root / "directory with spaces"
    spaced.mkdir()
    old_spaced, new_spaced = spaced / "old file.dat", spaced / "new file.dat"
    old_spaced.write_bytes((lab / "fixtures/old.dat").read_bytes())
    new_spaced.write_bytes((lab / "fixtures/new.dat").read_bytes())
    spaced_output = spaced / "published result"
    space_run = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                                str(old_spaced), str(new_spaced),
                                str(spaced_output)], capture_output=True,
                               text=True)
    assert space_run.returncode == 4, (
        space_run.returncode, space_run.stdout, space_run.stderr)
    subprocess.run(["python3", str(lab / "scripts/verify.py"),
                    str(spaced_output / "old.dat"),
                    str(spaced_output / "new.dat"),
                    str(spaced_output / "report.txt")], check=True,
                   capture_output=True, text=True)
    # Streaming-oracle guard: the verifier must not cache whole input files.
    # 120,000 records (213 MB) must verify under a 140 MB address-space cap;
    # a whole-file oracle would need > 213 MB and fail here.
    guard_old = root / "oracle-guard-old.dat"
    guard_buf = bytearray(old_record)
    with guard_old.open("wb") as guard_out:
        for key in range(1, 120_001):
            guard_buf[11:21] = f"{key:010d}".encode("ascii")
            guard_out.write(guard_buf)
    guard_new = root / "oracle-guard-new.dat"
    guard_new.write_bytes(b"")
    guard_target = root / "oracle-guard-out"
    guard_run = subprocess.run(["bash", str(lab / "scripts/run.sh"),
                                str(guard_old), str(guard_new),
                                str(guard_target)],
                               capture_output=True, text=True)
    assert guard_run.returncode == 4, (guard_run.returncode, guard_run.stderr)
    guard_verify = subprocess.run(
        ["bash", "-c",
         'ulimit -v 140000; exec python3 "$1" "$2" "$3" "$4"', "oracle-guard",
         str(lab / "scripts/verify.py"), str(guard_target / "old.dat"),
         str(guard_target / "new.dat"), str(guard_target / "report.txt")],
        capture_output=True, text=True)
    assert guard_verify.returncode == 0, (
        guard_verify.returncode, guard_verify.stdout, guard_verify.stderr[-300:])
print("PASS: 175-field catalog continuity, 72-column source, fixed-record fixture and COBOL comparison")
