#!/usr/bin/env bash
# JOB003 SORT 及有序性验证 -- nodes 003a/003b/003c.
# Reuses the canonical module 07 SORTTX runner (one sort implementation for
# the whole course) and then proves the published order independently.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
work="$NIGHT_OUTPUT/work"
sorter=$(c12_sort_runner)

n_build_sort() {
  local node=$1
  # The canonical transaction-sort implementation ships inside the curriculum
  # (module 07 lab) as the sort runner's own dependency; the node only needs to
  # confirm that runner is present.  Its output is proven independently by
  # 003b/003c, so no instructor-only source path is required.
  [[ -f $sorter ]] || { c12_log "$node" ERROR 'module 07 sort runner missing'; return 12; }
  c12_marker "$node" 0
}

n_sort() {
  local node=$1 out="$work/sorted_tx.dat" rc=0 keyout
  [[ ! -e $out ]] || { c12_log "$node" ERROR 'sorted output already exists'; return 12; }
  # Duplicate transaction_id is a business error: name it plainly before the
  # canonical sorter, so the night log carries a usable reason.
  keyout=$(python3 "$here/../lib/validate.py" keys \
    --tx "$work/validate/accepted_tx.dat" 2>&1) || {
    c12_log "$node" ERROR "$keyout"
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$keyout" >>"$NIGHT_LOG_DIR/$node.log"
  set +e
  B02_DATE="$NIGHT_DATE" bash "$sorter" "$work/validate/accepted_tx.dat" "$out" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0) c12_marker "$node" 0; return 0 ;;
    8) c12_log "$node" ERROR 'sort rejected the accepted stream'
       c12_marker "$node" 8; return 8 ;;
    *) c12_log "$node" ERROR "sort failed rc=$rc"; return 12 ;;
  esac
}

n_order_verify() {
  local node=$1 out
  out=$(python3 "$here/../lib/ordercheck.py" --tx "$work/sorted_tx.dat" \
    2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR 'order/duplicate check failed'
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}

c12_step 003a-build-sort n_build_sort
c12_step 003b-sort n_sort
c12_step 003c-order-verify n_order_verify
c12_job_exit
