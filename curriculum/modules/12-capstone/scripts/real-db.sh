#!/usr/bin/env bash
# Module 12 capstone real-DB route for JOB004/JOB006.
#
#   real-db.sh OUTPUT_DIR [BUSINESS_DATE]     (default date 20261010)
#
# The capstone DB layer *composes* the module 10 contract (12 logical tables on
# the same checkpoint conventions), so it reuses the canonical module 10 harness
# and, through it, the P1-validated GixSQL/PostgreSQL toolchain and the module
# 08 ESQL programs (real cursor extraction + single-transaction idempotent
# apply).  The customer feed here is the 31 byte CAP-CUSTOMER-FEED; its first
# 27 bytes are the canonical CUSTOMER v1 view the real cursor extracts, which
# keeps the "byte 27 is the record status" contract verifiable end to end.
#
# The offline file-checkpoint route (system/lib/capdb.py via scripts/run.sh) is
# the default teaching path; this is the real-DB evidence route.
# RC: 0 verified; 2 real DB unavailable; 8 assertion failed; 12 system failure.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$module/../../.." && pwd)
[[ $# -ge 1 ]] || { echo 'Usage: real-db.sh OUTPUT_DIR [BUSINESS_DATE]' >&2; exit 12; }
export REALDB_MODULE="$module"
export REALDB_DATASET="$module/fixtures/normal"
export REALDB_EXPECTED="$module/expected/normal.closing.txt"
export REALDB_LAYOUT=v1
exec bash "$repo/curriculum/modules/10-jobs/scripts/real-db.sh" \
  "$1" "${2:-20261010}"
