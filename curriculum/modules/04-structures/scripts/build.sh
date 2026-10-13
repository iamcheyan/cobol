#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
# Include dirs: the exercise sources COPY the canonical, shipped enterprise
# copybook (module 07 lab).  In a student bundle there is no instructor/, so
# resolve the canonical copybook from its shipped curriculum location only.
inc_self="$repo/instructor/modules/04-structures"
inc_ent="$repo/instructor/modules/07/05-large-record"
[[ -d $inc_self ]] || inc_self="$here/.."
[[ -d $inc_ent ]] || inc_ent="$repo/curriculum/modules/07-matching/labs/05-large-record/copybooks"
target=${1:?usage: build.sh NEW-BINARY SOURCE}
source=${2:?usage: build.sh NEW-BINARY SOURCE}
[[ ! -e $target && ! -L $target && -d $(dirname -- "$target") ]] || exit 12
[[ -f $source ]] || exit 12
tmp=$(mktemp "$(dirname -- "$target")/.m04-build.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
cobc -Wall -I "$inc_self" -I "$inc_ent" \
     -x -o "$tmp" "$source" || exit 12
mv -n -- "$tmp" "$target"
[[ ! -e $tmp ]] || exit 12
trap - EXIT
