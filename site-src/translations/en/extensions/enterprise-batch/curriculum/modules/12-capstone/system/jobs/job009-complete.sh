#!/usr/bin/env bash
# JOB009 Completion marker and next-day preparation -- nodes 009a/009b/009c.
# Only after the published manifest carries this run's id is the completion
# marker written.  A stale publish/<run_id> can never be mistaken for this run.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
verify_lib="$NIGHT_REPO/curriculum/modules/10-jobs/lib/verify_publish.py"

n_runid_confirm() {
  local node=$1 curf="$NIGHT_OUTPUT/publish/CURRENT"
  [[ -f $curf ]] || { c12_log "$node" ERROR 'CURRENT pointer missing'; return 12; }
  [[ $(cat "$curf") == "$NIGHT_RUN_ID" ]] || {
    c12_log "$node" ERROR 'CURRENT points at a different run (stale)'; return 12; }
  python3 "$verify_lib" --dir "$NIGHT_OUTPUT/publish/$NIGHT_RUN_ID" \
    --run-id "$NIGHT_RUN_ID" --business-date "$NIGHT_DATE" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'published manifest invalid'; return 12; }
  c12_marker "$node" 0
}

n_complete() {
  local node=$1
  if c12_fault complete; then
    c12_log "$node" ERROR 'injected I/O failure: completion marker'
    return 12
  fi
  {
    printf 'business_date=%s\n' "$NIGHT_DATE"
    printf 'run_id=%s\n' "$NIGHT_RUN_ID"
    printf 'layout=%s\n' "$NIGHT_LAYOUT"
    printf 'published=%s\n' "$NIGHT_OUTPUT/publish/$NIGHT_RUN_ID"
    printf 'completed=%s\n' "$(c12_now)"
    printf 'db_layer=offline-file-checkpoint (real DB NOT verified)\n'
  } >"$NIGHT_OUTPUT/state/complete.marker"
  printf 'date|%s|run_id|%s|layout|%s|phase|published|rc|0\n' \
    "$NIGHT_DATE" "$NIGHT_RUN_ID" "$NIGHT_LAYOUT" \
    >>"$NIGHT_DB/run/$NIGHT_DATE.table"
  c12_marker "$node" 0
}

n_nextday() {
  local node=$1
  if c12_fault nextday; then
    c12_log "$node" ERROR 'injected I/O failure: next-day preparation'
    return 12
  fi
  cat >"$NIGHT_OUTPUT/state/next-day.txt" <<EOF
Next-day preparation (JOB009)
- The published closing-master.dat becomes the next business date opening.
- Re-seed the next day's DB store from:
  $NIGHT_OUTPUT/publish/$NIGHT_RUN_ID/closing-master.dat
- Never delete the completion marker to force a re-apply; use an idempotent
  rerun with a new --output and the same --db instead.
- The customer store is now CAP-CUSTOMER-FEED v2 (32 bytes); downstream
  readers must declare v2 and must not read the canonical 27 byte CUSTOMER
  v1 status byte (byte 27) as a distinction.
EOF
  c12_marker "$node" 0
}

c12_step 009a-runid-confirm n_runid_confirm
c12_step 009b-nextday n_nextday
c12_step 009c-complete n_complete
c12_job_exit
