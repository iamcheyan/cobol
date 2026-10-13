#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../.." && pwd)
target=${1:-"$PWD/custload"}
# The exercise is the learner's own starter; the instructor reference is only
# used when it is present (authoring repo) or passed explicitly (2nd arg).
default_source="$repo/instructor/modules/02-data/CUSTLOAD.COB"
[[ -f $default_source ]] || default_source="$here/starter/CUSTLOAD.COB"
source=${2:-"$default_source"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.custload.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$here/copybooks" -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
