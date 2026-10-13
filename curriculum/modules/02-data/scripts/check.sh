#!/usr/bin/env bash
# Module 02 check entry point.  Two modes:
#   repository mode (instructor/ present) : full regression, including the
#       pristine-starter RED invariant and instructor-fault injections.
#   student bundle mode (no instructor/)  : learner self-check that runs the
#       same contracts against the shipped learner source and skips the
#       authoring-only assertions.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
if [[ -f "$repo/instructor/modules/02-data/CUSTLOAD.COB" ]]; then
  echo '== module 02 check: repository mode (instructor reference present) =='
else
  echo '== module 02 check: student bundle mode (no instructor; learner source) =='
fi
python3 "$here/check.py"
