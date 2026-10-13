#!/usr/bin/env bash
# Four (plus one) crash-boundary recovery lab for module 10.
#
#   recovery-lab.sh [WORKDIR]
#
# For each boundary: run with --crash-at (expect RC97 and preserved
# state), then resume the same run id (expect the business RC and a
# consistent DB/ledger/file/status), and record the raw evidence.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
run="$here/scripts/run.sh"
normal="$here/fixtures/normal"
work=${1:-"$PWD/m10-recovery-lab"}
mkdir -p -- "$work"
fail=0
for point in before-db-commit mid-db-commit after-db-commit \
             during-publish after-publish; do
  out="$work/out-$point"
  db="$work/db-$point"
  rm -rf -- "$out" "$db"
  echo "==== crash at $point ===="
  set +e
  bash "$run" --input "$normal" --output "$out" --db "$db" \
    --business-date 20261009 --run-id "lab-$point" --crash-at "$point"
  crash_rc=$?
  echo "crash_rc=$crash_rc"
  bash "$run" --input "$normal" --output "$out" --db "$db" \
    --business-date 20261009 --run-id "lab-$point"
  recover_rc=$?
  set -e
  echo "recover_rc=$recover_rc"
  ledger=$(wc -l <"$db/ledger.dat" 2>/dev/null || echo 0)
  committed=no; [[ -f $db/commit/20261009.json ]] && committed=yes
  complete=no; [[ -f $out/state/complete.marker ]] && complete=yes
  current=$(cat "$out/publish/CURRENT" 2>/dev/null || echo none)
  echo "ledger_lines=$ledger committed=$committed complete=$complete current=$current"
  if [[ $crash_rc != 97 || $recover_rc != 4 || $ledger != 4 ||
        $committed != yes || $complete != yes || $current != "lab-$point" ]]; then
    echo "BOUNDARY $point FAILED" >&2
    fail=1
  fi
done
[[ $fail == 0 ]] || { echo "recovery lab FAILED" >&2; exit 1; }
echo "PASS: all crash boundaries recovered consistently"
