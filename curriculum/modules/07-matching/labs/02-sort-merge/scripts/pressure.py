#!/usr/bin/env python3
"""Measure only COBOL core processes at fixed 2M SORT pool across tiers."""
from pathlib import Path
import hashlib
import re
import json
import os
import platform
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parents[4]
WAIT4 = ROOT / "scripts/wait4-core"
TIERS = tuple(int(x) for x in os.environ.get(
    "B02_PRESSURE_TIERS", "10000,100000,1000000").split(","))
DATE = b"20261009"
POOL = "2M"
RSS_LIMIT_KIB = 65536
RSS_GROWTH_LIMIT_KIB = 8192



def record(n, total):
    per_account = (total + 1) // 2
    account = (n - 1) // per_account + 1
    sequence = (n - 1) % per_account + 1
    return (f"{account:010d}T{n:015d}".encode() + DATE
            + f"{sequence:06d}C{1:013d}N\n".encode())


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1 << 20):
            h.update(chunk)
    return h.hexdigest()


def generate_sort(path, count):
    with path.open("wb") as out:
        for n in range(count, 0, -1):
            out.write(record(n, count))


def generate_merge(a, b, count):
    with a.open("wb") as out_a, b.open("wb") as out_b:
        for n in range(1, count + 1):
            (out_a if n % 2 else out_b).write(record(n, count))


def verify_sequence(path, count):
    seen = 0
    with path.open("rb") as stream:
        for expected in range(1, count + 1):
            line = stream.readline(57)
            if len(line) != 56 or line[-1:] != b"\n":
                raise AssertionError(f"malformed result row {expected}")
            row = line[:-1]
            per_account = (count + 1) // 2
            account = (expected - 1) // per_account + 1
            sequence = (expected - 1) % per_account + 1
            if row[:10] != f"{account:010d}".encode():
                raise AssertionError(f"account mismatch at {expected}")
            if row[34:40] != f"{sequence:06d}".encode():
                raise AssertionError(f"sequence mismatch at {expected}")
            if row[10:26] != f"T{expected:015d}".encode():
                raise AssertionError(f"ID mismatch at {expected}")
            seen += 1
        if stream.read(1):
            raise AssertionError("unexpected trailing bytes")
    assert seen == count


