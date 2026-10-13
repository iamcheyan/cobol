#!/usr/bin/env bash
# Remove a module 11 snapshot run output directory, but only a marked
# course run.  Refuses repository paths, symlinks and unmarked dirs.
set -Eeuo pipefail
export LC_ALL=C
[[ $# == 1 && -n $1 ]] || { echo 'Usage: reset.sh COURSE_RUN_DIR' >&2; exit 12; }
target=$1
[[ ! -L $target && -d $target ]] || {
  echo 'Refusing non-directory or symlink' >&2; exit 12; }
resolved=$(realpath -- "$target")
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../../.." && pwd)
[[ $resolved != "$repo" && $resolved != "$repo"/* ]] || {
  echo 'Refusing path inside repository' >&2; exit 12; }
[[ -f $resolved/run.env ]] || {
  echo 'Refusing unmarked directory (no run.env)' >&2; exit 12; }
rm -rf -- "$resolved"
echo "Removed course run $resolved"
