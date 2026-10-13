#!/usr/bin/env bash
# Reproduce this incident exactly as the scheduler ran it.  The failure
# is an environment condition (a broken temporary-space tool) injected
# only on this run's PATH; the batch input itself is the normal feed.
# The work directory is preserved (--keep-scene).
#
#   run.sh [OUTPUT_DIR] [DB_DIR]
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/../.." && pwd)
out=${1:-$PWD/INC-2026-005-scene}
db=${2:-$PWD/INC-2026-005-db}
shim=$(mktemp -d)
trap 'rm -rf -- "$shim"' EXIT
printf '#!/bin/sh\necho "mktemp: cannot create temporary directory" >&2\nexit 1\n' >"$shim/mktemp"
chmod +x "$shim/mktemp"
set +e
PATH="$shim:$PATH" bash "$module/system/scripts/run.sh" \
  --input "$here/input" --output "$out" --db "$db" \
  --business-date 20261009 --run-id as-found --keep-scene
rc=$?
set -e
echo "reproduced rc=$rc  (logs under $out/logs)"
exit "$rc"
