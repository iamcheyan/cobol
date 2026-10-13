#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 3 ]]; then
  echo 'Usage: run.sh ACCOUNT_INPUT NEW_OUTPUT_DIR YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
[[ $3 =~ ^[0-9]{8}$ ]] || { echo 'Invalid business date' >&2; exit 8; }
input=$1
[[ -f $input && -r $input ]] || { echo 'Input missing/unreadable' >&2; exit 12; }
input=$(realpath -- "$input")
[[ ! -e $2 && ! -L $2 ]] || { echo 'Output already exists' >&2; exit 12; }
output=$(realpath -m -- "$2")
[[ ! -e $output && ! -L $output ]] || { echo 'Output already exists' >&2; exit 12; }
parent=$(dirname -- "$output")
[[ -d $parent ]] || { echo 'Output parent missing' >&2; exit 12; }
lock="$output.lock"
mkdir -- "$lock" 2>/dev/null || { echo 'Run locked' >&2; exit 12; }
stage=''
cleanup() {
  [[ -z $stage ]] || rm -rf -- "$stage"
  rmdir -- "$lock"
}
trap cleanup EXIT
[[ ! -e $output && ! -L $output ]] || exit 12
stage=$(mktemp -d "$parent/.bank-fileval.XXXXXXXX")
cp -- "$input" "$stage/account.input.dat"
# Default to the instructor reference when present (authoring repo); in a
# student bundle without instructor/ fall back to the learner's own starter.
default_source="$repo/instructor/modules/06-files/FILEVAL.COB"
[[ -f $default_source ]] || default_source="$here/../starter/FILEVAL.COB"
source=${COURSE_SOURCE:-"$default_source"}
cobc -Wall -I "$repo/curriculum/bank/copybooks" -x \
  -o "$stage/fileval" "$source" || exit 12
export ACCOUNT_FILE="$stage/account.input.dat"
export ACCEPT_OUTPUT_FILE="$stage/accepted.dat"
export REJECT_OUTPUT_FILE="$stage/rejected.dat"
export STATUS_LOG_FILE="$stage/filestatus.log"
export BUSINESS_DATE="$3"
if "$stage/fileval" > "$stage/report.txt" 2> "$stage/stderr.txt"; then
  rc=0
else
  rc=$?
fi
case "$rc" in
  0|4) ;;
  8|12) grep -v 'libcob: warning: implicit CLOSE' "$stage/stderr.txt" >&2 || true
        exit "$rc" ;;
  *) echo "Unexpected fileval RC=$rc; mapped to 12" >&2; exit 12 ;;
esac
python3 "$here/verify-publish.py" "$stage/account.input.dat" \
  "$stage/report.txt" "$stage/accepted.dat" "$stage/rejected.dat" || exit 12
(cd "$stage" && sha256sum account.input.dat > inputs.sha256)
(cd "$stage" && sha256sum accepted.dat rejected.dat report.txt \
  filestatus.log > outputs.sha256)
printf 'business_date=%s\n' "$3" > "$stage/run.txt"
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" > "$stage/source.sha256"
rm -- "$stage/fileval" "$stage/stderr.txt"
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
echo 'PASS: file contract and control totals verified'
exit "$rc"
