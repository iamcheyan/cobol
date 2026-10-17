#!/usr/bin/env bash
# JOB005 順次突合と残高計算：固定形式の
# 1:N突合器をソート済みスナップショットに対して実行する。期末Master候補は
# JOB006/JOB008までwork/closing/に隔離する。順序
# の崩れまたはオーバーフローは構造エラー（RC8）、孤立取引／当座貸越は
# 業務拒否としてRC4の警告となる。
set -Eeuo pipefail
export LC_ALL=C
job=JOB005
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR M11_COBOL \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

bin="$BANK_RUN_DIR/work/bin"
mkdir -p -- "$bin"
[[ -x $bin/m11match ]] || {
  b_joblog "$job" INFO "build matcher from $M11_COBOL/M11MATCH.COB"
  if ! cobc -Wall -I "$M11_COBOL/../copybooks" -x \
        -o "$bin/m11match" "$M11_COBOL/M11MATCH.COB" \
        >>"$BANK_LOG_DIR/$job.log" 2>&1; then
    b_log "$job" ERROR 'matcher build failed'; exit 12
  fi
}
out="$BANK_RUN_DIR/work/closing"
[[ ! -e $out ]] || { b_log "$job" ERROR 'closing candidate already exists'; exit 12; }
mkdir -p -- "$out"

set +e
M11MATCH_ACCOUNT="$BANK_RUN_DIR/work/db/account_master.dat" \
M11MATCH_TRANSACTION="$BANK_RUN_DIR/work/sorted_tx.dat" \
M11MATCH_MASTER_OUT="$out/master.dat" \
M11MATCH_ACCEPTED="$out/accepted.dat" \
M11MATCH_REJECTED="$out/rejected.dat" \
M11MATCH_REPORT="$out/report.txt" \
  "$bin/m11match" >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0|4)
    for f in master.dat accepted.dat rejected.dat report.txt; do
      [[ -f $out/$f ]] || { b_log "$job" ERROR "missing $f"; exit 12; }
    done
    b_joblog "$job" INFO "match rc=$rc $(sed -n 1p "$out/report.txt")"
    b_marker "$job" "$rc"
    exit "$rc" ;;
  8|12)
    b_log "$job" ERROR "match failed rc=$rc"; exit "$rc" ;;
  *)
    b_log "$job" ERROR "unexpected match rc=$rc mapped 12"; exit 12 ;;
esac
