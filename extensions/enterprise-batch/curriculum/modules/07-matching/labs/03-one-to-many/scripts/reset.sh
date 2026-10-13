#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# == 1 && -n $1 ]] || { echo 'Usage: reset.sh COURSE_OUTPUT_DIR' >&2; exit 12; }
target=$1
[[ ! -L $target && -d $target ]] || { echo 'Refusing non-directory or symlink' >&2; exit 12; }
resolved=$(realpath -- "$target")
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../../../.." && pwd)
[[ $resolved != "$repo" && $resolved != "$repo"/* ]] || {
  echo 'Refusing path inside repository' >&2; exit 12;
}
[[ -f $resolved/run.txt && -f $resolved/inputs.sha256 &&
   -f $resolved/outputs.sha256 && -f $resolved/report.txt ]] || {
  echo 'Refusing unmarked directory' >&2; exit 12;
}
rm -rf -- "$resolved"
echo "Removed course output $resolved"
