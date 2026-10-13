#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 3 ]]; then
  echo 'Usage: run.sh INPUT NEW_OUTPUT YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
[[ $3 =~ ^[0-9]{8}$ ]] || { echo 'Invalid business date' >&2; exit 8; }
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
stage=$(mktemp -d "$parent/.bank-m01.XXXXXXXX")
cp -- "$input" "$stage/account.input.dat"
input="$stage/account.input.dat"
# Default to the instructor reference when it is present (authoring repo), and
# to the learner's own starter in a student bundle where instructor/ is not
# shipped.  An explicit COURSE_SOURCE always wins.
default_source="$repo/instructor/modules/01-foundations/BANK-ENTRY.COB"
[[ -f $default_source ]] || default_source="$here/../starter/BANK-ENTRY.COB"
source=${COURSE_SOURCE:-"$default_source"}
cobc -Wall -x -o "$stage/bankentry" "$source" || exit 12
export INPUT_FILE="$input"
export PASS_OUTPUT_FILE="$stage/accepted.dat"
export REJECT_OUTPUT_FILE="$stage/rejected.dat"
export BUSINESS_DATE="$3"
if "$stage/bankentry" > "$stage/control.txt"; then rc=0; else rc=$?; fi
case "$rc" in
  0|4) ;;
  8|12)
    cat -- "$stage/control.txt" >&2
    exit "$rc"
    ;;
  *)
    echo "Unexpected entry RC=$rc; mapped to 12" >&2
    exit 12
    ;;
esac
python3 "$here/verify-publish.py" "$input" "$3" "$stage/control.txt" \
  "$stage/accepted.dat" "$stage/rejected.dat" || exit 12
(cd "$stage" && sha256sum account.input.dat > inputs.sha256)
(cd "$stage" && sha256sum accepted.dat rejected.dat > outputs.sha256)
printf 'business_date=%s\n' "$3" > "$stage/run.txt"
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" > "$stage/source.sha256"
rm -- "$stage/bankentry"
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
echo 'PASS: account entry counts verified'
exit "$rc"
