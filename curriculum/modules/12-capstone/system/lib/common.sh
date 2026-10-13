#!/usr/bin/env bash
# Module 12 capstone: shared helpers for the 30-node nightly chain.
# Sourced, not run.  Callers must export:
#   NIGHT_INPUT NIGHT_OUTPUT NIGHT_DB NIGHT_DATE NIGHT_RUN_ID
#   NIGHT_LOG_DIR NIGHT_LAYOUT NIGHT_REPO
# Every caller sets LC_ALL=C itself.  All paths tolerate spaces.
#
# The capstone deliberately reuses the canonical module 06/07/10 programs
# and the module 10 offline DB/control contracts instead of re-implementing
# them, so the "strange version" is a composition, not a fork.

c12_now() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

# c12_joblog NODE LEVEL MESSAGE...
c12_joblog() {
  local node=$1 level=$2; shift 2
  printf '%s | %s | %s\n' "$(c12_now)" "$level" "$*" \
    >>"$NIGHT_LOG_DIR/$node.log"
}

# c12_log NODE LEVEL MESSAGE...  (also mirrors to the aggregated log + stderr)
c12_log() {
  local node=$1 level=$2; shift 2
  printf '%s | %s | %s | %s\n' "$(c12_now)" "$node" "$level" "$*" \
    >>"$NIGHT_LOG_DIR/nightly.log"
  c12_joblog "$node" "$level" "$*"
  printf '%s %s: %s\n' "$node" "$level" "$*" >&2
}

# c12_require NODE VAR...
c12_require() {
  local node=$1; shift
  local name
  for name in "$@"; do
    if [[ -z ${!name:-} ]]; then
      c12_log "$node" ERROR "missing required environment $name"
      return 12
    fi
  done
}

# c12_marker NODE RC [note]
c12_marker() {
  local node=$1 rc=$2 note=${3:-}
  {
    printf 'node=%s\n' "$node"
    printf 'rc=%s\n' "$rc"
    printf 'business_date=%s\n' "$NIGHT_DATE"
    printf 'run_id=%s\n' "$NIGHT_RUN_ID"
    printf 'layout=%s\n' "$NIGHT_LAYOUT"
    printf 'finished=%s\n' "$(c12_now)"
    [[ -z $note ]] || printf 'note=%s\n' "$note"
  } >"$NIGHT_OUTPUT/state/$node.done"
}

c12_done() { [[ -f "$NIGHT_OUTPUT/state/$1.done" ]]; }

# c12_start NODE : verify env, honor resume, bump the node counter.
# Returns 0 to continue, 10 when the node is already complete (resume),
# 12 on a missing-environment system error.
c12_start() {
  local node=$1
  if ! c12_require "$node" NIGHT_OUTPUT NIGHT_DATE NIGHT_RUN_ID \
        NIGHT_LOG_DIR NIGHT_LAYOUT; then
    return 12
  fi
  mkdir -p -- "$NIGHT_OUTPUT/state" "$NIGHT_LOG_DIR"
  if c12_done "$node"; then
    local rc
    rc=$(sed -n 's/^rc=//p' "$NIGHT_OUTPUT/state/$node.done" | head -1)
    [[ $rc == 4 || $rc == 8 ]] && c12_bump "$rc"
    c12_log "$node" INFO "resume: already complete (rc=$rc)"
    return 10
  fi
  c12_log "$node" INFO start
  return 0
}

# c12_bump RC : record the highest "warning-ish" RC seen so far on this run
# in a run-scoped file so the driver can fold it into the overall RC.
c12_bump() {
  local rc=$1
  local f="$NIGHT_OUTPUT/state/.rc"
  local cur=0
  [[ -f $f ]] && cur=$(cat "$f")
  case "$rc" in
    4) [[ $cur == 0 ]] && printf '4\n' >"$f" ;;
    8) printf '8\n' >"$f" ;;
    12) printf '12\n' >"$f" ;;
  esac
}

# c12_sha FILE
c12_sha() { sha256sum -- "$1" | cut -d' ' -f1; }

# c12_fault POINT : true when the caller injected an I/O failure at POINT.
# Exercises the post-publish persistence boundaries (publish registry,
# completion marker, next-day preparation) without deleting real output.
c12_fault() { [[ ${NIGHT_INJECT_FAIL:-} == "$1" ]]; }

