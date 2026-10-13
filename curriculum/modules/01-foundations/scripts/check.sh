#!/usr/bin/env bash
# Module 01 check entry point.  Two modes:
#   repository mode (instructor/ present) : module contracts plus the
#       student-bundle packaging regression (the packager needs the reference
#       answer to cross-check against, so it only runs here).
#   student bundle mode (no instructor/)  : learner self-check only; the
#       packaging regression is repo-only.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
python3 "$here/check.py"
if [[ -f "$repo/instructor/modules/01-foundations/BANK-ENTRY.COB" ]]; then
  echo '== module 01 check: repository mode; running student-bundle regression =='
  python3 "$here/check-student-package.py"
else
  echo '== module 01 check: student bundle mode (packaging regression skipped) =='
fi
