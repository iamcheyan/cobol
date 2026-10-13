#!/usr/bin/env bash
# RED -> GREEN evidence for the two code-gap incidents.
#
#   red-green.sh [WORKDIR]
#
# The as-found snapshot is never modified: it is copied into WORKDIR,
# reproduced (RED), then patched with the instructor fix and rerun
# (GREEN).  Raw exit codes, ledger/control evidence and publish state
# are printed for the author evidence file.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
inc="$here/.."
repo=$(cd -- "$inc/../../.." && pwd)
module="$repo/curriculum/modules/11-incidents"
work=${1:-"$PWD/m11-red-green"}
rm -rf -- "$work"
mkdir -p -- "$work"

run_case() { # fixture snapshot_dir out db rid
  local fixture=$1 system=$2 out=$3 db=$4 rid=$5
  set +e
  bash "$system/scripts/run.sh" --input "$module/fixtures/$fixture" \
    --output "$out" --db "$db" --business-date 20261009 --run-id "$rid" \
    --keep-scene
  local rc=$?
  set -e
  printf 'rc=%s publish=%s\n' "$rc" \
    "$([[ -d $out/publish/$rid ]] && echo yes || echo no)"
}

echo "################ inc-02 DB unique constraint ################"
cp -r -- "$module/system" "$work/inc02-system"
echo "--- RED: as-found snapshot (defect) ---"
run_case INC-2026-002 "$work/inc02-system" "$work/inc02-red-out" \
  "$work/inc02-red-db" red02
echo "ledger lines as-found: $(wc -l <"$work/inc02-red-db/ledger.dat")"
echo "acc1 balance as-found: $(cut -c1-35 "$work/inc02-red-db/account.table" | head -1)"
echo "--- GREEN: apply inc-02 fix (lib/db.py) ---"
cp -- "$inc/inc-02/fix/db.py" "$work/inc02-system/lib/db.py"
run_case INC-2026-002 "$work/inc02-system" "$work/inc02-green-out" \
  "$work/inc02-green-db" green02
echo "acc1 balance after fix: $(cut -c1-35 "$work/inc02-green-db/account.table" 2>/dev/null | head -1)"
tail -1 "$work/inc02-green-out/logs/JOB006.log" 2>/dev/null || true

echo "################ inc-06 RC0 but business error ################"
cp -r -- "$module/system" "$work/inc06-system"
echo "--- RED: as-found snapshot (defect) ---"
run_case INC-2026-006 "$work/inc06-system" "$work/inc06-red-out" \
  "$work/inc06-red-db" red06
echo "published closing_total as-found: $(sed -n 's/^closing_total=//p' \
  "$work/inc06-red-out/work/control/control.txt" 2>/dev/null)"
echo "declared closing_total: $(sed -n 's/^control_closing_total=//p' \
  "$module/fixtures/INC-2026-006/MANIFEST")"
echo "--- GREEN: apply inc-06 fix (lib/control.py) ---"
cp -- "$inc/inc-06/fix/control.py" "$work/inc06-system/lib/control.py"
run_case INC-2026-006 "$work/inc06-system" "$work/inc06-green-out" \
  "$work/inc06-green-db" green06
tail -2 "$work/inc06-green-out/logs/JOB007.log" 2>/dev/null || true

echo "################ result ################"
fail=0
[[ -f $work/inc02-red-db/ledger.dat && $(wc -l <"$work/inc02-red-db/ledger.dat") == 4 ]] || {
  echo "RED inc-02: unexpected ledger"; fail=1; }
[[ ! -d $work/inc02-green-out/publish/green02 ]] || {
  echo "GREEN inc-02: published despite unique violation"; fail=1; }
[[ ! -d $work/inc06-green-out/publish/green06 ]] || {
  echo "GREEN inc-06: published despite declared-total mismatch"; fail=1; }
[[ -f $work/inc06-red-out/publish/red06/control-report.txt ]] || {
  echo "RED inc-06: as-found did not publish the wrong total"; fail=1; }
[[ $fail == 0 ]] || { echo "RED->GREEN FAILED" >&2; exit 1; }
echo "PASS: RED reproduced and GREEN blocks publication for both gaps"
