#!/usr/bin/env bash
# JOB007 制御合計、日次レポート、顧客状態抽出：
# 実際のストリームを照合（内部保存確認）し、下流向け顧客状態抽出
# （CUSTOMER v1の27バイト目、A/D）を生成する。
# 不一致なら公開を停止する（RC8）。システム障害はRC12。
set -Eeuo pipefail
export LC_ALL=C
job=JOB007
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR M11_COBOL \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

overall=0
set +e
python3 "$here/../lib/control.py" >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0) ;;
  8) b_log "$job" ERROR 'control totals do not reconcile'; exit 8 ;;
  *) b_log "$job" ERROR "unexpected control rc=$rc mapped 12"; exit 12 ;;
esac

cust="$BANK_RUN_DIR/work/customer"
mkdir -p -- "$cust"
bin="$BANK_RUN_DIR/work/bin"
mkdir -p -- "$bin"
if [[ ! -x $bin/m11cust ]]; then
  if ! cobc -Wall -I "$M11_COBOL/../copybooks" -x \
        -o "$bin/m11cust" "$M11_COBOL/M11CUST.COB" \
        >>"$BANK_LOG_DIR/$job.log" 2>&1; then
    b_log "$job" ERROR 'customer extract build failed'; exit 12
  fi
fi
set +e
M11CUST_INPUT="$BANK_RUN_DIR/work/db/customer_snapshot.dat" \
M11CUST_EXTRACT="$cust/extract.txt" \
M11CUST_REPORT="$cust/report.txt" \
  "$bin/m11cust" >>"$BANK_LOG_DIR/$job.log" 2>&1
rc=$?
set -e
case "$rc" in
  0) ;;
  8) b_log "$job" ERROR 'customer extract structural failure'; exit 8 ;;
  *) b_log "$job" ERROR "unexpected customer rc=$rc mapped 12"; exit 12 ;;
esac
b_joblog "$job" INFO "control reconciled; customer $(sed -n 1p "$cust/report.txt")"
b_marker "$job" 0
exit 0
