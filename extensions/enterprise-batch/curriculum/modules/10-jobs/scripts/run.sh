#!/usr/bin/env bash
# Module 10 nightly entry point.
#
#   run.sh --input DIR --output DIR --db DIR --business-date YYYYMMDD
#          [--run-id ID] [--config FILE] [--command run|status]
#          [--crash-at POINT]
#
# Parameter precedence: CLI > --config file > allowlisted BANK_* env >
# built-in default.  Environment variables only carry agreed config.
# Works from any cwd, tolerates spaces in paths, never overwrites an
# existing result, holds a lock, and publishes nothing unless every job
# that may fail has succeeded.
#
# Crash points (labs): before-db-commit | mid-db-commit | after-db-commit
#                     | during-publish | after-publish
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$module/../../.." && pwd)
lib="$module/lib"

usage() {
  cat >&2 <<'EOF'
usage: run.sh --input DIR --output DIR --db DIR --business-date YYYYMMDD
              [--run-id ID] [--config FILE] [--command run|status]
              [--crash-at POINT]
EOF
  exit 12
}

in_cli=''; out_cli=''; db_cli=''; date_cli=''; runid_cli=''
config=''; command=run; crash=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) [[ $# -ge 2 ]] || usage; in_cli=$2; shift 2 ;;
    --output) [[ $# -ge 2 ]] || usage; out_cli=$2; shift 2 ;;
    --db) [[ $# -ge 2 ]] || usage; db_cli=$2; shift 2 ;;
    --business-date) [[ $# -ge 2 ]] || usage; date_cli=$2; shift 2 ;;
    --run-id) [[ $# -ge 2 ]] || usage; runid_cli=$2; shift 2 ;;
    --config) [[ $# -ge 2 ]] || usage; config=$2; shift 2 ;;
    --command) [[ $# -ge 2 ]] || usage; command=$2; shift 2 ;;
    --crash-at) [[ $# -ge 2 ]] || usage; crash=$2; shift 2 ;;
    -h|--help) usage ;;
    *) echo "run.sh: unknown argument '$1'" >&2; usage ;;
  esac
done

cfg_input=''; cfg_output=''; cfg_db=''; cfg_date=''; cfg_run=''
if [[ -n $config ]]; then
  [[ -f $config && -r $config ]] || { echo "config not readable" >&2; exit 12; }
  while IFS= read -r line; do
    line=${line%%#*}
    [[ $line == *=* ]] || continue
    key=${line%%=*}; value=${line#*=}
    key=${key//[[:space:]]/}; value=${value#"${value%%[![:space:]]*}"}
    case "$key" in
      input) cfg_input=$value ;;
      output) cfg_output=$value ;;
      db) cfg_db=$value ;;
      business_date) cfg_date=$value ;;
      run_id) cfg_run=$value ;;
    esac
  done <"$config"
fi

input=${in_cli:-${cfg_input:-${BANK_INPUT:-}}}
output=${out_cli:-${cfg_output:-${BANK_OUTPUT:-}}}
db=${db_cli:-${cfg_db:-${BANK_DB_DIR:-}}}
date=${date_cli:-${cfg_date:-${BANK_BUSINESS_DATE:-}}}
runid=${runid_cli:-${cfg_run:-${BANK_RUN_ID:-}}}
crash=${crash:-${BANK_CRASH_AT:-}}
# Default to the instructor reference when present (authoring repo); in a
# student bundle fall back to the learner's own completed starter.
default_course_source="$repo/instructor/modules/10-jobs/BANKVAL.COB"
[[ -f $default_course_source ]] || default_course_source="$module/starter/BANKVAL.COB"
course_source=${BANK_COURSE_SOURCE:-"$default_course_source"}

[[ -n $output && -n $db && -n $date ]] || usage
[[ -d $input && -r $input ]] || { echo "input dir invalid" >&2; exit 12; }
python3 - "$date" <<'PY' || { echo "invalid business date" >&2; exit 8; }
import datetime, sys
try:
    datetime.datetime.strptime(sys.argv[1], "%Y%m%d")
except ValueError:
    raise SystemExit(1)
PY
[[ $date =~ ^[0-9]{8}$ ]] || { echo "invalid business date" >&2; exit 8; }
case "$crash" in
  ''|before-db-commit|mid-db-commit|after-db-commit|during-publish|after-publish) ;;
  *) echo "unknown --crash-at '$crash'" >&2; exit 12 ;;
esac
[[ -z $runid ]] && runid="run-${date}-$$"
[[ $runid =~ ^[A-Za-z0-9._-]+$ ]] || { echo "bad run id" >&2; exit 12; }
[[ -f $course_source ]] || { echo "course source missing" >&2; exit 12; }

if [[ $command == status ]]; then
  [[ -f $output/run.env ]] || { echo "no run at $output" >&2; exit 12; }
  echo "output=$output"
  echo "state:"
  for m in "$output"/state/JOB*.done; do
    [[ -e $m ]] || continue
    echo "  $(basename "$m") $(sed -n 's/^rc=//p' "$m")"
  done
  [[ -f $output/state/complete.marker ]] && echo "complete=yes" || echo "complete=no"
  [[ -f $output/publish/CURRENT ]] && echo "current=$(cat "$output/publish/CURRENT")"
  python3 "$lib/db.py" status --db "$db" --business-date "$date" 2>/dev/null || true
  exit 0
fi

parent=$(dirname -- "$output")
[[ -d $parent ]] || { echo "output parent missing" >&2; exit 12; }
[[ ! -L $output ]] || { echo "output is a symlink" >&2; exit 12; }

outlock="$output.lock"
mkdir -p -- "$db"
dblock="$db/locks/$date.lock"
mkdir -p -- "$db/locks"
if [[ -d $dblock ]]; then
  owner_pid=$(cat "$dblock/pid" 2>/dev/null || true)
  if [[ -n $owner_pid ]] && kill -0 "$owner_pid" 2>/dev/null; then
    echo "another run holds the business-date lock for $date" >&2
    exit 12
  fi
  rm -rf -- "$dblock"
fi
mkdir -- "$dblock" 2>/dev/null || { echo "business-date lock race" >&2; exit 12; }
printf '%s\n' "$$" >"$dblock/pid"
mkdir -- "$outlock" 2>/dev/null || {
  echo "output already locked by another run" >&2; rm -rf -- "$dblock"; exit 12; }

resume=0
cleanup() {
  rmdir -- "$outlock" 2>/dev/null || rm -rf -- "$outlock"
  rm -rf -- "$dblock"
}
trap cleanup EXIT

if [[ -e $output ]]; then
  if [[ -f $output/run.env ]]; then
    if [[ -f $output/state/complete.marker ]]; then
      echo "output already holds a completed run; use a new --output" >&2
      exit 12
    fi
    prev_date=$(sed -n 's/^business_date=//p' "$output/run.env" | head -1)
    prev_run=$(sed -n 's/^run_id=//p' "$output/run.env" | head -1)
    if [[ $prev_date != "$date" || $prev_run != "$runid" ]]; then
      echo "output holds a different run; refusing to resume" >&2
      exit 12
    fi
    resume=1
  else
    echo "output exists and is not a course run; not overwriting" >&2
    exit 12
  fi
else
  mkdir -p -- "$output"
fi

mkdir -p -- "$output/logs" "$output/state"
if [[ $resume == 0 ]]; then
  cat >"$output/run.env" <<EOF
input=$input
output=$output
db=$db
business_date=$date
run_id=$runid
course_source=$course_source
db_layer=offline-file-checkpoint
real_db_verified=false
created=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
EOF
  echo "=== module 10 nightly run $runid for $date ===" >>"$output/logs/nightly.log"
else
  echo "=== resume of $runid for $date ===" >>"$output/logs/nightly.log"
fi

if [[ ! -f $db/account.table ]]; then
  if [[ ! -f $input/account_seed.dat || ! -f $input/customer_seed.dat ]]; then
    echo "DB store empty and no seed files in input" >&2
    exit 12
  fi
  python3 "$lib/db.py" seed --db "$db" \
    --account "$input/account_seed.dat" \
    --customer "$input/customer_seed.dat" || {
    echo "DB seed failed" >&2; exit 12; }
fi
if [[ -f $db/commit/$date.json && $resume == 0 ]]; then
  echo "note: business date $date already committed; rerun will be idempotent" \
    >>"$output/logs/nightly.log"
fi

export BANK_RUN_DIR=$output BANK_DB_DIR=$db BANK_BUSINESS_DATE=$date \
  BANK_RUN_ID=$runid BANK_LOG_DIR="$output/logs" BANK_REPO=$repo \
  BANK_INPUT=$input BANK_COURSE_SOURCE=$course_source BANK_CRASH_AT=$crash

set +e
bash "$module/jobs/nightly.sh"
rc=$?
set -e

# A run is committed once its DB commit marker exists and published once
# publish/CURRENT points at this run (or its publish/<runid> dir exists).
# Those artifacts must never be deleted to manufacture a "failure published
# nothing" appearance; only a genuinely unpublished, uncommitted staging dir
# is removed.
has_committed_or_published() {
  [[ -f $output/state/complete.marker ]] && return 0
  local marker="$db/commit/$date.json"
  if [[ -f $marker ]] && grep -qF "\"run_id\": \"$runid\"" "$marker"; then
    return 0
  fi
  if [[ -f $output/publish/CURRENT ]]; then
    [[ $(cat "$output/publish/CURRENT" 2>/dev/null) == "$runid" ]] && return 0
  fi
  [[ -d $output/publish/$runid ]] && return 0
  return 1
}

case "$rc" in
  0|4)
    if [[ ! -f $output/state/complete.marker ]]; then
      echo "nightly returned $rc without a completion marker" >&2
      rc=12
    fi
    ;;
  97)
    echo "injected crash (rc=97); state preserved for recovery at $output" >&2
    ;;
  *)
    [[ $rc == 8 || $rc == 12 ]] || {
      echo "unexpected nightly rc=$rc; mapped to 12" >&2; rc=12; }
    if has_committed_or_published; then
      echo "nightly failed rc=$rc after commit/publish; preserving $output" \
        "for recovery" >&2
    else
      echo "nightly failed rc=$rc; removing unpublished run dir" >&2
      rm -rf -- "$output"
    fi
    ;;
esac
exit "$rc"
