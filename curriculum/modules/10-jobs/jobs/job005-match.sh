#!/usr/bin/env bash
# JOB005 顺序突合及余额计算: reuse the accepted module 07 L2 matcher
# (instructor/modules/07/03-one-to-many/BATCHL2.COB via its own runner).
# The candidate closing master stays isolated until JOB006/JOB008.
set -Eeuo pipefail
export LC_ALL=C
job=JOB005
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR BANK_REPO \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

matcher="$BANK_REPO/curriculum/modules/07-matching/labs/03-one-to-many/scripts/run.sh"
[[ -f $matcher ]] || { b_log "$job" ERROR "module 07 matcher runner missing"; exit 12; }
out="$BANK_RUN_DIR/work/closing"
[[ ! -e $out ]] || { b_log "$job" ERROR 'closing candidate already exists'; exit 12; }
: >"$BANK_RUN_DIR/work/empty-reversal.dat"

set +e
bash "$matcher" "$BANK_RUN_DIR/work/db/account_master.dat" \
  "$BANK_RUN_DIR/work/sorted_tx.dat" \
  "$BANK_RUN_DIR/work/empty-reversal.dat" "$out" "$BANK_BUSINESS_DATE" \
  >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0|4)
    for f in master.dat accepted.dat rejected.dat report.txt; do
      [[ -f $out/$f ]] || { b_log "$job" ERROR "missing $f"; exit 12; }
    done
    b_joblog "$job" INFO "match rc=$rc"
    b_marker "$job" "$rc"
    exit "$rc" ;;
  8|12) b_log "$job" ERROR "match failed rc=$rc"; exit "$rc" ;;
  *) b_log "$job" ERROR "unexpected match rc=$rc mapped 12"; exit 12 ;;
esac
