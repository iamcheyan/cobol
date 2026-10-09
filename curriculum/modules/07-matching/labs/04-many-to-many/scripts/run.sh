#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 7 ]]; then
  echo 'Usage: run.sh ACCOUNT TX REVERSAL SNAPSHOT PREVIOUS OUTPUT YYYYMMDD' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../../" && pwd)
[[ $7 =~ ^[0-9]{8}$ ]] || exit 8
for input in "$1" "$2" "$3" "$4" "$5"; do
  [[ -f $input && -r $input ]] || exit 12
done
inputs=()
for input in "$1" "$2" "$3" "$4" "$5"; do
  inputs+=("$(realpath -- "$input")")
done
[[ ! -e $6 && ! -L $6 ]] || exit 12
output=$(realpath -m -- "$6")
[[ ! -e $output && ! -L $output ]] || exit 12
parent=$(dirname -- "$output")
[[ -d $parent && -w $parent ]] || exit 12
lock="$output.lock"
mkdir -- "$lock" 2>/dev/null || exit 12
stage=''
cleanup() {
  [[ -z $stage ]] || rm -rf -- "$stage"
  rmdir -- "$lock"
}
trap cleanup EXIT
[[ ! -e $output && ! -L $output ]] || exit 12
stage=$(mktemp -d "$parent/.b03-stage.XXXXXXXX")
mkdir "$stage/tmp"
cp -- "${inputs[0]}" "$stage/account.input.dat"
cp -- "${inputs[1]}" "$stage/transaction.input.dat"
cp -- "${inputs[2]}" "$stage/reversal-link.input.dat"
cp -- "${inputs[3]}" "$stage/customer-snapshot.input.dat"
cp -- "${inputs[4]}" "$stage/previous-day.input.dat"
(cd "$stage" && sha256sum ./*.input.dat > inputs.sha256)
l2run="$repo/curriculum/modules/07-matching/labs/03-one-to-many/scripts/run.sh"
if env -u COURSE_SOURCE bash "$l2run" "$stage/account.input.dat" \
  "$stage/transaction.input.dat" \
  "$stage/reversal-link.input.dat" "$stage/l2" "$7"; then
  l2rc=0
else
  l2rc=$?
fi
case "$l2rc" in
  0|4) ;;
  8|12) exit "$l2rc" ;;
  *) echo "Unexpected L2 RC=$l2rc" >&2; exit 12 ;;
esac
source=${COURSE_SOURCE:-"$repo/instructor/modules/07/04-many-to-many/BATCHL3.COB"}
"$here/build.sh" "$stage/batchl3" "$source"
export COB_SORT_MEMORY=${COB_SORT_MEMORY:-2M}
runtime_tmp=${B03_RUNTIME_TMPDIR:-"$stage/tmp"}
export TMPDIR="$runtime_tmp"
export B03_ACCOUNT_FILE="$stage/account.input.dat"
export B03_MASTER_FILE="$stage/l2/master.dat"
export B03_ACCEPT_FILE="$stage/l2/accepted.dat"
export B03_REJECT_FILE="$stage/l2/rejected.dat"
export B03_SNAPSHOT_FILE="$stage/customer-snapshot.input.dat"
export B03_PREVIOUS_FILE="$stage/previous-day.input.dat"
export B03_SNAPSHOT_NORMAL="$stage/snapshot.normal.dat"
export B03_PREVIOUS_NORMAL="$stage/previous.normal.dat"
export B03_ACCOUNT_FEED="$stage/account.feed.dat"
export B03_TX_FEED="$stage/transaction.feed.dat"
export B03_SPOOL_FILE="$stage/customer.spool.dat"
export B03_ELIGIBLE_MASTER="$stage/eligible-master.customer-order.dat"
export B03_ELIGIBLE_TX="$stage/eligible-transaction.customer-order.dat"
export B03_TOTALS_FILE="$stage/customer-totals.csv"
export B03_STATUS_FILE="$stage/customer-status.txt"
export B03_ISOLATION_FILE="$stage/isolation.txt"
export B03_CONTROL_FILE="$stage/control.txt"
export B03_BUSINESS_DATE="$7"
export B03_L2_RC="$l2rc"
if [[ ${B03_MEASURE_CORE:-N} == Y ]]; then
  "$stage/batchl3" > "$stage/core.stdout" &
  core_pid=$!
  printf '%s\n' "$core_pid" > "$stage/core-pid"
  core_peak=0
  while [[ -r "/proc/$core_pid/status" ]]; do
    while IFS= read -r proc_line; do
      if [[ $proc_line == VmHWM:* ]]; then
        read -r _ core_rss _ <<< "$proc_line"
        (( core_rss > core_peak )) && core_peak=$core_rss
      fi
    done < "/proc/$core_pid/status"
    sleep 0.01
  done
  if wait "$core_pid"; then
    rc=0
  else
    rc=$?
  fi
  printf '%s\n' "$core_peak" > "$stage/core-rss-kib"
else
  if "$stage/batchl3" > "$stage/core.stdout"; then
  rc=0
  else
    rc=$?
  fi
fi
case "$rc" in
  0|4) ;;
  8|12) exit "$rc" ;;
  *) echo "Unexpected B03 RC=$rc" >&2; exit 12 ;;
esac
sort -T "$stage/tmp" -k1.1,1.10 \
  "$stage/eligible-master.customer-order.dat" \
  > "$stage/eligible-master.dat"
sort -T "$stage/tmp" -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 \
  "$stage/eligible-transaction.customer-order.dat" \
  > "$stage/eligible-transaction.dat"
cp -- "$stage/l2/rejected.dat" "$stage/rejected-l2.dat"
cp -- "$stage/l2/report.txt" "$stage/l2-report.txt"
python3 "$here/verify.py" "$stage" "$7" "$l2rc" "$rc" || exit 12
(cd "$stage" && sha256sum account.input.dat transaction.input.dat \
  reversal-link.input.dat customer-snapshot.input.dat previous-day.input.dat \
  l2/master.dat l2/accepted.dat l2/rejected.dat l2/report.txt \
  eligible-master.dat eligible-transaction.dat rejected-l2.dat l2-report.txt \
  customer-totals.csv customer-status.txt isolation.txt control.txt \
  > manifest.sha256)
cobc -V > "$stage/compiler.txt"
sha256sum -- "$source" > "$stage/source.sha256"
rm -- "$stage/batchl3"
rm -f -- "$stage/core.stdout" "$stage/core-pid" "$stage/snapshot.normal.dat" \
  "$stage/previous.normal.dat" "$stage/account.feed.dat" \
  "$stage/transaction.feed.dat" "$stage/customer.spool.dat" \
  "$stage/eligible-master.customer-order.dat" \
  "$stage/eligible-transaction.customer-order.dat"
rmdir "$stage/tmp"
(cd "$stage" && sha256sum -c inputs.sha256 &&
  sha256sum -c manifest.sha256)
mv -T -n -- "$stage" "$output" || exit 12
[[ ! -e $stage ]] || exit 12
echo 'PASS: B03 customer aggregation, conservation and bytes verified'
if (( l2rc == 4 || rc == 4 )); then exit 4; fi
exit 0
