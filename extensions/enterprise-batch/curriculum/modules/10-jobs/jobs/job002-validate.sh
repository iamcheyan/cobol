#!/usr/bin/env bash
# JOB002 长度与业务校验: run the fixed-format COBOL validator over the
# frozen snapshot.  RC0 clean, RC4 business rejects allowed through,
# RC8 structural error (bad length / non-numeric key), RC12 system.
set -Eeuo pipefail
export LC_ALL=C
job=JOB002
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR BANK_REPO \
  BANK_COURSE_SOURCE || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

work="$BANK_RUN_DIR/work/validate"
mkdir -p -- "$work"
bin="$BANK_RUN_DIR/work/bin"
mkdir -p -- "$bin"
b_joblog "$job" INFO "build validator from $BANK_COURSE_SOURCE"
if ! cobc -Wall -I "$BANK_REPO/curriculum/modules/10-jobs/copybooks" -x \
      -o "$bin/bankval" "$BANK_COURSE_SOURCE" >>"$BANK_LOG_DIR/$job.log" 2>&1; then
  b_log "$job" ERROR 'validator build failed'; exit 12
fi

set +e
BANKVAL_IN="$BANK_RUN_DIR/snapshot/transaction.dat" \
BANKVAL_ACCEPTED="$work/accepted_tx.dat" \
BANKVAL_REJECTED="$work/rejected.txt" \
BANKVAL_CONTROL="$work/control.txt" \
BANKVAL_DATE="$BANK_BUSINESS_DATE" \
  "$bin/bankval" >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0|4)
    b_joblog "$job" INFO "validator rc=$rc"
    b_marker "$job" "$rc"
    exit "$rc" ;;
  8|12)
    b_log "$job" ERROR "validator failed rc=$rc"; exit "$rc" ;;
  *)
    b_log "$job" ERROR "unexpected validator rc=$rc mapped 12"; exit 12 ;;
esac
