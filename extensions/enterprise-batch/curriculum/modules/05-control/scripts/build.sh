#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../.." && pwd)
target=${1:-"$PWD/cleanse"}
# The exercise is the learner's own starter; the instructor reference is used
# only when passed explicitly (second argument or COURSE_SOURCE).
source=${2:-"$here/starter/CLEANSE.COB"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.cleanse.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$here/copybooks" -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
