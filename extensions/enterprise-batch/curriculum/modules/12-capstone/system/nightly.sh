#!/usr/bin/env bash
# Module 12 capstone nightly chain: JOB001 -> JOB009 (32 nodes) with
# per-JOB marker based resume, RC dependency policy and crash injection.
#
#   dependency policy: only RC0 proceeds; RC4 is an explicitly allowed
#   business warning for JOB002/JOB005/JOB006; RC8/12 stop the net and
#   publish nothing; RC97 is an injected-lab crash that preserves state.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$here/lib/common.sh"
c12_require NIGHTLY NIGHT_OUTPUT NIGHT_DATE NIGHT_RUN_ID NIGHT_LOG_DIR \
  || exit "$?"
mkdir -p -- "$NIGHT_OUTPUT/state" "$NIGHT_LOG_DIR"

overall=0
run_job() {
  local job=$1 script=$2 rc
  if c12_done "$job"; then
    rc=$(sed -n 's/^rc=//p' "$NIGHT_OUTPUT/state/$job.done" | head -1)
    [[ $rc == 4 ]] && overall=4
    c12_log "$job" INFO "resume: already complete (rc=$rc)"
    return 0
  fi
  set +e
  bash "$script"
  rc=$?
  set -e
  case "$rc" in
    97) c12_log "$job" WARN 'injected crash (rc=97)'; exit 97 ;;
    0) c12_marker "$job" 0 ;;
    4) overall=4; c12_marker "$job" 4 ;;
    8) c12_log "$job" ERROR 'business failure rc=8'; exit 8 ;;
    12) c12_log "$job" ERROR 'system failure rc=12'; exit 12 ;;
    *) c12_log "$job" ERROR "unexpected rc=$rc; mapped to 12"; exit 12 ;;
  esac
}

run_job JOB001 "$here/jobs/job001-receive.sh"
run_job JOB002 "$here/jobs/job002-validate.sh"
run_job JOB003 "$here/jobs/job003-sort.sh"
run_job JOB004 "$here/jobs/job004-db-snapshot.sh"
run_job JOB005 "$here/jobs/job005-match.sh"
run_job JOB006 "$here/jobs/job006-db-apply.sh"
run_job JOB007 "$here/jobs/job007-control.sh"
run_job JOB008 "$here/jobs/job008-publish.sh"
if [[ ${NIGHT_CRASH_AT:-} == after-publish ]]; then
  c12_log JOB008 WARN 'injected crash after publish, before completion'
  exit 97
fi
run_job JOB009 "$here/jobs/job009-complete.sh"
exit "$overall"
