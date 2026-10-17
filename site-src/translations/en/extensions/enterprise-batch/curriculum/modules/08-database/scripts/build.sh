#!/usr/bin/env bash
# Compile an ESQL source file into an executable (gixpp + cobc inside the tool image).
# Usage: build.sh NEW_BINARY SOURCE.COB [COPYBOOK_DIR]
# Uses the GnuCOBOL default dialect (do not pass -std=cobol85); fixed-format checks are in check.py.
# Works from any starting directory, supports paths with spaces, and rejects an existing target (no-clobber); failures exit 12.
set -Eeuo pipefail
trap 'exit 12' ERR
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo 'Usage: build.sh NEW_BINARY SOURCE.COB [COPYBOOK_DIR]' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd -- "$here/.." && pwd)
target=$1
source=$(realpath -- "$2")
copydir=$(realpath -- "${3:-$lab/copybooks}")
bankdir=$(realpath -- "$lab/../../bank/copybooks")
[[ -f $source ]] || { echo "FAIL: source missing: $source" >&2; exit 12; }
[[ -d $copydir ]] || { echo "FAIL: copybook dir missing" >&2; exit 12; }
[[ -d $bankdir ]] || { echo "FAIL: canonical copybook dir missing" >&2; exit 12; }
[[ ! -e $target && ! -L $target ]] || { echo "FAIL: target exists: $target" >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent && -w $parent ]] || { echo "FAIL: target dir not writable" >&2; exit 12; }
export M08_TOOL_IMAGE=${M08_TOOL_IMAGE:-cobol-course-gixsql:m08}
tag=$M08_TOOL_IMAGE
bash "$here/docker-image.sh" >/dev/null
tmp=$(mktemp -d)
cleanup() { rm -rf -- "$tmp"; }
trap 'cleanup; exit 12' ERR
trap cleanup EXIT
cp -- "$source" "$tmp/PROG.COB"
docker run --rm -v "$tmp:/work" -v "$copydir:/copy:ro" -v "$bankdir:/bank:ro" -w /work "$tag" bash -euc '
  gixpp -e -S -I /usr/local/share/gixsql/copy -i PROG.COB -o PROG.pp.cob
  cobc -Wall -x -I /usr/local/share/gixsql/copy -I /copy -I /bank \
    -L /usr/local/lib -lgixsql -o PROG PROG.pp.cob
'
mv -n -- "$tmp/PROG" "$target"
[[ ! -e $tmp/PROG ]] || { echo 'FAIL: move failed' >&2; exit 12; }
trap cleanup EXIT
