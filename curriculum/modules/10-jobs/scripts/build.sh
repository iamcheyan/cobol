#!/usr/bin/env bash
# Build the JOB002 validator (or an alternate COURSE_SOURCE starter).
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../.." && pwd)
target=${1:-"$PWD/bankval"}
# The exercise is the learner's own starter; the instructor reference is only
# used when present (authoring repo) or passed explicitly (2nd arg).
default_source="$repo/instructor/modules/10-jobs/BANKVAL.COB"
[[ -f $default_source ]] || default_source="$here/starter/BANKVAL.COB"
source=${2:-"$default_source"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.bankval.XXXXXXXX") || { echo 'mktemp failed' >&2; exit 12; }
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$here/copybooks" -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
