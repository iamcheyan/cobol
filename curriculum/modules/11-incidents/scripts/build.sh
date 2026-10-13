#!/usr/bin/env bash
# Module 11 COBOL build helper: build one snapshot program to TARGET.
#   build.sh TARGET [SOURCE]
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$here/system/scripts/build.sh" "$@"
