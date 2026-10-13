#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../../../.." && pwd)
target=${1:-"$PWD/batchl2"}
# Prefer the instructor reference (authoring repo); in a student bundle build
# the learner's own starter, which later modules 10/12 reuse once completed.
default_source="$repo/instructor/modules/07/03-one-to-many/BATCHL2.COB"
[[ -f $default_source ]] || default_source="$here/starter/BATCHL2.COB"
source=${2:-"$default_source"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.batchl2.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$repo/curriculum/bank/copybooks" -x \
  -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
