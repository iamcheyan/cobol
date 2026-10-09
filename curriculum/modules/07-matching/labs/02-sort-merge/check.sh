#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$here/01-sort/scripts/check.py"
python3 "$here/02-merge/scripts/check.py"
python3 "$here/01-sort/scripts/check-core-raw.py"
python3 "$here/02-merge/scripts/check-core-raw.py"
python3 "$here/scripts/check-runner-failures.py"
(cd "$here" && sha256sum -c SHA256SUMS)
echo 'PASS: B02 SORT/MERGE full contract'
