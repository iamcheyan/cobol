#!/usr/bin/env bash
# Compile the exercise. Does not publish; use run.sh for a real JOB.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../.." && pwd)
# The three shared subprograms are *provided* modules (not the exercise
# answer).  Prefer the instructor reference tree in the authoring repo, else
# use the copy shipped inside the learner bundle (curriculum/.../lib).
libdir="$repo/instructor/modules/09-modular"
[[ -f $libdir/AMTCALC.COB ]] || libdir="$here/lib"
target=${1:-"$PWD/batch09"}
default_source="$repo/instructor/modules/09-modular/BATCH09.COB"
[[ -f $default_source ]] || default_source="$here/starter/BATCH09.COB"
source=${2:-"$default_source"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.batch09.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$here/copybooks" -I "$repo/curriculum/bank/copybooks" \
  -x -o "$tmp" "$source" \
  "$libdir/AMTCALC.COB" \
  "$libdir/CUSTVAL.COB" \
  "$libdir/LOGGER.COB"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
