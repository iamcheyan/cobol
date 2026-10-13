#!/usr/bin/env bash
# JOB008 下游文件发布 -- nodes 008a/008b/008c/008d.
# Stage under a private run directory, verify the manifest, then publish
# atomically.  A partially staged or pre-existing result is never presented
# as this run's result.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
work="$NIGHT_OUTPUT/work"
manifest_lib="$NIGHT_REPO/curriculum/modules/10-jobs/lib/manifest.py"
verify_lib="$NIGHT_REPO/curriculum/modules/10-jobs/lib/verify_publish.py"
stage="$work/publish/$NIGHT_RUN_ID"
root="$NIGHT_OUTPUT/publish/$NIGHT_RUN_ID"

n_stage() {
  local node=$1
  rm -rf -- "$stage"
  mkdir -p -- "$stage" "$NIGHT_OUTPUT/publish" "$work/publish"
  cp -- "$work/closing/master.dat"       "$stage/closing-master.dat"
  cp -- "$work/closing/accepted.dat"     "$stage/accepted-tx.dat"
  cp -- "$work/closing/rejected.dat"     "$stage/rejected-match.dat"
  cp -- "$work/validate/rejected.txt"    "$stage/rejected-validate.txt"
  cp -- "$work/customer/customer_v2.dat" "$stage/customer-v2.dat"
  cp -- "$work/report/customer-day.dat"  "$stage/customer-day.dat"
  cp -- "$work/report/daily-report.txt"  "$stage/daily-report.txt"
  cp -- "$work/validate/control.txt"     "$stage/validate-control.txt"
  cp -- "$work/customer/control.txt"     "$stage/customer-control.txt"
  c12_marker "$node" 0
}

n_manifest() {
  local node=$1
  python3 "$manifest_lib" --dir "$stage" --run-id "$NIGHT_RUN_ID" \
    --business-date "$NIGHT_DATE" --engine capstone-offline-file-checkpoint \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'manifest build failed'; return 12; }
  python3 "$verify_lib" --dir "$stage" --run-id "$NIGHT_RUN_ID" \
    --business-date "$NIGHT_DATE" >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'staged manifest verification failed'; return 12; }
  c12_marker "$node" 0
}

n_atomic_switch() {
  local node=$1
  if [[ -d $root ]]; then
    python3 "$verify_lib" --dir "$root" --run-id "$NIGHT_RUN_ID" \
      --business-date "$NIGHT_DATE" >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
      c12_log "$node" ERROR 'existing publish dir failed verification'; return 12; }
    c12_joblog "$node" INFO 'reusing verified publish dir from interrupted run'
    c12_marker "$node" 0
    return 0
  fi
  if [[ ${NIGHT_CRASH_AT:-} == during-publish ]]; then
    c12_log "$node" WARN 'injected crash during publish (staged, not switched)'
    return 97
  fi
  mv -T -n -- "$stage" "$root" || {
    c12_log "$node" ERROR 'publish collision'; return 12; }
  [[ ! -e $stage ]] || { c12_log "$node" ERROR 'staged dir still present'; return 12; }
  c12_marker "$node" 0
}

n_current() {
  local node=$1 tmp
  tmp="$NIGHT_OUTPUT/publish/.CURRENT.$NIGHT_RUN_ID"
  printf '%s\n' "$NIGHT_RUN_ID" >"$tmp"
  mv -f -- "$tmp" "$NIGHT_OUTPUT/publish/CURRENT"
  [[ $(cat "$NIGHT_OUTPUT/publish/CURRENT") == "$NIGHT_RUN_ID" ]] || {
    c12_log "$node" ERROR 'CURRENT pointer not updated'; return 12; }
  if c12_fault registry; then
    c12_log "$node" ERROR 'injected I/O failure: publish registry'
    return 12
  fi
  python3 "$here/../lib/capdb.py" record-publish --db "$NIGHT_DB" \
    --business-date "$NIGHT_DATE" --run-id "$NIGHT_RUN_ID" \
    --manifest "$root/manifest.json" --published "$(c12_now)" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'publish registry record failed'; return 12; }
  c12_marker "$node" 0
}

c12_step 008a-stage n_stage
c12_step 008b-manifest n_manifest
c12_step 008c-atomic-switch n_atomic_switch
c12_step 008d-current n_current
c12_job_exit
