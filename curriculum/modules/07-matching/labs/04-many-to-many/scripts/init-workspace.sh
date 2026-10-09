#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $# != 1 ]]; then
  echo 'Usage: init-workspace.sh EMPTY_DIRECTORY' >&2
  exit 12
fi
directory=$(realpath -m -- "$1")
[[ ! -e $directory || -d $directory ]] || exit 12
mkdir -p -- "$directory"
[[ -z $(find "$directory" -mindepth 1 -maxdepth 1 -print -quit) ]] || exit 12
[[ ! -e "$directory/.b03-workspace" ]] || exit 12
printf 'B03-STUDENT-WORKSPACE-V1\n' > "$directory/.b03-workspace"
