#!/usr/bin/env bash
# Nightly JOB flow driver for module 10: JOB001 -> JOB009 with marker
# based resume, RC dependency policy, and crash injection hooks.
#
#   dependency policy: only RC0 proceeds; RC4 is a Warning that is
#   explicitly allowed through for JOB002/JOB005; RC8/12 stop the net.
#   resume: a job whose marker exists is skipped, so a rerun after a
#   crash resumes at the failed stage.  RC97 = injected crash for labs.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require NIGHTLY BANK_RUN_DIR BANK_BUSINESS_DATE BANK_RUN_ID BANK_LOG_DIR \
  || exit "$?"
mkdir -p -- "$BANK_RUN_DIR/state" "$BANK_LOG_DIR"

overall=0
run_job() {
  local job=$1 script=$2 rc
  if b_done "$job"; then
    rc=$(sed -n 's/^rc=//p' "$BANK_RUN_DIR/state/$job.done" | head -1)
    [[ $rc == 4 ]] && overall=4
    b_log "$job" INFO "resume: already complete (rc=$rc)"
    return 0
  fi
  b_log "$job" INFO 'start'
  set +e
  bash "$script"
  rc=$?
  set -e
  case "$rc" in
    97) b_log "$job" WARN 'injected crash (rc=97)'; exit 97 ;;
    0) : ;;
    4) overall=4 ;;
    8) b_log "$job" ERROR 'business failure rc=8'; exit 8 ;;
    12) b_log "$job" ERROR 'system failure rc=12'; exit 12 ;;
    *) b_log "$job" ERROR "unexpected rc=$rc; mapped to 12"; exit 12 ;;
  esac
}

run_job JOB001 "$here/job001-receive.sh"
run_job JOB002 "$here/job002-validate.sh"
run_job JOB003 "$here/job003-sort.sh"
run_job JOB004 "$here/job004-db-snapshot.sh"
run_job JOB005 "$here/job005-match.sh"
run_job JOB006 "$here/job006-db-apply.sh"
run_job JOB007 "$here/job007-control.sh"
run_job JOB008 "$here/job008-publish.sh"
if [[ ${BANK_CRASH_AT:-} == after-publish ]]; then
  b_log JOB008 WARN 'injected crash after publish, before completion'
  exit 97
fi
run_job JOB009 "$here/job009-complete.sh"
exit "$overall"
