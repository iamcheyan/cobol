#!/usr/bin/env bash
# Reproduce this incident exactly as the scheduler ran it.  The failed
# work directory is preserved (--keep-scene) so the JOB logs, state and
# intermediate files can be read.  The input is THIS package's own
# student/input copy; the shared fixtures are never touched.
#
#   run.sh [OUTPUT_DIR] [DB_DIR]
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/../.." && pwd)
out=${1:-$PWD/INC-2026-007-scene}
db=${2:-$PWD/INC-2026-007-db}
set +e
bash "$module/system/scripts/run.sh" \
  --input "$here/input" --output "$out" --db "$db" \
  --business-date 20261009 --run-id as-found --keep-scene
rc=$?
set -e
echo "reproduced rc=$rc  (logs under $out/logs)"
exit "$rc"
