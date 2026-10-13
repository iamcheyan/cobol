#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
# Prefer the instructor reference (authoring repo).  In a student bundle the
# reference is absent, so build the learner's own starter; the -I include dir
# only needs to exist (this program has no COPY).
module="$repo/instructor/modules/03-bytes"
[[ -d $module ]] || module="$here/.."
target=${1:?usage: build.sh NEW-BINARY [SOURCE]}
default_source="$module/M03BYTES.COB"
[[ -f $default_source ]] || default_source="$here/../starter/M03BYTES.COB"
source=${2:-"$default_source"}
[[ ! -e $target && ! -L $target && -d $(dirname -- "$target") ]] || exit 12
[[ -f $source ]] || exit 12
tmp=$(mktemp "$(dirname -- "$target")/.m03-build.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
cobc -Wall -I "$module" -x -o "$tmp" "$source" || exit 12
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || exit 12
trap - EXIT
