#!/usr/bin/env bash
# Module 12 capstone acceptance entry point.  Two modes:
#   repository mode (instructor/ present) : full regression plus the real-DB
#       route (UNVERIFIED/RC2 when the environment is missing).
#   student bundle mode (no instructor/)  : learner self-check against the
#       shipped system and the learner's own CUSTV2/BANKVAL; the real-DB route
#       needs instructor-only ESQL programs, so it is reported UNVERIFIED.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
if [[ -d "$repo/instructor/modules/12-capstone" ]]; then
  echo '== module 12 check: repository mode (instructor reference present) =='
  repo_mode=1
else
  echo '== module 12 check: student bundle mode (no instructor; learner source) =='
  repo_mode=0
fi
python3 "$here/check.py" || exit $?
if [[ $repo_mode == 0 ]]; then
  echo 'UNVERIFIED: real-DB route needs the instructor ESQL programs; not run' >&2
  exit 0
fi
# Real-DB regression (R01/R02).  When the environment is missing it reports
# UNVERIFIED (RC2) and never claims a real end-to-end pass.
set +e
bash "$here/check-real-db.sh"
rc=$?
set -e
case "$rc" in
  0) ;;
  2) echo "WARNING: module 12 real DB NOT verified in this environment" >&2 ;;
  *) exit "$rc" ;;
esac
