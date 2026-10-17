#!/usr/bin/env bash
# JOB007 Control totals and daily report reconciliation: independent conservation check across the
# real streams plus the DB ledger.  A mismatch must stop publication.
set -Eeuo pipefail
export LC_ALL=C
job=JOB007
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_DB_DIR BANK_BUSINESS_DATE BANK_LOG_DIR \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

set +e
python3 "$here/../lib/control.py" >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0) b_marker "$job" 0; exit 0 ;;
  8) b_log "$job" ERROR 'control totals do not reconcile'; exit 8 ;;
  *) b_log "$job" ERROR "unexpected control rc=$rc mapped 12"; exit 12 ;;
esac
