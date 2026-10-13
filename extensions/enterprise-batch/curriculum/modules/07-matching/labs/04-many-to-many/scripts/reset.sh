#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $# != 1 ]]; then
  echo 'Usage: reset.sh MARKED_WORKSPACE' >&2
  exit 12
fi
directory=$(realpath -- "$1")
[[ -d $directory && -f "$directory/.b03-workspace" ]] || exit 12
[[ $(cat "$directory/.b03-workspace") == B03-STUDENT-WORKSPACE-V1 ]] || exit 12
if find "$directory" -type d -name '*.lock' -print -quit | rg -q .; then
  echo 'Workspace lock exists; reset refused' >&2
  exit 12
fi
rm -f -- "$directory/batchl3" "$directory/core.stdout" \
  "$directory/result.log" "$directory/manifest.sha256"
rm -rf -- "$directory/build" "$directory/output"
