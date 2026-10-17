#!/usr/bin/env bash
# JOB003 SORT and ordering verification: reuse the accepted module 07 SORT reference
# (instructor/modules/07/.../SORTTX.COB via its own runner) so this
# course has exactly one canonical transaction-sort implementation.
set -Eeuo pipefail
export LC_ALL=C
job=JOB003
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR BANK_REPO \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

sorter="$BANK_REPO/curriculum/modules/07-matching/labs/02-sort-merge/01-sort/scripts/run.sh"
[[ -f $sorter ]] || { b_log "$job" ERROR "module 07 sort runner missing"; exit 12; }
out="$BANK_RUN_DIR/work/sorted_tx.dat"
mkdir -p -- "$BANK_RUN_DIR/work"
[[ ! -e $out ]] || { b_log "$job" ERROR 'sorted output already exists'; exit 12; }

set +e
B02_DATE="$BANK_BUSINESS_DATE" bash "$sorter" \
  "$BANK_RUN_DIR/work/validate/accepted_tx.dat" "$out" \
  >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0) b_joblog "$job" INFO 'sort verified'; b_marker "$job" 0; exit 0 ;;
  8|12) b_log "$job" ERROR "sort failed rc=$rc"; exit "$rc" ;;
  *) b_log "$job" ERROR "unexpected sort rc=$rc mapped 12"; exit 12 ;;
esac
