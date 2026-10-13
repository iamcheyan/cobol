#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 2 ]]; then
  echo 'Usage: run.sh INPUT NEW_OUTPUT' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
copybooks=$(cd -- "$here/../copybooks" && pwd)
[[ -f $1 && -r $1 ]] || { echo 'Input missing/unreadable' >&2; exit 12; }
input=$(realpath -- "$1")
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
stage=$(mktemp -d "$parent/.bank-m02.XXXXXXXX")
cp -- "$input" "$stage/customer.input.dat"
input="$stage/customer.input.dat"
# Default to the instructor reference when present (authoring repo); in a
# student bundle without instructor/ fall back to the learner's own starter.
default_source="$repo/instructor/modules/02-data/CUSTLOAD.COB"
[[ -f $default_source ]] || default_source="$here/../starter/CUSTLOAD.COB"
source=${COURSE_SOURCE:-"$default_source"}
cobc -Wall -I "$copybooks" -x -o "$stage/custload" "$source" || exit 12
export INPUT_FILE="$input"
export PASS_OUTPUT_FILE="$stage/accepted.dat"
export REJECT_OUTPUT_FILE="$stage/rejected.dat"
if "$stage/custload" > "$stage/control.txt"; then rc=0; else rc=$?; fi
case "$rc" in
  0|4) ;;
  8|12)
    cat -- "$stage/control.txt" >&2
    exit "$rc"
    ;;
  *)
    echo "Unexpected loader RC=$rc; mapped to 12" >&2
    exit 12
    ;;
esac
python3 "$here/verify-publish.py" "$input" "$stage/control.txt" \
  "$stage/accepted.dat" "$stage/rejected.dat" || exit 12
(cd "$stage" && sha256sum customer.input.dat > inputs.sha256)
(cd "$stage" && sha256sum accepted.dat rejected.dat > outputs.sha256)
printf 'job=custload\n' > "$stage/run.txt"
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" > "$stage/source.sha256"
rm -- "$stage/custload"
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
echo 'PASS: customer counts and balance verified'
exit "$rc"
