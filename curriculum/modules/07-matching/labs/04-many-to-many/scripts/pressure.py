#!/usr/bin/env python3
"""B03 full-job tiers; child-only COBOL RSS and cobsort FD observation."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import sys
import time

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[4]
EVIDENCE = LAB / "evidence/B03-author-pressure-2026-10-10.json"
SOURCE = REPO / "instructor/modules/07/04-many-to-many/BATCHL3.COB"
TIERS = (10_000, 100_000, 1_000_000)
MAX_RSS_KIB = 65_536
MAX_GROWTH_KIB = 8_192


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(1 << 20):
            digest.update(block)
    return digest.hexdigest()


def write_inputs(folder: Path, count: int, shape: str = "balanced") -> list[Path]:
    account = folder / "account.dat"
    tx = folder / "transaction.dat"
    link = folder / "reversal-link.dat"
    snap = folder / "snapshot.dat"
    prev = folder / "previous.dat"
    link.write_bytes(b"")
    if shape == "balanced":
        customer_count = 1000
        per_customer = count // customer_count
        assert count % customer_count == 0
    else:
        customer_count = 1
        per_customer = count
    account_count = (1 if count <= 999_999 else 2) if shape != "balanced" else customer_count
    per_account = (count + account_count - 1) // account_count
    with account.open("wb") as stream:
        for customer in range(1, customer_count + 1):
            for offset in range(account_count if shape != "balanced" else 1):
                account_id = (customer - 1) * (account_count if shape != "balanced" else 1) + offset + 1
                row = (f"{account_id:010d}{customer:08d}JPY+0000001000000A"
                       "20261009001\n").encode()
                assert len(row) == 48
                stream.write(row)
    with tx.open("wb") as stream:
        ordinal = 0
        for customer in range(1, customer_count + 1):
            customer_accounts = account_count if shape != "balanced" else 1
            per_acct = per_customer if shape == "balanced" else per_account
            for offset in range(customer_accounts):
                account_id = (customer - 1) * customer_accounts + offset + 1
                seq_count = min(per_acct, count - ordinal)
                for sequence in range(1, seq_count + 1):
                    ordinal += 1
                    transaction_id = f"T{ordinal:015d}".encode()
                    row = (f"{account_id:010d}".encode() + transaction_id +
                           b"20261009" + f"{sequence:06d}".encode() +
                           b"C0000000000001N\n")
                    assert len(row) == 56
                    stream.write(row)
    with snap.open("wb") as stream, prev.open("wb") as previous_stream:
        for customer in range(1, customer_count + 1):
            actual_accounts = account_count if shape != "balanced" else 1
            initial = actual_accounts * 1_000_000
            closing = initial + per_customer
            stream.write((f"{customer:08d}20261009001A{actual_accounts:03d}{9999999999999:013d}\n"
                          ).encode())
            previous_stream.write((
                f"{customer:08d}20261008001{actual_accounts:06d}+{initial:013d}\n"
            ).encode())
    return [account, tx, link, snap, prev]


def descendants(pid: int) -> list[int]:
    pending = [pid]
    found = []
    while pending:
        parent = pending.pop()
        child_file = Path(f"/proc/{parent}/task/{parent}/children")
        try:
            children = [int(value) for value in child_file.read_text().split()]
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
        found.extend(children)
        pending.extend(children)
    return found


def observe_sort_files(root_pid: int, stage_parent: Path) -> tuple[list[str], int, list[int]]:
    links = []
    maximum = 0
    core_pids = []
    for pid in descendants(root_pid):
        cmdline = Path(f"/proc/{pid}/cmdline")
        try:
            args = cmdline.read_bytes().replace(b"\0", b" ")
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
        if b"batchl3" not in args:
            continue
        core_pids.append(pid)
        fd_dir = Path(f"/proc/{pid}/fd")
        try:
            fds = list(fd_dir.iterdir())
        except (FileNotFoundError, PermissionError):
            continue
        for fd in fds:
            try:
                target = os.readlink(fd)
                size = os.stat(fd).st_size
            except (FileNotFoundError, PermissionError, OSError):
                continue
            if "cobsort" in target:
                if target not in links:
                    links.append(target)
                maximum = max(maximum, size)
    return links, maximum, core_pids


def main() -> int:
    EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "source_sha256": hash_file(SOURCE),
        "runner_sha256": hash_file(LAB / "scripts/run.sh"),
        "commit": subprocess.run(["git", "rev-parse", "HEAD"],
                                  capture_output=True, text=True,
                                  check=True).stdout.strip(),
        "driver_sha256": hash_file(Path(__file__).resolve()),
        "tools": {
            "cobc": subprocess.run(["cobc", "-V"], capture_output=True,
                                   text=True, check=True).stdout.splitlines()[0],
            "sort": subprocess.run(["sort", "--version"], capture_output=True,
                                   text=True, check=True).stdout.splitlines()[0],
            "python": sys.version.split()[0],
        },
        "sort_memory": "2M",
        "max_transactions_in_one_customer_group": 1_000_000,
        "max_transactions_total": max(TIERS),
        "limits": {"core_rss_kib": MAX_RSS_KIB,
                   "growth_kib": MAX_GROWTH_KIB},
        "measurement_scope": "Bash samples /proc/<BATCHL3 PID>/status VmHWM for the COBOL child only; includes libcob; excludes runner, B01 L2, external sort, Python SQLite oracle and driver. SORT FD observation is separately sampled from /proc.",
        "tiers": [],
        "status": "running",
    }
    EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
    baseline = None
    try:
        runs = [(count, "balanced") for count in TIERS]
        runs.extend((count, "single-customer-max-group") for count in TIERS)
        for count, shape in runs:
            with tempfile.TemporaryDirectory(prefix=f"b03-pressure-{count}-") as td:
                root = Path(td)
                input_paths = write_inputs(root, count, shape)
                target = root / "published"
                command = ["bash", str(LAB / "scripts/run.sh"),
                           *(str(path) for path in input_paths),
                           str(target), "20261009"]
                env = dict(os.environ, LC_ALL="C", COB_SORT_MEMORY="2M",
                           B03_MEASURE_CORE="Y")
                process = subprocess.Popen(command, env=env,
                                           stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE)
                seen, max_file, observed_core_pids = [], 0, []
                sample_count = 0
                first_seen = last_seen = None
                started = time.monotonic()
                while process.poll() is None:
                    links, size, core_pids = observe_sort_files(process.pid, root)
                    observed_core_pids.extend(
                        pid for pid in core_pids if pid not in observed_core_pids)
                    if links:
                        sample_count += 1
                        now = time.monotonic() - started
                        if first_seen is None:
                            first_seen = now
                        last_seen = now
                    seen.extend(item for item in links if item not in seen)
                    max_file = max(max_file, size)
                    time.sleep(0.05)
                stdout, stderr = process.communicate()
                tier = {
                    "shape": shape,
                    "transaction_records": count,
                    "raw_tx_bytes": input_paths[1].stat().st_size,
                    "account_records": sum(1 for _ in input_paths[0].open("rb")),
                    "customer_snapshot_records": sum(
                        1 for _ in input_paths[3].open("rb")),
                    "max_customer_transaction_group": (
                        count if shape == "single-customer-max-group"
                        else count // 1000),
                    "max_transactions_per_account": (
                        min(999_999, (count + 1) // 2)
                        if shape == "single-customer-max-group" and count > 999_999
                        else count if shape == "single-customer-max-group"
                        else count // 1000),
                    "account_record_count": sum(1 for _ in input_paths[0].open("rb")),
                    "runner_pid": process.pid,
                    "observed_core_pids": observed_core_pids,
                    "core_child_observed": bool(observed_core_pids),
                    "input_sha256": {path.name: hash_file(path)
                                     for path in input_paths},
                    "raw_rc": process.returncode,
                    "stdout": stdout.decode(errors="replace"),
                    "stderr": stderr.decode(errors="replace"),
                    "sort_fd_paths": seen,
                    "sort_fd_samples": sample_count,
                    "first_sort_fd_observation_seconds": first_seen,
                    "last_sort_fd_observation_seconds": last_seen,
                    "sort_fd_max_size_bytes": max_file,
                    "sort_spill_observed": bool(seen),
                }
                if process.returncode not in (0, 4) or not target.is_dir():
                    tier["pass"] = False
                    report["tiers"].append(tier)
                    report["status"] = "failed"
                    EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
                    return 1
                tier["core_rss_kib"] = int(
                    (target / "core-rss-kib").read_text().strip())
                tier["output_sha256"] = {
                    path.relative_to(target).as_posix(): hash_file(path)
                    for path in target.rglob("*.dat") if path.is_file()}
                tier["pass"] = tier["core_rss_kib"] <= MAX_RSS_KIB
                if count == TIERS[-1] and shape == "balanced":
                    tier["pass"] = tier["pass"] and bool(seen)
                report["tiers"].append(tier)
                if baseline is None:
                    baseline = tier["core_rss_kib"]
                tier["growth_kib"] = max(0, tier["core_rss_kib"] - baseline)
                tier["pass"] = tier["pass"] and tier["growth_kib"] <= MAX_GROWTH_KIB
                EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
                if not tier["pass"]:
                    report["status"] = "failed"
                    EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
                    return 1
        with tempfile.TemporaryDirectory(prefix="b03-tmpdir-failure-") as td:
            root = Path(td)
            input_paths = write_inputs(root, 100_000,
                                       "single-customer-max-group")
            restricted = root / "no-write"
            restricted.mkdir()
            restricted.chmod(0o500)
            target = root / "must-not-publish"
            command = ["bash", str(LAB / "scripts/run.sh"),
                       *(str(path) for path in input_paths),
                       str(target), "20261009"]
            env = dict(os.environ, LC_ALL="C", COB_SORT_MEMORY="2M",
                       B03_MEASURE_CORE="Y",
                       B03_RUNTIME_TMPDIR=str(restricted))
            result = subprocess.run(command, env=env, capture_output=True,
                                    text=True)
            restricted.chmod(0o700)
            failure = {
                "shape": "runtime-TMPDIR-permission-failure",
                "transaction_records": 100_000,
                "account_records": 1,
                "customer_snapshot_records": 1,
                "max_customer_transaction_group": 100_000,
                "COB_SORT_MEMORY": "2M",
                "runtime_tmpdir_mode_during_core": "0500",
                "raw_runner_rc": result.returncode,
                "published": target.exists(),
                "stdout": result.stdout,
                "stderr": result.stderr,
                "input_sha256": {path.name: hash_file(path)
                                 for path in input_paths},
            }
            failure["pass"] = (result.returncode == 12 and
                               not target.exists())
            report["resource_failure"] = failure
            EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
            if not failure["pass"]:
                report["status"] = "failed"
                EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
                return 1
        report["status"] = "passed"
        report["finished_utc"] = datetime.now(timezone.utc).isoformat()
        EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
        return 0
    except BaseException as error:
        report["status"] = "failed"
        report["error"] = repr(error)
        EVIDENCE.write_text(json.dumps(report, indent=2) + "\n")
        raise


if __name__ == "__main__":
    raise SystemExit(main())
