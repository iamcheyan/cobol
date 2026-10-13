#!/usr/bin/env bash
# Module 11 entry point: run the incident-snapshot nightly.  All real
# work happens in system/scripts/run.sh; this wrapper only resolves the
# path so the command works from any cwd.  Pass --keep-scene to preserve
# a failed work directory for forensics.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$here/system/scripts/run.sh" "$@"
