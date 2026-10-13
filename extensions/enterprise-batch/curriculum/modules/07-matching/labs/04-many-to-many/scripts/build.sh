#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../../" && pwd)
target=${1:?usage: build.sh NEW_BINARY [SOURCE]}
source=${2:-"$repo/instructor/modules/07/04-many-to-many/BATCHL3.COB"}
[[ ! -e $target && ! -L $target ]] || exit 12
parent=$(dirname -- "$target")
[[ -d $parent ]] || exit 12
tmp=$(mktemp "$parent/.b03-build.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
if ! cobc -Wall -free -I "$repo/curriculum/bank/copybooks" \
  -I "$here/../copybooks" -x -o "$tmp" "$source"; then
  exit 12
fi
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || exit 12
trap - EXIT