# c12_run NODE FUNC : resume-aware node runner.
#   marker present -> skip (returns 0)
#   otherwise runs FUNC NODE; FUNC must write its own marker and echo the RC.
c12_run() {
  local node=$1 func=$2 st=0
  c12_start "$node" || st=$?
  case "$st" in
    10) return 0 ;;
    0) "$func" "$node" ;;
    *) return 12 ;;
  esac
}

# c12_step NODE FUNC : run a node inside a JOB group, folding RCs.
#   RC0 -> continue; RC4 -> remember warning, continue; RC8/12 -> stop.
c12_step() {
  local rc=0
  c12_run "$1" "$2" || rc=$?
  case "$rc" in
    0) ;;
    4) [[ ${C12_JOB_RC:-0} == 0 ]] && C12_JOB_RC=4 || true ;;
    97) exit 97 ;;
    8|12) c12_bump "$rc"; exit "$rc" ;;
    *) c12_bump 12; exit 12 ;;
  esac
  return 0
}
c12_job_exit() { exit "${C12_JOB_RC:-0}"; }

# c12_map_rc CHILD_RC : map an arbitrary child RC to the course RC set.
c12_map_rc() {
  case "$1" in
    0|4|8|12) printf '%s\n' "$1" ;;
    *) printf '12\n' ;;
  esac
}

# Canonical component locations (resolved from the repository root).
c12_module10() { printf '%s/curriculum/modules/10-jobs' "$NIGHT_REPO"; }
c12_sort_runner() {
  printf '%s/curriculum/modules/07-matching/labs/02-sort-merge/01-sort/scripts/run.sh' \
    "$NIGHT_REPO"
}
c12_match_runner() {
  printf '%s/curriculum/modules/07-matching/labs/03-one-to-many/scripts/run.sh' \
    "$NIGHT_REPO"
}
# c12_bankval_source : the transaction business-rule validator (canonical
# module 10).  The system runs the learner's own completed BANKVAL: an explicit
# CAPSTONE_STUDENT_BANKVAL wins, else the instructor reference when present
# (authoring repo), else the learner's module 10 starter.
c12_bankval_source() {
  if [[ -n ${CAPSTONE_STUDENT_BANKVAL:-} ]]; then
    printf '%s' "$CAPSTONE_STUDENT_BANKVAL"
  elif [[ -f $NIGHT_REPO/instructor/modules/10-jobs/BANKVAL.COB ]]; then
    printf '%s/instructor/modules/10-jobs/BANKVAL.COB' "$NIGHT_REPO"
  else
    printf '%s/curriculum/modules/10-jobs/starter/BANKVAL.COB' "$NIGHT_REPO"
  fi
}

# c12_copybooks : capstone interface copybook directory.
c12_copybooks() {
  printf '%s/curriculum/modules/12-capstone/system/copybooks' "$NIGHT_REPO"
}

# c12_custv2_source : the customer validator source.  An explicit
# CAPSTONE_STUDENT_CUSTV2 (learner's own completed program) always wins.  In
# the authoring repository the nightly chain uses the reference answer
# (system/cobol/CUSTV2.COB) so the course regression can run a complete system;
# that file is deliberately excluded from the student bundle, so a learner runs
# the capstone starter (completed in place) instead.
c12_custv2_source() {
  if [[ -n ${CAPSTONE_STUDENT_CUSTV2:-} ]]; then
    printf '%s' "$CAPSTONE_STUDENT_CUSTV2"
  elif [[ -f $NIGHT_REPO/curriculum/modules/12-capstone/system/cobol/CUSTV2.COB ]]; then
    printf '%s/curriculum/modules/12-capstone/system/cobol/CUSTV2.COB' "$NIGHT_REPO"
  else
    printf '%s/curriculum/modules/12-capstone/starter/CUSTV2.COB' "$NIGHT_REPO"
  fi
}

# c12_build SRC BIN : compile a COBOL program into the run's bin dir.
c12_build() {
  local src=$1 bin=$2
  [[ -x $bin ]] && return 0
  mkdir -p -- "$(dirname -- "$bin")"
  if ! cobc -Wall -I "$(c12_copybooks)" -x -o "$bin" "$src" \
        >>"$NIGHT_LOG_DIR/build.log" 2>&1; then
    return 12
  fi
}
