#!/usr/bin/env bash
# Module 09 check entry point.  Two modes:
#   repository mode (instructor/ present) : full regression, including the
#       pristine-starter RED invariant and instructor-fault injections.
#   student bundle mode (no instructor/)  : learner self-check against the
#       shipped shared subprograms and the learner's own BATCH09; skips the
#       authoring-only assertions.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
if [[ -f "$repo/instructor/modules/09-modular/BATCH09.COB" ]]; then
  echo '== module 09 check: repository mode (instructor reference present) =='
else
  echo '== module 09 check: student bundle mode (no instructor; learner source) =='
fi
python3 "$here/check.py"
