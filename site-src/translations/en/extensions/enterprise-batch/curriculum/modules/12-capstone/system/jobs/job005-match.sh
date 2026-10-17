#!/usr/bin/env bash
# JOB005 Sequential matching and balance calculation -- nodes 005a/005b/005c.
# Reuses the canonical module 07 L2 (1:N) matcher - one match implementation
# for the whole course.  The candidate closing master stays isolated in
# work/closing until JOB007 has reconciled it and JOB008 publishes.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
work="$NIGHT_OUTPUT/work"
matcher=$(c12_match_runner)

n_keybreak_balance() {
  local node=$1 out="$work/closing" rc=0
  [[ -f $matcher ]] || { c12_log "$node" ERROR 'module 07 matcher runner missing'; return 12; }
  [[ ! -e $out ]] || { c12_log "$node" ERROR 'closing candidate already exists'; return 12; }
  : >"$work/empty-reversal.dat"
  set +e
  bash "$matcher" "$work/db/account_master.dat" "$work/sorted_tx.dat" \
    "$work/empty-reversal.dat" "$out" "$NIGHT_DATE" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0|4) c12_marker "$node" "$rc"; return "$rc" ;;
    8) c12_log "$node" ERROR 'match business failure (unsorted/duplicate/overflow)'
       c12_marker "$node" 8; return 8 ;;
    *) c12_log "$node" ERROR "match failed rc=$rc"; return 12 ;;
  esac
}

n_accept_reject() {
  local node=$1
  for f in master.dat accepted.dat rejected.dat report.txt; do
    [[ -f $work/closing/$f ]] || { c12_log "$node" ERROR "missing closing/$f"; return 12; }
  done
  c12_marker "$node" 0
}

n_candidate_isolate() {
  local node=$1
  # The candidate is intentionally not visible under publish/ yet.
  [[ ! -e $NIGHT_OUTPUT/publish && ! -e $NIGHT_OUTPUT/publish/CURRENT ]] || {
    c12_log "$node" ERROR 'publish area existed before JOB008'; return 12; }
  c12_marker "$node" 0
}

c12_step 005a-keybreak-balance n_keybreak_balance
c12_step 005b-accept-reject n_accept_reject
c12_step 005c-candidate-isolate n_candidate_isolate
c12_job_exit
