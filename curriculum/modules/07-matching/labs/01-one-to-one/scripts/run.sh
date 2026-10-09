#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 4 ]]; then
  echo 'Usage: run.sh ACCOUNT TRANSACTION NEW_OUTPUT_DIRECTORY YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../.." && pwd)
[[ $4 =~ ^[0-9]{8}$ ]] || { echo 'Invalid business date' >&2; exit 8; }
[[ -r $1 && -f $1 && -r $2 && -f $2 ]] || { echo 'Input missing/unreadable' >&2; exit 12; }
account=$(realpath -- "$1")
transaction=$(realpath -- "$2")
[[ ! -e $3 && ! -L $3 ]] || { echo 'Output already exists' >&2; exit 12; }
output=$(realpath -m -- "$3")
[[ ! -e $output && ! -L $output ]] || { echo 'Output already exists; use a new run directory' >&2; exit 12; }
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
stage=$(mktemp -d "$parent/.bank-l1.XXXXXXXX")
cp -- "$account" "$stage/account.input.dat"
cp -- "$transaction" "$stage/transaction.input.dat"
account="$stage/account.input.dat"
transaction="$stage/transaction.input.dat"
# Each run builds in isolation. COURSE_SOURCE supports the learner's solution.
source=${COURSE_SOURCE:-"$repo/instructor/modules/07/01-one-to-one/MATCH.COB"}
cobc -Wall -I "$repo/curriculum/bank/copybooks" -x -o "$stage/match" "$source" || exit 12
# SORT checks the global transaction-id constraint; COBOL does account matching.
cut -b 11-26 -- "$transaction" | sort -T "$stage" | uniq -d > "$stage/duplicate-ids"
[[ ! -s $stage/duplicate-ids ]] || { echo 'Duplicate transaction id' >&2; exit 8; }
export ACCOUNT_FILE="$account" TRANSACTION_FILE="$transaction" BUSINESS_DATE="$4"
if "$stage/match" > "$stage/report.txt"; then rc=0; else rc=$?; fi
case "$rc" in
  0) ;;
  8|12) exit "$rc" ;;
  *) echo "Unexpected matcher RC=$rc; mapped to 12" >&2; exit 12 ;;
esac
(cd "$stage" && sha256sum account.input.dat transaction.input.dat > inputs.sha256)
printf 'business_date=%s\n' "$4" > "$stage/run.txt"
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" "$repo"/curriculum/bank/copybooks/*.CPY > "$stage/source.sha256"
rm -- "$stage/match" "$stage/duplicate-ids"
# Do not replace an output created outside the cooperative lock protocol.
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