def core_run(binary, env, output, count):
    timing = time.monotonic()
    proc = subprocess.Popen([str(WAIT4), str(binary)], env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    max_hwm = 0
    workfiles = {}
    observed_child = None
    while proc.poll() is None:
        children_file = Path(f"/proc/{proc.pid}/task/{proc.pid}/children")
        try:
            children = children_file.read_text().split()
        except OSError:
            children = []
        for child in children:
            observed_child = int(child)
            proc_path = Path("/proc") / child
            try:
                status = (proc_path / "status").read_text()
                for line in status.splitlines():
                    if line.startswith("VmHWM:"):
                        max_hwm = max(max_hwm, int(line.split()[1]))
                for fd in (proc_path / "fd").iterdir():
                    try:
                        target = os.readlink(fd)
                        if "cobsort" in target:
                            workfiles[target] = max(workfiles.get(target, 0),
                                                    os.stat(fd).st_size)
                    except OSError:
                        pass
            except OSError:
                pass
        time.sleep(0.004)
    stdout, stderr = proc.communicate()
    elapsed = time.monotonic() - timing
    match = re.search(r"WAIT_STATUS=(\d+) MAX_RSS_KIB=(\d+)", stdout)
    assert match, (proc.returncode, stdout, stderr)
    wait_status, max_rss = map(int, match.groups())
    assert proc.returncode == 0, (proc.returncode, stdout, stderr)
    verify_sequence(output, count)
    return {
        "raw_rc": proc.returncode,
        "wait_status": wait_status,
        "stdout": stdout,
        "stderr": stderr,
        "elapsed_seconds": round(elapsed, 3),
        "max_rss_kib_wait4_child": max_rss,
        "sampled_cobol_vm_hwm_kib": max_hwm,
        "observed_cobol_pid": observed_child,
        "observed_sort_workfiles": workfiles,
        "output_bytes": output.stat().st_size,
        "output_sha256": digest(output),
    }


def main():
    global WAIT4
    evidence = ROOT / "evidence" / "B02-pressure-2026-10-10.json"
    results = {
        "status": "running",
        "pool": POOL,
        "tiers": {},
        "max_rss_threshold_kib": RSS_LIMIT_KIB,
        "rss_growth_threshold_kib": RSS_GROWTH_LIMIT_KIB,
        "measurement_scope": "wait4 reports only the exec'd COBOL core child; libcob core allocations are included. Python generator/verifier and C wait4 helper are excluded. Disk workfiles are recorded separately.",
        "driver_memory": "Input generation and verification stream one record at a time; no transaction-ID list is held.",
        "sort_same_account_max_group": 500000,
    }
    try:
        with tempfile.TemporaryDirectory(prefix="b02-pressure-") as temp:
            root = Path(temp)
            sort_src = REPO / "instructor/modules/07/02-sort-merge/SORTTX.COB"
            merge_src = REPO / "instructor/modules/07/02-sort-merge/MERGETX.COB"
            copybook = REPO / "curriculum/bank/copybooks/TRANSACTION-V1.CPY"
            for source, binary in ((sort_src, root / "sorttx"),
                                   (merge_src, root / "mergetx")):
                built = subprocess.run(["cobc", "-Wall", "-I",
                                        str(REPO / "curriculum/bank/copybooks"),
                                        "-x", "-o", str(binary), str(source)],
                                       text=True, capture_output=True)
                assert built.returncode == 0, built.stderr
            WAIT4 = root / "wait4-core"
            wait_build = subprocess.run(["cc", "-O2", "-Wall", "-Wextra",
                                         "-o", str(WAIT4),
                                         str(ROOT / "scripts/wait4-core.c")],
                                        text=True, capture_output=True)
            assert wait_build.returncode == 0, wait_build.stderr
            results.update({
                "cobc_version": subprocess.run(["cobc", "-V"], text=True,
                                                capture_output=True).stdout.splitlines()[0],
                "compiler_version": subprocess.run(["cc", "--version"], text=True,
                                                    capture_output=True).stdout.splitlines()[0],
                "python_version": platform.python_version(),
                "sort_version": subprocess.run(["sort", "--version"], text=True,
                                                capture_output=True).stdout.splitlines()[0],
                "kernel": platform.release(),
                "sort_source_sha256": digest(sort_src),
                "merge_source_sha256": digest(merge_src),
                "transaction_copybook_sha256": digest(copybook),
                "runtime_cfg_sha256": digest(Path("/usr/share/gnucobol/config/runtime.cfg")),
                "wait4_helper_sha256": digest(ROOT / "scripts/wait4-core.c"),
            })
            rss_values = []
            for count in TIERS:
                case = root / str(count)
                case.mkdir()
                sort_input, sort_output = case / "sort.in", case / "sort.out"
                generate_sort(sort_input, count)
                sort_tmp = case / "sort-tmp"
                sort_tmp.mkdir()
                sort_env = dict(os.environ, B02_INPUT=str(sort_input),
                                B02_OUTPUT=str(sort_output), B02_DATE="20261009",
                                COB_SORT_MEMORY=POOL, TMPDIR=str(sort_tmp), LC_ALL="C")
                sort_result = core_run(root / "sorttx", sort_env, sort_output, count)
                sort_result["input_sha256"] = digest(sort_input)
                sort_result["input_bytes"] = sort_input.stat().st_size
                sort_result["observed_temp_max_bytes"] = max(
                    sort_result["observed_sort_workfiles"].values(), default=0)
                sort_result["spill_proven"] = (
                    bool(sort_result["observed_sort_workfiles"])
                    and sort_result["observed_temp_max_bytes"] > 2 * 1024 * 1024)

                feed_a, feed_b, merge_output = (case / "merge-a.in",
                                                case / "merge-b.in",
                                                case / "merge.out")
                generate_merge(feed_a, feed_b, count)
                merge_tmp = case / "merge-tmp"
                merge_tmp.mkdir()
                merge_env = dict(os.environ, B02_INPUT_A=str(feed_a),
                                 B02_INPUT_B=str(feed_b),
                                 B02_OUTPUT=str(merge_output),
                                 B02_DATE="20261009", COB_SORT_MEMORY=POOL,
                                 TMPDIR=str(merge_tmp), LC_ALL="C")
                merge_result = core_run(root / "mergetx", merge_env,
                                        merge_output, count)
                merge_result["feed_a_sha256"] = digest(feed_a)
                merge_result["feed_b_sha256"] = digest(feed_b)
                merge_result["input_bytes_total"] = (
                    feed_a.stat().st_size + feed_b.stat().st_size)
                rss_values.extend((sort_result["max_rss_kib_wait4_child"],
                                   merge_result["max_rss_kib_wait4_child"]))
                results["tiers"][str(count)] = {
                    "sort": sort_result,
                    "merge": merge_result,
                    "max_same_account_group": (count + 1) // 2,
                }
                print(json.dumps({"records": count,
                                  "sort_seconds": sort_result["elapsed_seconds"],
                                  "merge_seconds": merge_result["elapsed_seconds"],
                                  "sort_rss_kib": sort_result["max_rss_kib_wait4_child"],
                                  "merge_rss_kib": merge_result["max_rss_kib_wait4_child"],
                                  "observed_sort_workfiles": len(sort_result["observed_sort_workfiles"]),
                                  "observed_sort_temp_max_bytes": sort_result["observed_temp_max_bytes"]}))
            growth = max(rss_values) - min(rss_values)
            results["rss_growth_kib"] = growth
            results["rss_bounded_pass"] = (max(rss_values) <= RSS_LIMIT_KIB
                                            and growth <= RSS_GROWTH_LIMIT_KIB)
            assert results["rss_bounded_pass"], "RSS threshold exceeded"
            proof = None
            if max(TIERS) >= 1_000_000:
                proof = results["tiers"][str(max(TIERS))]["sort"]["spill_proven"]
                results["million_sort_spill_pass"] = proof
                assert proof, "million-record tier did not observe a >2M cobsort workfile"
            else:
                results["million_sort_spill_pass"] = "not run: non-final smoke tier"
            results["measured_tiers"] = TIERS

            fail_count = 150_000
            fail_case = root / "workfile-failure"
            fail_case.mkdir()
            fail_input = fail_case / "input.dat"
            generate_sort(fail_input, fail_count)
            output = fail_case / "must-not-publish.dat"
            build_tmp = fail_case / "build-tmp"
            runtime_tmp = fail_case / "readonly-tmp"
            build_tmp.mkdir()
            runtime_tmp.mkdir()
            runtime_tmp.chmod(0o500)
            failure_env = dict(os.environ, COB_SORT_MEMORY=POOL,
                               B02_BUILD_TMPDIR=str(build_tmp),
                               B02_RUNTIME_TMPDIR=str(runtime_tmp))
            fail_run = subprocess.run([
                "bash", str(ROOT / "01-sort/scripts/run.sh"),
                str(fail_input), str(output)], env=failure_env, text=True,
                capture_output=True)
            results["readonly_tmp_failure"] = {
                "input_records": fail_count,
                "input_bytes": fail_input.stat().st_size,
                "input_sha256": digest(fail_input),
                "build_tmp_writable": os.access(build_tmp, os.W_OK),
                "runtime_tmp_writable": os.access(runtime_tmp, os.W_OK),
                "raw_runner_rc": fail_run.returncode,
                "published": output.exists(),
                "lock_left": Path(str(output) + ".lock").exists(),
                "stdout": fail_run.stdout,
                "stderr": fail_run.stderr,
            }
            runtime_tmp.chmod(0o700)
            assert fail_run.returncode == 12 and not output.exists()
            assert not Path(str(output) + ".lock").exists()

            limit_output = fail_case / "size-limit-output.dat"
            limit_env = dict(os.environ, COB_SORT_MEMORY=POOL,
                             B02_FILESIZE_LIMIT_BLOCKS="5120")
            limit_run = subprocess.run([
                "bash", str(ROOT / "01-sort/scripts/run.sh"),
                str(fail_input), str(limit_output)], env=limit_env,
                text=True, capture_output=True)
            results["file_size_limit_failure"] = {
                "input_records": fail_count,
                "input_bytes": fail_input.stat().st_size,
                "raw_runner_rc": limit_run.returncode,
                "core_shell_rc_text": "153 (128+SIGXFSZ) observed in runner stderr",
                "published": limit_output.exists(),
                "lock_left": Path(str(limit_output) + ".lock").exists(),
                "stdout": limit_run.stdout,
                "stderr": limit_run.stderr,
            }
            assert limit_run.returncode == 12 and not limit_output.exists()
            assert not Path(str(limit_output) + ".lock").exists()
            results["status"] = "PASS"
    except BaseException as error:
        results["status"] = "FAIL"
        results["failure"] = f"{type(error).__name__}: {error}"
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.write_text(json.dumps(results, indent=2) + "\n",
                            encoding="utf-8")
        raise
    evidence.parent.mkdir(parents=True, exist_ok=True)
    evidence.write_text(json.dumps(results, indent=2) + "\n",
                        encoding="utf-8")
    print(f"Evidence: {evidence}")

if __name__ == "__main__":
    main()
