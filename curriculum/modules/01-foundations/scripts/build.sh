#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../.." && pwd)
target=${1:-"$PWD/bankentry"}
# The exercise is the learner's own starter; the instructor reference is only
# used when explicitly passed as the second argument (or COURSE_SOURCE).
source=${2:-"$here/starter/BANK-ENTRY.COB"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.bankentry.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
