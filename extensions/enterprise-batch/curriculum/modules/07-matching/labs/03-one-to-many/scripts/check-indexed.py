#!/usr/bin/env python3
"""Verify the exact GnuCOBOL BDB indexed operations used by the lab."""
from pathlib import Path
import os
import subprocess
import tempfile

LAB = Path(__file__).resolve().parents[1]
SOURCE = LAB / "scripts" / "indexed-probe.COB"


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="bank-l2-index-") as temp:
        root = Path(temp)
        binary = root / "probe"
        subprocess.run(["cobc", "-Wall", "-x", "-o", str(binary),
                        str(SOURCE)], check=True)
        env = dict(os.environ, IX_PATH=str(root / "ledger.index"))
        probe = subprocess.run([str(binary)], env=env, text=True,
                               capture_output=True)
        assert probe.returncode == 0, (probe.returncode, probe.stdout,
                                       probe.stderr)
        for line in ("DUPLICATE=22", "READ=ACCEPTED",
                     "MISSING=23", "REWRITE=REVERSED"):
            assert line in probe.stdout, probe.stdout
        bad_env = dict(env, IX_PATH=str(root / "missing" / "ledger.index"))
        failed = subprocess.run([str(binary)], env=bad_env, text=True,
                                capture_output=True)
        assert failed.returncode == 12, (failed.returncode, failed.stdout)
        assert "OPEN=" in failed.stdout, failed.stdout
    print("PASS: BDB indexed WRITE/READ/REWRITE/status and open failure")


if __name__ == "__main__":
    main()
