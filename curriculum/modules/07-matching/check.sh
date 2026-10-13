#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# 07.3 L1: 1:1 classification and double-EOF contract.
python3 "$here/labs/01-one-to-one/scripts/check.py"
(cd "$here/labs/01-one-to-one/fixtures" && sha256sum -c SHA256SUMS)

# 07.1/07.2 SORT + MERGE, including the SORT/MERGE -> L2 bridge expected files.
(cd "$here/labs/02-sort-merge" && bash check.sh)

# 07.4 L2: 1:N key break, balances, reversals, indexed ledger probe.
python3 "$here/labs/03-one-to-many/scripts/check.py"
python3 "$here/labs/03-one-to-many/scripts/check-indexed.py"

# 07.5 L3: four-stream N:N customer-day reconciliation.
(cd "$here/labs/04-many-to-many" && bash scripts/check.sh)

# 07.6 L4: 175-field catalog, layout, field-level diff oracle, failure/publish guards.
(cd "$here/labs/05-large-record" && bash scripts/check.sh)

echo 'PASS: module 07 SORT/MERGE + L1 + L2 + L3 + L4 full contract'
