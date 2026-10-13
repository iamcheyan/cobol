#!/usr/bin/env bash
# Permanent regression for the module 10 real-DB route (review R01/R02).
#
# Runs the canonical GixSQL/PostgreSQL17 extraction + single-transaction apply
# against module 10's own accepted transactions, then asserts the balance/ledger
# results produced by the harness.  When the real DB environment is missing the
# script reports UNVERIFIED (RC2) - it never claims a real end-to-end pass.
#
# RC: 0 verified; 2 real DB unavailable (UNVERIFIED); 1 assertion failed.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
root=$(mktemp -d "${TMPDIR:-/tmp}/m10-realdb.XXXXXX")
out="$root/out"
set +e
bash "$module/scripts/real-db.sh" "$out" 20261009
rc=$?
set -e
if [[ $rc == 2 ]]; then
  echo 'UNVERIFIED: real DB environment unavailable (module 10)'
  exit 2
fi
[[ $rc == 0 ]] || { echo "FAIL: module 10 real DB rc=$rc" >&2; exit 1; }
summary="$out/real-db-summary.txt"
[[ -f $summary ]] || { echo 'FAIL: no real-db-summary.txt' >&2; exit 1; }
grep -qx 'BALANCES_FIRST=400,150,0' "$summary" || {
  echo 'FAIL: real DB first-apply balances wrong' >&2; exit 1; }
grep -qx 'BALANCES_RETRY=400,150,0' "$summary" || {
  echo 'FAIL: real DB retry changed balances (double debit)' >&2; exit 1; }
grep -qx 'LEDGER_CONCURRENT=4' "$summary" || {
  echo 'FAIL: real DB concurrency double-posted' >&2; exit 1; }
echo "PASS: module 10 real DB verified ($out)"
exit 0
