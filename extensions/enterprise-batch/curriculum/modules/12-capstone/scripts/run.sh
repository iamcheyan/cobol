#!/usr/bin/env bash
# Module 12 capstone night entry point.
#
#   run.sh --input DIR --output DIR --db DIR --business-date YYYYMMDD
#          --layout v1|v2 [--run-id ID] [--config FILE]
#          [--command run|status] [--crash-at POINT]
#
# Parameter precedence: CLI > --config file > allowlisted NIGHT_* env >
# built-in default.  Works from any cwd, tolerates spaces in paths, never
# overwrites an existing result, holds an output lock and a business-date
# lock, and publishes nothing unless every job that may fail has succeeded.
#
# Crash points (labs): before-db-commit | mid-db-commit | after-db-commit
#                     | during-publish | after-publish
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$module/../../.." && pwd)
system="$module/system"

usage() {
  cat >&2 <<'EOF'
usage: run.sh --input DIR --output DIR --db DIR --business-date YYYYMMDD
              --layout v1|v2 [--run-id ID] [--config FILE]
              [--command run|status] [--crash-at POINT]
EOF
  exit 12
}

in_cli=''; out_cli=''; db_cli=''; date_cli=''; run_cli=''; layout_cli=''
config=''; command=run; crash=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input) [[ $# -ge 2 ]] || usage; in_cli=$2; shift 2 ;;
    --output) [[ $# -ge 2 ]] || usage; out_cli=$2; shift 2 ;;
    --db) [[ $# -ge 2 ]] || usage; db_cli=$2; shift 2 ;;
    --business-date) [[ $# -ge 2 ]] || usage; date_cli=$2; shift 2 ;;
    --layout) [[ $# -ge 2 ]] || usage; layout_cli=$2; shift 2 ;;
    --run-id) [[ $# -ge 2 ]] || usage; run_cli=$2; shift 2 ;;
    --config) [[ $# -ge 2 ]] || usage; config=$2; shift 2 ;;
    --command) [[ $# -ge 2 ]] || usage; command=$2; shift 2 ;;
    --crash-at) [[ $# -ge 2 ]] || usage; crash=$2; shift 2 ;;
    -h|--help) usage ;;
    *) echo "run.sh: unknown argument '$1'" >&2; usage ;;
  esac
done

cfg_input=''; cfg_output=''; cfg_db=''; cfg_date=''; cfg_run=''; cfg_layout=''
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
      layout) cfg_layout=$value ;;
      run_id) cfg_run=$value ;;
    esac
  done <"$config"
fi

input=${in_cli:-${cfg_input:-${NIGHT_INPUT:-}}}
output=${out_cli:-${cfg_output:-${NIGHT_OUTPUT:-}}}
db=${db_cli:-${cfg_db:-${NIGHT_DB:-}}}
date=${date_cli:-${cfg_date:-${NIGHT_BUSINESS_DATE:-}}}
layout=${layout_cli:-${cfg_layout:-${NIGHT_LAYOUT:-}}}
runid=${run_cli:-${cfg_run:-${NIGHT_RUN_ID:-}}}
crash=${crash:-${NIGHT_CRASH_AT:-}}

[[ -n $output && -n $db && -n $date && -n $layout ]] || usage
[[ -d $input && -r $input ]] || { echo "input dir invalid" >&2; exit 12; }
case "$layout" in v1|v2) ;; *) echo "layout must be v1 or v2" >&2; exit 8 ;; esac
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
[[ -f $system/nightly.sh ]] || { echo "capstone system missing" >&2; exit 12; }

if [[ $command == status ]]; then
  [[ -f $output/run.env ]] || { echo "no run at $output" >&2; exit 12; }
  echo "output=$output"
  for m in "$output"/state/JOB*.done; do
    [[ -e $m ]] || continue
    echo "  $(basename "$m") $(sed -n 's/^rc=//p' "$m")"
  done
  [[ -f $output/state/complete.marker ]] && echo "complete=yes" || echo "complete=no"
  [[ -f $output/publish/CURRENT ]] && echo "current=$(cat "$output/publish/CURRENT")"
  python3 "$system/lib/capdb.py" status --db "$db" --business-date "$date" 2>/dev/null || true
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
layout=$layout
run_id=$runid
system=$system
db_layer=offline-file-checkpoint
real_db_verified=false
created=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
EOF
  echo "=== module 12 capstone run $runid for $date ($layout) ===" \
    >>"$output/logs/nightly.log"
else
  echo "=== resume of $runid for $date ===" >>"$output/logs/nightly.log"
fi

if [[ ! -f $db/account.table ]]; then
  if [[ ! -f $input/account_seed.dat || ! -f $input/customer_seed.dat ]]; then
    echo "DB store empty and no seed files in input" >&2
    exit 12
  fi
  python3 "$system/lib/capdb.py" seed --db "$db" \
    --account "$input/account_seed.dat" \
    --customer "$input/customer_seed.dat" \
    --business-date "$date" --run-id "$runid" --layout "$layout" || {
    echo "DB seed failed" >&2; exit 12; }
fi

export NIGHT_INPUT=$input NIGHT_OUTPUT=$output NIGHT_DB=$db \
  NIGHT_DATE=$date NIGHT_RUN_ID=$runid NIGHT_LOG_DIR="$output/logs" \
  NIGHT_LAYOUT=$layout NIGHT_REPO=$repo NIGHT_CRASH_AT=$crash

set +e
bash "$system/nightly.sh"
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
  97) echo "injected crash (rc=97); state preserved for recovery at $output" >&2 ;;
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
