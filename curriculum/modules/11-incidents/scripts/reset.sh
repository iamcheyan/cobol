#!/usr/bin/env bash
# Module 11 reset helper: remove a marked module 11 run directory.
#   reset.sh COURSE_RUN_DIR
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$here/system/scripts/reset.sh" "$@"
