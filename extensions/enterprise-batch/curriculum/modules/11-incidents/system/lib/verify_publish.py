#!/usr/bin/env python3
"""Verify a publication directory belongs to this run and is intact.

Used by JOB008 (before switching CURRENT) and JOB009 (before completion),
so a stale or corrupted result can never be presented as this run's.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

META = {"manifest.json", "MANIFEST.sha256"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--business-date", required=True)
    args = parser.parse_args()
    target = Path(args.dir)
    try:
        manifest = json.loads(
            (target / "manifest.json").read_text(encoding="ascii"))
    except (OSError, ValueError) as error:
        print(f"verify: cannot read manifest: {error}", file=sys.stderr)
        return 12
    if manifest.get("run_id") != args.run_id:
        print("verify: run_id mismatch (stale result)", file=sys.stderr)
        return 12
    if manifest.get("business_date") != args.business_date:
        print("verify: business_date mismatch", file=sys.stderr)
        return 12
    expected = manifest.get("files", {})
    present = {p.name for p in target.iterdir()
               if p.is_file() and p.name not in META
               and not p.name.endswith(".tmp")}
    if present != set(expected):
        print(f"verify: file set mismatch ({sorted(present)} vs "
              f"{sorted(expected)})", file=sys.stderr)
        return 12
    for name, digest in expected.items():
        if sha256(target / name) != digest:
            print(f"verify: checksum mismatch for {name}", file=sys.stderr)
            return 12
    expected_manifest = "".join(
        f"{digest}  {name}\n" for name, digest in sorted(expected.items()))
    if (target / "MANIFEST.sha256").read_text(encoding="ascii") != \
            expected_manifest:
        print("verify: MANIFEST.sha256 does not match manifest.json",
              file=sys.stderr)
        return 12
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
