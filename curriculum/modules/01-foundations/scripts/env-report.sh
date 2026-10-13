#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/bank-entry-env.XXXXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
echo "== platform =="
uname -srm
echo "== compiler =="
cobc -V | head -n 3
echo "== build =="
bash "$here/build.sh" "$tmp/bankentry"
echo "== artifact type =="
file "$tmp/bankentry"
echo "== dynamic dependencies =="
ldd "$tmp/bankentry" | sed 's/^/  /'
echo "== ELF header =="
readelf -h "$tmp/bankentry" | sed -n '1,12p'
echo "== source to executable mapping =="
default_source="$repo/instructor/modules/01-foundations/BANK-ENTRY.COB"
[[ -f $default_source ]] || default_source="$here/../starter/BANK-ENTRY.COB"
echo "  source : ${COURSE_SOURCE:-$default_source}"
echo "  driver : cobc -x -o bankentry BANK-ENTRY.COB"
echo "  result : a native ELF executable; GnuCOBOL generates C and the"
echo "           system C compiler links it with libcob at runtime."
