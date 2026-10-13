"""Generate bounded-memory 1:N workloads and stream-check the COBOL report."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import tempfile
import time

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[4]
SOURCE = REPO / "instructor/modules/07/03-one-to-many/BATCHL2.COB"
def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check_report(path: Path, accounts: int, per_account: int,
                 work: Path) -> None:
    with path.open("rb") as stream:
        for account_id in range(accounts):
            account_key = f"{account_id:010d}"
            for sequence in range(1, per_account + 1):
                tx_number = account_id * per_account + sequence
                tx_id = f"T{tx_number:015d}"
                balance = 1000 + sequence
                expected = (f"TX|{tx_id}|ACCEPT|+{balance:013d}\n")
                assert stream.readline() == expected.encode("ascii"), tx_number
            expected = f"ACCOUNT|{account_key}|+{1000 + per_account:013d}\n"
            assert stream.readline() == expected.encode("ascii"), account_id
            control = (f"ACCT-CONTROL|{account_key}|TX={per_account:012d}|"
                       f"ACCEPT={per_account:012d}|REJECT=000000000000|"
                       f"OPENING=+{1000:013d}|"
                       f"CLOSING=+{1000 + per_account:013d}|"
                       f"CREDIT={per_account:018d}|DEBIT={0:018d}\n")
            assert stream.readline() == control.encode("ascii"), account_id
        total_tx = accounts * per_account
        final = (f"CONTROL|ACCOUNTS={accounts:012d}|NO-TX={0:012d}|"
                 f"TX={total_tx:012d}|ACCEPT={total_tx:012d}|"
                 f"REJECT={0:012d}|OPENING=+{accounts * 1000:018d}|"
                 f"CLOSING=+{accounts * (1000 + per_account):018d}|"
                 f"CREDIT={total_tx:018d}|DEBIT={0:018d}\n")
        assert stream.readline() == final.encode("ascii")
        assert stream.read() == b""
    with (work / "accepted.dat").open("rb") as accepted:
        for account_id in range(accounts):
            for sequence in range(1, per_account + 1):
                tx_number = account_id * per_account + sequence
                expected = (f"{account_id:010d}T{tx_number:015d}"
                            f"20261009{sequence:06d}C{1:013d}N\n")
                assert accepted.readline() == expected.encode("ascii")
        assert accepted.read() == b""
    assert (work / "rejected.dat").read_bytes() == b""
    with (work / "master.dat").open("rb") as masters:
        for account_id in range(accounts):
            original = (f"{account_id:010d}{account_id % 100000000:08d}"
                        f"JPY+{1000:013d}A20261009001")
            expected = (original[:21] + "+" + f"{1000 + per_account:013d}"
                        + original[35:] + "\n")
            assert masters.readline() == expected.encode("ascii")
        assert masters.read() == b""


def run_tier(binary: Path, root: Path, accounts: int, label: str,
             per_account: int = 10) -> dict:
    work = root / label
    work.mkdir()
    account_path = work / "account.dat"
    transaction_path = work / "transaction.dat"
    links_path = work / "reversal-link.dat"
    report_path = work / "report.dat"
    with account_path.open("wb") as stream:
        for account_id in range(accounts):
            stream.write((f"{account_id:010d}{account_id % 100000000:08d}"
                          f"JPY+{1000:013d}A20261009001\n").encode("ascii"))
    with transaction_path.open("wb") as stream:
        for account_id in range(accounts):
            for sequence in range(1, per_account + 1):
                tx_number = account_id * per_account + sequence
                stream.write((f"{account_id:010d}T{tx_number:015d}"
                              f"20261009{sequence:06d}C{1:013d}N\n")
                             .encode("ascii"))
    links_path.write_bytes(b"")
    # Use disk files so the driver does not inflate the COBOL child's inherited RSS.
    ids_path = work / "ids.txt"
    sorted_path = work / "ids.sorted"
    duplicates_path = work / "duplicates.txt"
    with ids_path.open("wb") as ids:
        subprocess.run(["cut", "-b", "11-26", str(transaction_path)],
                       check=True, stdout=ids)
    subprocess.run(["sort", "-T", str(work), "-o", str(sorted_path),
                    str(ids_path)], check=True)
    with duplicates_path.open("wb") as duplicates:
        subprocess.run(["uniq", "-d", str(sorted_path)], check=True,
                       stdout=duplicates)
    assert duplicates_path.stat().st_size == 0
    env = dict(os.environ, ACCOUNT_FILE=str(account_path),
               TRANSACTION_FILE=str(transaction_path),
               REVERSAL_FILE=str(links_path), LEDGER_FILE=str(work / "ledger"),
               LINKS_FILE=str(work / "links"), BUSINESS_DATE="20261009",
               MASTER_OUTPUT_FILE=str(work / "master.dat"),
               ACCEPT_OUTPUT_FILE=str(work / "accepted.dat"),
               REJECT_OUTPUT_FILE=str(work / "rejected.dat"))
    start = time.monotonic()
    with report_path.open("wb") as report:
        process = subprocess.Popen([str(binary)], stdout=report, env=env,
                                   stderr=subprocess.PIPE)
        _, status, usage = os.wait4(process.pid, 0)
        process.returncode = os.waitstatus_to_exitcode(status)
        stderr = process.stderr.read()
        assert process.returncode == 0, (process.returncode, stderr)
    elapsed = time.monotonic() - start
    check_report(report_path, accounts, per_account, work)
    return dict(label=label, accounts=accounts,
                transactions=accounts * per_account,
                maximum_same_account_group=per_account,
                seconds=round(elapsed, 3), matcher_max_rss_kib=usage.ru_maxrss,
                account_sha256=sha256(account_path),
                transaction_sha256=sha256(transaction_path),
                links_sha256=sha256(links_path), report_sha256=sha256(report_path))


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-l2-pressure-") as temp:
        root = Path(temp)
        binary = root / "batchl2"
        subprocess.run(["cobc", "-Wall", "-I",
                        str(REPO / "curriculum/bank/copybooks"), "-x",
                        "-o", str(binary), str(SOURCE)], check=True)
        results = []
        for args in [(1, "micro-10", 10),
                     (10_000, "10k-accounts-100k", 10),
                     (100_000, "100k-accounts-1m", 10),
                     (1, "single-key-100k", 100_000)]:
            results.append(run_tier(binary, root, args[0], args[1], args[2]))
            print(json.dumps(results[-1]), flush=True)
        baseline = results[0]["matcher_max_rss_kib"]
        maximum = max(r["matcher_max_rss_kib"] for r in results)
        print(json.dumps(dict(source_sha256=sha256(SOURCE),
                              rss_metric="COBOL child wait4 ru_maxrss only; excludes driver and sort",
                              runs=results,
                              memory_growth_kib=maximum - baseline,
                              bounded_growth_pass=maximum <= baseline + 65536),
                         indent=2), flush=True)
        assert maximum <= baseline + 65536


if __name__ == "__main__":
    main()
