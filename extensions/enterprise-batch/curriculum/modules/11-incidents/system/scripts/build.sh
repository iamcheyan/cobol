#!/usr/bin/env bash
# Build one snapshot COBOL program into a target path.
#   build.sh TARGET [SOURCE]
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
target=${1:-"$PWD/m11prog"}
source=${2:-"$here/cobol/M11VAL.COB"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp "$parent/.m11prog.XXXXXXXX") || { echo 'mktemp failed' >&2; exit 12; }
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -I "$here/copybooks" -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || { echo 'Build target collision' >&2; exit 12; }
trap - EXIT
echo "Built $target"
