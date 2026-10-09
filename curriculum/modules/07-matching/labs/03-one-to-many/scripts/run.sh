#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 5 ]]; then
  echo 'Usage: run.sh ACCOUNT TRANSACTION REVERSAL_LINK NEW_OUTPUT YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../.." && pwd)
[[ $5 =~ ^[0-9]{8}$ ]] || { echo 'Invalid business date' >&2; exit 8; }
for input in "$1" "$2" "$3"; do
  [[ -f $input && -r $input ]] || { echo 'Input missing/unreadable' >&2; exit 12; }
done
account=$(realpath -- "$1")
transaction=$(realpath -- "$2")
reversal=$(realpath -- "$3")
[[ ! -e $4 && ! -L $4 ]] || { echo 'Output already exists' >&2; exit 12; }
output=$(realpath -m -- "$4")
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
stage=$(mktemp -d "$parent/.bank-l2.XXXXXXXX")
cp -- "$account" "$stage/account.input.dat"
cp -- "$transaction" "$stage/transaction.input.dat"
cp -- "$reversal" "$stage/reversal-link.input.dat"
account="$stage/account.input.dat"
transaction="$stage/transaction.input.dat"
reversal="$stage/reversal-link.input.dat"
source=${COURSE_SOURCE:-"$repo/instructor/modules/07/03-one-to-many/BATCHL2.COB"}
cobc -Wall -I "$repo/curriculum/bank/copybooks" -x \
  -o "$stage/batchl2" "$source" || exit 12
# External sort catches duplicate IDs across distant rows and accounts.
cut -b 11-26 -- "$transaction" | sort -T "$stage" | uniq -d > "$stage/duplicate-ids"
[[ ! -s $stage/duplicate-ids ]] || { echo 'Duplicate transaction id' >&2; exit 8; }
export ACCOUNT_FILE="$account" TRANSACTION_FILE="$transaction"
export REVERSAL_FILE="$reversal" BUSINESS_DATE="$5"
export LEDGER_FILE="$stage/ledger.index" LINKS_FILE="$stage/links.index"
export MASTER_OUTPUT_FILE="$stage/master.dat"
export ACCEPT_OUTPUT_FILE="$stage/accepted.dat"
export REJECT_OUTPUT_FILE="$stage/rejected.dat"
if "$stage/batchl2" > "$stage/report.txt"; then rc=0; else rc=$?; fi
case "$rc" in
  0|4) ;;
  8|12) cat -- "$stage/report.txt" >&2; exit "$rc" ;;
  *) echo "Unexpected matcher RC=$rc; mapped to 12" >&2; exit 12 ;;
esac
python3 "$here/verify-publish.py" "$account" "$transaction" \
  "$stage/report.txt" "$stage/master.dat" "$stage/accepted.dat" \
  "$stage/rejected.dat" || exit 12
(cd "$stage" && sha256sum account.input.dat transaction.input.dat reversal-link.input.dat > inputs.sha256)
(cd "$stage" && sha256sum master.dat accepted.dat rejected.dat > outputs.sha256)
printf 'business_date=%s\n' "$5" > "$stage/run.txt"
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" > "$stage/source.sha256"
rm -- "$stage/batchl2" "$stage/duplicate-ids" "$stage/ledger.index" "$stage/links.index"
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
echo 'PASS: business and control totals verified'
exit "$rc"
