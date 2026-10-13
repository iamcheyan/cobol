#!/usr/bin/env bash
# Module 04 check entry point.  Two modes:
#   repository mode (instructor/ present) : full regression, including the
#       pristine-starter RED invariant and instructor-fault injections.
#   student bundle mode (no instructor/)  : learner self-check that measures
#       the shipped learner source against the frozen catalog and skips the
#       authoring-only assertions.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
if [[ -d "$repo/instructor/modules/04-structures" ]]; then
  echo '== module 04 check: repository mode (instructor reference present) =='
else
  echo '== module 04 check: student bundle mode (no instructor; learner source) =='
fi
python3 "$here/check.py"
( cd "$here/../fixtures" && sha256sum -c SHA256SUMS )
