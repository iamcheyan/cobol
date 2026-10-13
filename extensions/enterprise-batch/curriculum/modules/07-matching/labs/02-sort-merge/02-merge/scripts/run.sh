#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $# == 3 ]] || { echo 'usage: run.sh feed-a.dat feed-b.dat output.dat' >&2; exit 12; }
a=$(realpath -e -- "$1") || { echo "Feed A resolution failed" >&2; exit 12; }
b=$(realpath -e -- "$2") || { echo "Feed B resolution failed" >&2; exit 12; }
output=$3
parent=$(dirname -- "$output")
[[ -f $a && -f $b && -d $parent && ! -e $output && ! -L $output ]] || {
  echo 'Input/parent invalid or output exists' >&2; exit 12; }
[[ ${COB_SORT_MEMORY:-2M} =~ ^[1-9][0-9]*[MmGg]$ ]] || {
  echo 'COB_SORT_MEMORY must be an explicit size >=1M' >&2; exit 12; }
lock="${output}.lock"
mkdir -- "$lock" 2>/dev/null || { echo 'Output lock exists' >&2; exit 12; }
work=
cleanup() { python3 - "${work:-}" "$lock" <<'PY'
import pathlib,sys,shutil
if sys.argv[1]: shutil.rmtree(sys.argv[1],ignore_errors=True)
pathlib.Path(sys.argv[2]).rmdir()
PY
}
trap cleanup EXIT
work=$(mktemp -d "$parent/.mergetx.XXXXXXXX") || { echo "Workspace creation failed" >&2; exit 12; }
snapshot_a="$work/feed-a.dat"
snapshot_b="$work/feed-b.dat"
cp -- "$a" "$snapshot_a" && cp -- "$b" "$snapshot_b" || {
  echo "Input snapshot failed" >&2; exit 12; }
set +e
python3 "$here/scripts/validate.py" "${B02_DATE:-20261009}" "$work/ids" strict "$snapshot_a" "$snapshot_b"
vr=$?
set -e
case "$vr" in 0) ;; 8|12) exit "$vr" ;; *) echo "Unexpected validator RC=$vr" >&2; exit 12 ;; esac
build_tmp=${B02_BUILD_TMPDIR:-${TMPDIR:-$work}}
[[ -d $build_tmp ]] || { echo "Build TMPDIR missing" >&2; exit 12; }
TMPDIR="$build_tmp" bash "$here/scripts/build.sh" "$work/mergetx"
export B02_INPUT_A="$snapshot_a" B02_INPUT_B="$snapshot_b" B02_OUTPUT="$work/candidate.dat"
export B02_DATE=${B02_DATE:-20261009}
export COB_SORT_MEMORY=${COB_SORT_MEMORY:-2M}
export TMPDIR=${B02_RUNTIME_TMPDIR:-${TMPDIR:-$work}}
set +e
if [[ -n ${B02_FILESIZE_LIMIT_BLOCKS:-} ]]; then
  (ulimit -f "$B02_FILESIZE_LIMIT_BLOCKS"; exec "$work/mergetx")
else
  "$work/mergetx"
fi
core_rc=$?
set -e
case "$core_rc" in 0|8|12) ;; *) echo "Unexpected core RC=$core_rc" >&2; exit 12 ;; esac
[[ $core_rc == 0 ]] || exit "$core_rc"
python3 "$here/scripts/verify.py" "$snapshot_a" "$snapshot_b" "$work/candidate.dat" || exit 12
python3 - "$work/candidate.dat" "$output" <<'PY'
import os,sys
try: os.link(sys.argv[1],sys.argv[2])
except OSError as e:
 print(f'No-clobber publish failed: {e}',file=sys.stderr); raise SystemExit(12)
PY
trap - EXIT
python3 - "$work" "$lock" <<'PY'
import pathlib,sys,shutil
shutil.rmtree(sys.argv[1],ignore_errors=True)
pathlib.Path(sys.argv[2]).rmdir()
PY
printf 'PASS: merged output published\n'
