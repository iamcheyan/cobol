#!/usr/bin/env bash
# Author tool: capture the real as-found scene for every incident into
# curriculum/modules/11-incidents/INC-2026-00X/student/scene/.
#
#   capture-scenes.sh [WORKDIR]
#
# It runs the frozen snapshot exactly as a scheduler would (preserving a
# failed work dir), copies the raw JOB logs / run.env / input MANIFEST,
# stores the untouched bad input under student/input/ and copies the
# source and copybooks under investigation.  It never edits the shared
# fixtures.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd -- "$here/../../../.." && pwd)
module="$repo/curriculum/modules/11-incidents"
work=${1:-"$PWD/m11-scenes"}
rm -rf -- "$work"
mkdir -p -- "$work"

copy_common() { # incident out
  local inc=$1 out=$2
  local student="$module/$inc/student"
  local fixture="$module/fixtures/$inc"
  mkdir -p -- "$student/scene/logs" "$student/scene/source" \
    "$student/scene/copybooks" "$student/input"
  cp -- "$out/run.env" "$student/scene/run.env"
  cp -- "$fixture/MANIFEST" "$student/scene/MANIFEST"
  cp -- "$fixture/MANIFEST" "$student/input/MANIFEST"
  cp -- "$fixture/transaction.dat" "$student/input/transaction.dat"
  cp -- "$fixture/account_seed.dat" "$student/input/account_seed.dat"
  cp -- "$fixture/customer_seed.dat" "$student/input/customer_seed.dat"
  cp -- "$out/logs/"*.log "$student/scene/logs/" 2>/dev/null || true
  cp -- "$module/system/cobol/M11VAL.COB" "$student/scene/source/"
  cp -- "$module/system/cobol/M11MATCH.COB" "$student/scene/source/"
  cp -- "$module/system/lib/db.py" "$student/scene/source/"
  cp -- "$module/system/lib/control.py" "$student/scene/source/"
  cp -- "$module/system/jobs/job002-validate.sh" "$student/scene/source/"
  cp -- "$module/system/jobs/job005-match.sh" "$student/scene/source/"
  cp -- "$module/system/copybooks/"*.CPY "$student/scene/copybooks/"
}

run_scene() { # incident keep fixture
  local inc=$1 keep=$2
  local out="$work/$inc-out" db="$work/$inc-db"
  local args=(--input "$module/fixtures/$inc" --output "$out" --db "$db"
              --business-date 20261009 --run-id "as-found")
  [[ $keep == keep ]] && args+=(--keep-scene)
  set +e
  bash "$module/system/scripts/run.sh" "${args[@]}" >"$work/$inc.out" 2>&1
  echo "$?" >"$work/$inc.rc"
  set -e
  copy_common "$inc" "$out"
  cp -- "$work/$inc.out" "$module/$inc/student/scene/console.txt"
  printf 'rc=%s\n' "$(cat "$work/$inc.rc")" > "$module/$inc/student/scene/rc.txt"
}

run_scene INC-2026-001 keep
run_scene INC-2026-002 keep
run_scene INC-2026-003 keep
run_scene INC-2026-004 keep
run_scene INC-2026-006 keep
run_scene INC-2026-007 keep

# INC-2026-005 needs the environment injection (failing mktemp on PATH).
inc=INC-2026-005
shim="$work/shim"
mkdir -p -- "$shim"
printf '#!/bin/sh\nexit 1\n' >"$shim/mktemp"
chmod +x "$shim/mktemp"
out="$work/$inc-out"; db="$work/$inc-db"
set +e
PATH="$shim:$PATH" bash "$module/system/scripts/run.sh" \
  --input "$module/fixtures/$inc" --output "$out" --db "$db" \
  --business-date 20261009 --run-id as-found --keep-scene \
  >"$work/$inc.out" 2>&1
echo "$?" >"$work/$inc.rc"
set -e
copy_common "$inc" "$out"
cp -- "$work/$inc.out" "$module/$inc/student/scene/console.txt"
printf 'rc=%s\n' "$(cat "$work/$inc.rc")" > "$module/$inc/student/scene/rc.txt"

# INC-2026-002 also carries the offline ledger seen in the incident.
cp -- "$work/INC-2026-002-db/ledger.dat" \
  "$module/INC-2026-002/student/scene/ledger-victim.dat" 2>/dev/null || true

for inc in INC-2026-001 INC-2026-002 INC-2026-003 \
           INC-2026-004 INC-2026-005 INC-2026-006 INC-2026-007; do
  printf '%s rc=%s\n' "$inc" "$(cat "$work/$inc.rc")"
done
echo "PASS: scenes captured"
