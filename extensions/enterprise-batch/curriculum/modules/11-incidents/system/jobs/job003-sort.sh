#!/usr/bin/env bash
# JOB003 SORT and ordering verification: sort the accepted transactions
# by (account_id, sequence, transaction_id) with the system sort and
# then verify the output is really ordered and conserved.  Temporary
# space or permission failure is a system failure (RC12); a lost or
# reordered record is a structural failure (RC8).  No publish on fail.
set -Eeuo pipefail
export LC_ALL=C
job=JOB003
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

in="$BANK_RUN_DIR/work/validate/accepted_tx.dat"
out="$BANK_RUN_DIR/work/sorted_tx.dat"
[[ -f $in ]] || { b_log "$job" ERROR 'accepted input missing'; exit 12; }
[[ ! -e $out ]] || { b_log "$job" ERROR 'sorted output already exists'; exit 12; }
workbase="$BANK_RUN_DIR/work"
tmp=$(mktemp -d "$workbase/.m11sort.XXXXXXXX") || {
  b_log "$job" ERROR 'cannot create sort workspace (temp space/permission)'
  exit 12; }
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT

keys=(-k1.1,1.10 -k1.35,1.40 -k1.11,1.26)
if ! sort "${keys[@]}" -- "$in" >"$tmp/candidate.dat"; then
  b_log "$job" ERROR 'system sort failed'; exit 12
fi
if ! sort -c "${keys[@]}" -- "$tmp/candidate.dat"; then
  b_log "$job" ERROR 'ordered output failed verification'; exit 8
fi
if ! cmp -s <(sort -- "$in") <(sort -- "$tmp/candidate.dat"); then
  b_log "$job" ERROR 'sort changed the record multiset'; exit 8
fi
if [[ $(wc -l <"$in") != $(wc -l <"$tmp/candidate.dat") ]]; then
  b_log "$job" ERROR 'sorted record count lost rows'; exit 8
fi
mv -n -- "$tmp/candidate.dat" "$out"
[[ ! -e $tmp/candidate.dat ]] || { b_log "$job" ERROR 'sort publish collision'; exit 12; }
b_joblog "$job" INFO 'sorted and verified'
b_marker "$job" 0 "records=$(wc -l <"$out")"
exit 0
