#!/usr/bin/env bash
# JOB007 制御総数と日次レポートの照合 -- nodes 007a/007b/007c/007d/007e.
# 実データストリームと DB 台帳を独立して整合性確認し、NIGHTRPT の顧客日次レポートを作成します。
# 不一致があれば公開を止めます。
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
report="$here/../lib/report.py"
work="$NIGHT_OUTPUT/work"
bin="$work/bin"

n_check() {  # 3 つの Python 整合性ノードで共用する runner
  local node=$1 sub=$2 out
  out=$(python3 "$report" "$sub" 2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR "$sub reconciliation failed"
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}
n_count_conserve() { n_check "$1" counts; }
n_amount_conserve() { n_check "$1" amounts; }
n_ledger_crosscheck() { n_check "$1" ledger; }

n_daily_report() {
  local node=$1 rdir="$work/report"
  mkdir -p -- "$rdir" "$bin"
  c12_build "$NIGHT_REPO/curriculum/modules/12-capstone/system/cobol/NIGHTRPT.COB" \
    "$bin/nightrpt" || { c12_log "$node" ERROR 'NIGHTRPT build failed'; return 12; }
  set +e
  NIGHTRPT_ACCOUNT="$work/closing/master.dat" \
  NIGHTRPT_CUSTOMER="$work/customer/customer_v2.dat" \
  NIGHTRPT_LAYOUT="v2" \
  NIGHTRPT_DAY="$rdir/customer-day.dat" \
  NIGHTRPT_REPORT="$rdir/daily-report.txt" \
  NIGHTRPT_DATE="$NIGHT_DATE" \
    "$bin/nightrpt" >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  local rc=$?
  set -e
  case "$rc" in
    0) c12_marker "$node" 0; return 0 ;;
    8) c12_log "$node" ERROR 'NIGHTRPT reconciliation failed'
       c12_marker "$node" 8; return 8 ;;
    *) c12_log "$node" ERROR "NIGHTRPT rc=$rc"; return 12 ;;
  esac
}

n_customer_day() {
  local node=$1 out acc tot
  out=$(python3 "$report" customerday 2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR 'customer-day check failed'
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  acc=$(sed -n 's/.*ACCOUNTS=\([0-9]*\).*/\1/p' \
    "$work/report/daily-report.txt" | tail -1)
  tot=$(sed -n 's/.*ACCOUNT_TOTAL=\([-0-9]*\).*/\1/p' \
    "$work/report/daily-report.txt" | tail -1)
  python3 "$here/../lib/capdb.py" record-control --db "$NIGHT_DB" \
    --business-date "$NIGHT_DATE" --run-id "$NIGHT_RUN_ID" \
    --pair "ACCOUNTS=${acc:-0}" --pair "TOTAL=${tot:-0}" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'control_total record failed'; return 12; }
  c12_marker "$node" 0
}

c12_step 007a-count-conserve n_count_conserve
c12_step 007b-amount-conserve n_amount_conserve
c12_step 007c-ledger-crosscheck n_ledger_crosscheck
c12_step 007d-daily-report n_daily_report
c12_step 007e-customer-day n_customer_day
c12_job_exit
