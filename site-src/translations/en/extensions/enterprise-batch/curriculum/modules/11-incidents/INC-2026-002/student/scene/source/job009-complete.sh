#!/usr/bin/env bash
# JOB009 Completion marker and next-day preparation: only after the published manifest carries
# this run's id, write the completion marker and next-day notes.
set -Eeuo pipefail
export LC_ALL=C
job=JOB009
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_RUN_ID BANK_LOG_DIR \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

curf="$BANK_RUN_DIR/publish/CURRENT"
[[ -f $curf ]] || { b_log "$job" ERROR 'CURRENT pointer missing'; exit 12; }
[[ $(cat "$curf") == "$BANK_RUN_ID" ]] || {
  b_log "$job" ERROR 'CURRENT points at a different run (stale result)'; exit 12; }
python3 "$here/../lib/verify_publish.py" \
  --dir "$BANK_RUN_DIR/publish/$BANK_RUN_ID" \
  --run-id "$BANK_RUN_ID" --business-date "$BANK_BUSINESS_DATE" \
  || { b_log "$job" ERROR 'published manifest invalid'; exit 12; }

{
  printf 'business_date=%s\n' "$BANK_BUSINESS_DATE"
  printf 'run_id=%s\n' "$BANK_RUN_ID"
  printf 'published=%s\n' "$BANK_RUN_DIR/publish/$BANK_RUN_ID"
  printf 'completed=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'db_layer=offline-file-checkpoint (real DB NOT verified)\n'
} >"$BANK_RUN_DIR/state/complete.marker"

cat >"$BANK_RUN_DIR/state/next-day.txt" <<EOF
Next-day preparation (JOB009)
- The published closing master becomes the next business date opening.
- Re-seed the next day's DB store from: $BANK_RUN_DIR/publish/$BANK_RUN_ID/closing-master.dat
- Never delete the completion marker to force a re-apply; use an idempotent
  rerun with a new --output and the same --db instead.
EOF
b_joblog "$job" INFO 'completion marker written; next-day notes prepared'
b_marker "$job" 0
exit 0
