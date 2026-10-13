#!/usr/bin/env bash
# Shared helpers for the module 10 nightly JOB chain.  Sourced, not run.
# Every caller must already have exported:
#   BANK_RUN_DIR BANK_DB_DIR BANK_BUSINESS_DATE BANK_RUN_ID BANK_LOG_DIR
#   BANK_REPO (repository root)
# All helpers are LC_ALL=C safe; callers set LC_ALL=C themselves.

b_log() {  # b_log JOB LEVEL MESSAGE...
  local job=$1 level=$2; shift 2
  printf '%s | %s | %s | %s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$job" "$level" "$*" \
    >>"$BANK_LOG_DIR/nightly.log"
  printf '%s %s: %s\n' "$job" "$level" "$*" >&2
}

b_joblog() {  # b_joblog JOB LEVEL MESSAGE...
  local job=$1 level=$2; shift 2
  printf '%s | %s | %s\n' \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" \
    >>"$BANK_LOG_DIR/$job.log"
}

b_marker() {  # b_marker JOB RC [extra]
  local job=$1 rc=$2 extra=${3:-}
  {
    printf 'job=%s\n' "$job"
    printf 'rc=%s\n' "$rc"
    printf 'business_date=%s\n' "$BANK_BUSINESS_DATE"
    printf 'run_id=%s\n' "$BANK_RUN_ID"
    printf 'finished=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    [[ -z $extra ]] || printf 'note=%s\n' "$extra"
  } >"$BANK_RUN_DIR/state/$job.done"
}

b_done() {  # b_done JOB  -> 0 if marker present
  [[ -f "$BANK_RUN_DIR/state/$1.done" ]]
}

b_require() {  # b_require JOB VAR...
  local job=$1; shift
  local name
  for name in "$@"; do
    if [[ -z ${!name:-} ]]; then
      b_log "$job" ERROR "missing required environment $name"
      return 12
    fi
  done
}

b_sha() { sha256sum -- "$1" | cut -d' ' -f1; }

# b_fault POINT : true when the caller injected an I/O failure at POINT.
# Used to exercise the persistence boundaries after publish (completion
# marker, next-day preparation) without deleting real output to fake a
# failure.
b_fault() { [[ ${BANK_INJECT_FAIL:-} == "$1" ]]; }

# Map an arbitrary child RC to a course RC.  Course RC 0/4/8/12 pass
# through; any other value (including 128+signal from a killed child) is
# a system failure and becomes RC12.
b_map_rc() {
  case "$1" in
    0|4|8|12) printf '%s\n' "$1" ;;
    *) printf '12\n' ;;
  esac
}
