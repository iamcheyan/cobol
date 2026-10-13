#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../../" && pwd)
target=${1:?usage: build.sh NEW_BINARY [SOURCE]}
source=${2:-"$repo/instructor/modules/07/05-large-record/BATCHL4.COB"}
[[ ! -e $target && ! -L $target && -d $(dirname -- "$target") ]] || exit 12
tmp=$(mktemp "$(dirname -- "$target")/.b04-build.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
cobc -Wall -I "$repo/instructor/modules/07/05-large-record" -x -o "$tmp" "$source" || exit 12
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || exit 12
trap - EXIT
