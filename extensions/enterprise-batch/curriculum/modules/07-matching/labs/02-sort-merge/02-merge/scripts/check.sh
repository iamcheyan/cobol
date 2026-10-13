#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$here/scripts/check.py"
python3 "$here/scripts/check-core-raw.py"
python3 "$here/../scripts/check-runner-failures.py"
echo 'PASS: 07.2 MERGE'
