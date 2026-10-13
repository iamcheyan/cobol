#!/usr/bin/env bash
# JOB006 DB 更新及幂等账本 -- nodes 006a/006b/006c.
# The ledger is the source of truth: a rerun after a crash, or a same-day
# rerun, never double-debits.  Recovery always reads the ledger first.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
capdb="$here/../lib/capdb.py"
work="$NIGHT_OUTPUT/work"

n_ledger_read() {
  local node=$1
  python3 "$capdb" idempotency --db "$NIGHT_DB" --business-date "$NIGHT_DATE" \
    >"$work/db/ledger-before.json" 2>>"$NIGHT_LOG_DIR/$node.log" || {
    c12_log "$node" ERROR 'ledger read failed'; return 12; }
  c12_marker "$node" 0
}

n_idempotent_apply() {
  local node=$1 inject="" rc=0
  case "${NIGHT_CRASH_AT:-}" in
    before-db-commit) inject=before ;;
    mid-db-commit) inject=ledger ;;
    after-db-commit) inject=after ;;
  esac
  mkdir -p -- "$work/db"
  set +e
  if [[ -n $inject ]]; then
    python3 "$capdb" apply --db "$NIGHT_DB" --business-date "$NIGHT_DATE" \
      --run-id "$NIGHT_RUN_ID" --layout "$NIGHT_LAYOUT" \
      --accepted "$work/closing/accepted.dat" \
      --candidate-master "$work/closing/master.dat" --inject "$inject" \
      >"$work/db/apply.json" 2>>"$NIGHT_LOG_DIR/$node.log"
  else
    python3 "$capdb" apply --db "$NIGHT_DB" --business-date "$NIGHT_DATE" \
      --run-id "$NIGHT_RUN_ID" --layout "$NIGHT_LAYOUT" \
      --accepted "$work/closing/accepted.dat" \
      --candidate-master "$work/closing/master.dat" \
      >"$work/db/apply.json" 2>>"$NIGHT_LOG_DIR/$node.log"
  fi
  rc=$?
  set -e
  case "$rc" in
    0) c12_marker "$node" 0; return 0 ;;
    4) c12_marker "$node" 4; return 4 ;;
    8) c12_log "$node" ERROR 'idempotency/balance check failed'
       c12_marker "$node" 8; return 8 ;;
    97) c12_log "$node" WARN 'injected crash during DB commit'; return 97 ;;
    *) c12_log "$node" ERROR "DB apply system failure rc=$rc"; return 12 ;;
  esac
}

n_commit_marker() {
  local node=$1
  [[ -f $NIGHT_DB/commit/$NIGHT_DATE.json ]] || {
    c12_log "$node" ERROR 'commit marker missing after apply'; return 12; }
  c12_marker "$node" 0
}

c12_step 006a-ledger-read n_ledger_read
c12_step 006b-idempotent-apply n_idempotent_apply
c12_step 006c-commit-marker n_commit_marker
c12_job_exit
