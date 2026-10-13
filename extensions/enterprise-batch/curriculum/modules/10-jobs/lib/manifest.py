#!/usr/bin/env python3
"""Build the publication manifest for one run (JOB008)."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

META = {"manifest.json", "MANIFEST.sha256"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--business-date", required=True)
    parser.add_argument("--engine", default="offline-file-checkpoint")
    args = parser.parse_args()
    target = Path(args.dir)
    files = sorted(p.name for p in target.iterdir()
                   if p.is_file() and p.name not in META
                   and not p.name.endswith(".tmp"))
    manifest = {
        "run_id": args.run_id,
        "business_date": args.business_date,
        "engine": args.engine,
        "real_db_verified": False,
        "files": {name: sha256(target / name) for name in files},
    }
    (target / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="ascii")
    (target / "MANIFEST.sha256").write_text(
        "".join(f"{sha256(target / name)}  {name}\n" for name in files),
        encoding="ascii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
