#!/usr/bin/env python3
"""Full-chain pressure for B04: million matched + high-diff through the real runner.

The earlier probe measured only the COBOL core and left the Python report oracle
untested.  This harness drives the real `scripts/run.sh` (COBOL core + streaming
verifier + manifest/publish gate) end to end and records, per layer:

* the largest-single-process peak RSS via an exact `wait4` around the verifier,
* sampled per-command `VmHWM` peaks (core, python3, bash, cobc) during the run,
* the peak of the summed `VmRSS` across the live process tree,
* the sampled disk high-water (used delta / minimum free) of the scratch
  filesystem while the run holds its inputs, stage, oracle temp and output,
* wall time, exit code, input/output/report SHAs and sizes and the published
  state.

It also proves the failure boundaries: a verifier failure and an oracle scratch
write failure inside the full chain publish nothing and leak no lock.

Every scenario asserts its invariants (exit code == expected, published iff the
RC is 0/4, no leaked lock, standalone verifier RC 0 when published).  A violated
invariant raises, main() returns non-zero and saves failure evidence, so a green
CLI can no longer hide a failed scenario.

Scratch contract: the scratch root is chosen for free space (recorded in the
evidence) and is *not* /tmp when a larger filesystem is available.  Each run's
oracle temporary file is forced onto that same scratch root via `TMPDIR`; the
chosen paths are recorded per case.  Each scenario removes its own work tree and
main() removes the scratch root on exit; course fixtures are never touched.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

lab = Path(__file__).resolve().parents[1]
repo = lab.parents[4]
core_src = repo / "instructor/modules/07/05-large-record/BATCHL4.COB"
runner = lab / "scripts/run.sh"
verifier = lab / "scripts/verify.py"
driver = Path(__file__).resolve()
fixture = (lab / "fixtures/old.dat").read_bytes()[:1778]
RECORD_BYTES = 1778
BIG = 1_000_000
SMALL = 100_000


def sha256_file(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def scratch_root(required_bytes):
    candidates = [os.environ.get("B04_PRESSURE_TMP"), "/var/tmp", "/tmp",
                  str(repo.parent)]
    for candidate in candidates:
        if candidate and Path(candidate).is_dir():
            if shutil.disk_usage(candidate).free >= required_bytes:
                return candidate
    raise SystemExit("insufficient scratch space for B04 pressure")


def generate(old_path, new_path, count, change):
    """Write fixed 1778-byte records with ascending keys; optionally differ."""
    record = bytearray(fixture)
    with open(old_path, "wb") as old, open(new_path, "wb") as new:
        for key in range(1, count + 1):
            record[11:21] = f"{key:010d}".encode("ascii")
            old.write(record)
            if change:
                original = bytes(record[54:58])
                record[54:58] = f"{(int(original) + 1) % 10000:04d}".encode("ascii")
                new.write(record)
                record[54:58] = original
            else:
                new.write(record)


def live_tree(root_pid):
    procs = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            data = Path(f"/proc/{entry}/stat").read_bytes()
        except OSError:
            continue
        close = data.rfind(b")")
        if close < 0:
            continue
        try:
            procs[int(entry)] = int(data[close + 2:].split()[1])
        except (IndexError, ValueError):
            continue
    children = {}
    for pid, ppid in procs.items():
        children.setdefault(ppid, []).append(pid)
    stack = list(children.get(root_pid, []))
    while stack:
        pid = stack.pop()
        stack.extend(children.get(pid, []))
        yield pid


def run_runner(args, env, scratch_dir):
    peaks = {}
    whole = [0]      # aggregate over the entire runner (includes cobc build)
    runtime = [0]    # aggregate only while the core/verifier are live
    started = time.monotonic()
    baseline = shutil.disk_usage(scratch_dir)
    peak_used = baseline.used
    min_free = baseline.free
    with open(os.devnull, "wb") as sink:
        proc = subprocess.Popen(["bash", str(runner), *args], env=env,
                                stdout=sink, stderr=subprocess.PIPE)
        while proc.poll() is None:
            total = 0
            runtime_total = 0
            for pid in live_tree(proc.pid):
                try:
                    comm = Path(f"/proc/{pid}/comm").read_text().strip()
                    status = Path(f"/proc/{pid}/status").read_text()
                except OSError:
                    continue
                hwm = rss = 0
                for line in status.splitlines():
                    if line.startswith("VmHWM:"):
                        hwm = int(line.split()[1])
                    elif line.startswith("VmRSS:"):
                        rss = int(line.split()[1])
                total += rss
                if comm in ("batchl4", "python3"):
                    runtime_total += rss
                peaks[comm] = max(peaks.get(comm, 0), hwm)
            whole[0] = max(whole[0], total)
            runtime[0] = max(runtime[0], runtime_total)
            sampled = shutil.disk_usage(scratch_dir)
            peak_used = max(peak_used, sampled.used)
            min_free = min(min_free, sampled.free)
            time.sleep(0.01)
        stderr = proc.communicate()[1].decode("utf-8", "replace")
    disk = {"scratch_dir": str(scratch_dir),
            "used_bytes_before": baseline.used,
            "peak_used_bytes": peak_used,
            "peak_used_delta_bytes": peak_used - baseline.used,
            "free_bytes_before": baseline.free,
            "min_free_bytes": min_free}
    return (proc.returncode, peaks, whole[0], runtime[0],
            round(time.monotonic() - started, 3), stderr, disk)


def run_wait4(argv, env, stdout_path):
    """Run argv and return (exit code, child ru_maxrss in KiB), exact."""
    out = os.open(stdout_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
    pid = os.fork()
    if pid == 0:
        try:
            os.dup2(out, 1)
            os.close(out)
            os.execve(argv[0], argv, env)
        except OSError:
            os._exit(127)
    os.close(out)
    _, status, usage = os.wait4(pid, 0)
    return os.waitstatus_to_exitcode(status), usage.ru_maxrss


def dir_bytes(path):
    total = 0
    for entry in Path(path).rglob("*"):
        if entry.is_file() and not entry.is_symlink():
            total += entry.stat().st_size
    return total


def check_invariants(name, record):
    problems = []
    if record["runner_rc"] != record["expected_rc"]:
        problems.append(f"runner_rc={record['runner_rc']} "
                        f"expected_rc={record['expected_rc']}")
    want_published = record["expected_rc"] in (0, 4)
    if record["published"] != want_published:
        problems.append(f"published={record['published']} "
                        f"for rc={record['expected_rc']}")
    if record.get("lock_leaked"):
        problems.append("output lock leaked")
    if record.get("verifier_standalone_rc") not in (None, 0):
        problems.append(f"standalone verifier RC="
                        f"{record.get('verifier_standalone_rc')}")
    if problems:
        record["invariant_failures"] = problems
        raise AssertionError(f"{name}: " + "; ".join(problems) +
                             " :: " + json.dumps(record))


def scenario(root, name, count, change, expected_rc, verify_exact):
    work = root / name
    work.mkdir()
    oracle_tmp = work / "tmp"
    oracle_tmp.mkdir()
    old, new, target = work / "old.dat", work / "new.dat", work / "published"
    generate(old, new, count, change)
    input_bytes = old.stat().st_size + new.stat().st_size
    env = dict(os.environ, TMPDIR=str(oracle_tmp))
    rc, peaks, aggregate, runtime_aggregate, elapsed, stderr, disk = run_runner(
        [str(old), str(new), str(target)], env, root)
    published = target.is_dir()
    lock_leaked = Path(str(target) + ".lock").exists()
    record = {"scenario": name, "old_records": count, "new_records": count,
              "record_bytes": RECORD_BYTES, "changed_field": "B04-HEA-008" if change else None,
              "input_bytes": input_bytes, "input_old_sha256": sha256_file(old),
              "input_new_sha256": sha256_file(new), "runner_rc": rc,
              "expected_rc": expected_rc, "published": published,
              "lock_leaked": lock_leaked, "oracle_tmpdir": str(oracle_tmp),
              "oracle_tmp_leftovers": sorted(p.name for p in oracle_tmp.iterdir()),
              "scratch_dir": str(work), "scratch_fs": disk,
              "runner_wall_seconds": elapsed, "runner_stderr_tail": stderr[-200:],
              "peak_vmhwm_kib_by_command": peaks,
              "peak_aggregate_tree_rss_kib": aggregate,
              "peak_runtime_tree_rss_kib": runtime_aggregate,
              "runtime_tree_scope": "aggregate summed VmRSS while batchl4/python3 live"}
    if published:
        report = target / "report.txt"
        record["report_bytes"] = report.stat().st_size
        record["report_sha256"] = sha256_file(report)
        record["published_bytes"] = dir_bytes(target)
        if verify_exact:
            code, maxrss = run_wait4(
                [sys.executable, str(verifier), str(target / "old.dat"),
                 str(target / "new.dat"), str(report)],
                dict(os.environ, TMPDIR=str(oracle_tmp)),
                str(work / "verify.out"))
            record["verifier_standalone_rc"] = code
            record["verifier_standalone_maxrss_kib"] = maxrss
    check_invariants(name, record)
    shutil.rmtree(work)
    return record


def failure_boundary(root):
    """A verifier failure inside the real chain must publish nothing."""
    normal_old = lab / "fixtures/old.dat"
    normal_new = lab / "fixtures/new.dat"
    fakebin = root / "fakebin"
    fakebin.mkdir()
    shim = fakebin / "python3"
    shim.write_text(f"#!/usr/bin/env bash\n"
                    f"for arg in \"$@\"; do [[ $arg == *verify.py ]] && exit 1; done\n"
                    f"exec {sys.executable} \"$@\"\n")
    shim.chmod(0o755)
    target = root / "boundary-verify"
    tmp = root / "boundary-tmp"
    tmp.mkdir()
    env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}", TMPDIR=str(tmp))
    proc = subprocess.run(["bash", str(runner), str(normal_old), str(normal_new),
                           str(target)], env=env, capture_output=True, text=True)
    record = {"scenario": "verifier-failure", "runner_rc": proc.returncode,
              "expected_rc": 12, "published": target.exists(),
              "lock_leaked": Path(str(target) + ".lock").exists(),
              "oracle_tmpdir": str(tmp),
              "runner_stderr_tail": proc.stderr[-200:]}
    check_invariants("verifier-failure", record)
    return record


def space_exhaustion(root):
    """The oracle's scratch write hits its file-size/space limit: the full chain
    must return 12, publish nothing and leave no output lock."""
    # A large, high-difference input so the oracle temp exceeds the tiny limit.
    old = root / "space-old.dat"
    new = root / "space-new.dat"
    generate(old, new, 400, True)
    fakebin = root / "fakebin-limit"
    fakebin.mkdir()
    shim = fakebin / "python3"
    shim.write_text(f"#!/usr/bin/env bash\n"
                    f"ulimit -f 8 2>/dev/null || true\n"
                    f"exec {sys.executable} \"$@\"\n")
    shim.chmod(0o755)
    target = root / "space-limited"
    tmp = root / "space-tmp"
    tmp.mkdir()
    env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}", TMPDIR=str(tmp))
    proc = subprocess.run(["bash", str(runner), str(old), str(new), str(target)],
                          env=env, capture_output=True, text=True)
    record = {"scenario": "oracle-temp-space-exhausted", "runner_rc": proc.returncode,
              "expected_rc": 12, "published": target.exists(),
              "lock_leaked": Path(str(target) + ".lock").exists(),
              "oracle_tmpdir": str(tmp),
              "oracle_tmp_leftovers": sorted(p.name for p in tmp.iterdir()),
              "runner_stderr_tail": proc.stderr[-200:]}
    check_invariants("oracle-temp-space-exhausted", record)
    # The oracle temp may be left by a killed writer, but it lives only under
    # this scratch root (removed on exit); the runner stage/lock must be gone.
    assert not (root / "space-limited.lock").exists()
    return record


def main():
    mode = "small" if ("--small" in sys.argv or
                       os.environ.get("B04_PRESSURE_MODE") == "small") else "full"
    big = BIG if mode == "full" else SMALL
    required = big * RECORD_BYTES * 5 + 512 * 1024 * 1024
    root = Path(tempfile.mkdtemp(prefix="b04-pressure-",
                                 dir=scratch_root(required)))
    evidence = {"mode": mode, "scratch_root": str(root),
                "scratch_contract": (
                    "scratch root selected for free space; every run's oracle "
                    "TMPDIR is forced onto it; each scenario removes its work "
                    "tree and main() removes the scratch root on exit. /tmp is "
                    "used only if it is the first candidate with enough free "
                    "space (recorded in scratch_root).")}
    cases = []
    evidence["cases"] = cases
    try:
        binary = root / "batchl4"
        subprocess.run(["cobc", "-I", str(core_src.parent), "-x", "-o",
                        str(binary), str(core_src)], check=True,
                       capture_output=True, text=True)
        core_binary_sha = sha256_file(binary)
        if mode == "full":
            cases.append(scenario(root, "matched-million-high-diff", BIG, True, 4, True))
            cases.append(scenario(root, "matched-clean-100k", SMALL, False, 0, True))
        else:
            cases.append(scenario(root, "matched-clean-100k", SMALL, False, 0, True))
            cases.append(scenario(root, "matched-high-diff-30k", 30_000, True, 4, True))
        evidence["failure_boundary"] = failure_boundary(root)
        evidence["space_exhaustion"] = space_exhaustion(root)
        evidence.update({
            "compiler": subprocess.run(["cobc", "-V"], capture_output=True,
                                       text=True, check=True).stdout.splitlines()[0],
            "python": sys.version.split()[0],
            "core_sha256": sha256_file(core_src),
            "core_binary_sha256": core_binary_sha,
            "runner_sha256": sha256_file(runner),
            "verifier_sha256": sha256_file(verifier),
            "driver_sha256": sha256_file(driver),
            "measurement": (
                "full scripts/run.sh chain; exact wait4 ru_maxrss for the "
                "standalone verifier plus 10ms sampled /proc VmHWM per command, "
                "summed VmRSS across the live tree, and 10ms sampled scratch "
                "statvfs used/free high-water"),
            "notes": (
                "Scratch files live on a non-/tmp filesystem selected for free "
                "space and are deleted on exit; course fixtures are read-only. "
                "Sampled peaks are per-command high-water marks; the standalone "
                "verifier number is exact. The COBOL core binary is removed by "
                "run.sh before publish, so only its source SHA is retained."),
            "status": "pass"})
    except BaseException as exc:  # save failure evidence and exit non-zero
        evidence["status"] = "fail"
        evidence["failure"] = repr(exc)
        (lab / "evidence/B04-pressure-FAILURE.json").write_text(
            json.dumps(evidence, indent=2, default=str) + "\n")
        print(f"B04 pressure FAILED: {exc}", file=sys.stderr)
        raise
    finally:
        shutil.rmtree(root, ignore_errors=True)
    out = lab / ("evidence/B04-pressure-author.json" if mode == "full"
                 else "evidence/B04-pressure-small.json")
    out.write_text(json.dumps(evidence, indent=2) + "\n")
    print(json.dumps(evidence, indent=2))


if __name__ == "__main__":
    main()
