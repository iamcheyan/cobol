#!/usr/bin/env bash
# JOB entry for module 09. From any cwd; never overwrites inputs or outputs.
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 5 ]]; then
  echo 'Usage: run.sh CUSTOMER ACCOUNT TRANSACTION NEW_OUTPUT YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd "$here/.." && pwd)
repo=$(cd "$lab/../../.." && pwd)
# Shared subprograms are provided modules, not the exercise answer: use the
# instructor tree in the authoring repo, else the copy shipped in the bundle.
libdir="$repo/instructor/modules/09-modular"
[[ -f $libdir/AMTCALC.COB ]] || libdir="$lab/lib"
[[ $5 =~ ^[0-9]{8}$ ]] || { echo 'Invalid business date' >&2; exit 8; }
for input in "$1" "$2" "$3"; do
  [[ -f $input && -r $input ]] || { echo 'Input missing/unreadable' >&2; exit 12; }
done
customer=$(realpath -- "$1")
account=$(realpath -- "$2")
transaction=$(realpath -- "$3")
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
stage=$(mktemp -d "$parent/.bank09.XXXXXXXX")
cp -- "$customer" "$stage/customer.input.dat"
cp -- "$account" "$stage/account.input.dat"
cp -- "$transaction" "$stage/transaction.input.dat"
: > "$stage/batch09.log"
customer="$stage/customer.input.dat"
account="$stage/account.input.dat"
transaction="$stage/transaction.input.dat"

# --- JOB検査：transaction_id全体一意性（メモリ上限付き外部ソート） ----------
# BANK-SYSTEM契約：transaction_idが重複する取引を再記帳してはいけません。account/sequence/id順の
# ストリーム照合は順序しか保証せず、全体一意性は保証しません。外部ソート（cut | sortの外部マージ、メモリ
# 使用量に上限あり）後、隣接する重複を走査します。検出時はRC8で非公開です。全件メモリ配列を使わず、
# 学習対象の順次突合アルゴリズムも変更しません。
dups=$(cut -c11-26 -- "$transaction" | LC_ALL=C sort | LC_ALL=C uniq -d)
if [[ -n $dups ]]; then
  echo "FAIL: duplicate global transaction_id: $(printf '%s' "$dups" | tr '\n' ',')" >&2
  exit 8
fi

default_source="$repo/instructor/modules/09-modular/BATCH09.COB"
[[ -f $default_source ]] || default_source="$lab/starter/BATCH09.COB"
source=${COURSE_SOURCE:-"$default_source"}
inc="-I $lab/copybooks -I $repo/curriculum/bank/copybooks"
# shellcheck disable=SC2086
cobc -Wall $inc -x -o "$stage/batch09" \
  "$source" \
  "$libdir/AMTCALC.COB" \
  "$libdir/CUSTVAL.COB" \
  "$libdir/LOGGER.COB" || exit 12
export CUSTOMER_FILE="$customer" ACCOUNT_FILE="$account"
export TRANSACTION_FILE="$transaction" BATCH_DATE="$5"
export LEDGER_OUTPUT="$stage/ledger.dat"
export VALID_OUTPUT="$stage/customers-valid.dat"
export REJECT_OUTPUT="$stage/customers-rejected.dat"
export LOG_FILE="$stage/batch09.log"
if "$stage/batch09" > "$stage/report.txt"; then rc=0; else rc=$?; fi
case "$rc" in
  0|4) ;;
  8|12) cat -- "$stage/report.txt" >&2; exit "$rc" ;;
  *) echo "Unexpected RC=$rc; mapped to 12" >&2; exit 12 ;;
esac
python3 "$here/verify-publish.py" "$customer" "$account" "$transaction" \
  "$5" "$stage/report.txt" "$stage/ledger.dat" \
  "$stage/customers-valid.dat" "$stage/customers-rejected.dat" \
  "$stage/batch09.log" || exit 12
(cd "$stage" && sha256sum customer.input.dat account.input.dat \
  transaction.input.dat > inputs.sha256)
(cd "$stage" && sha256sum report.txt ledger.dat customers-valid.dat \
  customers-rejected.dat batch09.log > outputs.sha256)
printf 'business_date=%s\n' "$5" > "$stage/run.txt"
cobc -V > "$stage/compiler.txt" 2>&1
for src in "$source" AMTCALC.COB CUSTVAL.COB LOGGER.COB; do
  case "$src" in
    /*) sha256sum -- "$src" ;;
    *) sha256sum -- "$libdir/$src" ;;
  esac
done > "$stage/source.sha256"
rm -- "$stage/batch09"
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || { echo 'Publication collision' >&2; exit 12; }
echo 'PASS: business and control totals verified'
exit "$rc"
