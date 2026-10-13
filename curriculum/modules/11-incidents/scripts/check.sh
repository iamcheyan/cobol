#!/usr/bin/env bash
# Module 11 acceptance entry point.  Two modes:
#   repository mode (instructor/ present) : full regression, including the
#       RED->GREEN incident fixes and the instructor maintenance sources.
#   student bundle mode (no instructor/)  : learner self-check against the
#       shipped system COBOL; skips the instructor-only RED->GREEN fixes.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
if [[ -d "$repo/instructor/modules/11-incidents" ]]; then
  echo '== module 11 check: repository mode (instructor reference present) =='
else
  echo '== module 11 check: student bundle mode (no instructor; shipped system) =='
fi
python3 "$here/check.py"
