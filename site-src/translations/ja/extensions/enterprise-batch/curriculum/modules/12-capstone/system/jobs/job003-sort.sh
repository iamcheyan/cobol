#!/usr/bin/env bash
# JOB003 SORT と順序検証 -- nodes 003a/003b/003c.
# canonical モジュール 07 SORTTX runner を再利用します（コース全体でソート実装を一つに統一）。
# 続いて、出力順序を独立して証明します。
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
work="$NIGHT_OUTPUT/work"
sorter=$(c12_sort_runner)

n_build_sort() {
  local node=$1
  # canonical の取引ソート実装は curriculum（モジュール 07 lab）内にあり、
  # sort runner 自身の依存先です。このノードでは runner の存在だけを確認します。
  # 出力は 003b/003c で独立に検証するため、講師専用のソースパスは不要です。
  [[ -f $sorter ]] || { c12_log "$node" ERROR 'module 07 sort runner missing'; return 12; }
  c12_marker "$node" 0
}

n_sort() {
  local node=$1 out="$work/sorted_tx.dat" rc=0 keyout
  [[ ! -e $out ]] || { c12_log "$node" ERROR 'sorted output already exists'; return 12; }
  # 重複 transaction_id は業務エラーです。canonical sorter に渡す前に明示して、
  # 夜間ログに原因を分かりやすく残します。
  keyout=$(python3 "$here/../lib/validate.py" keys \
    --tx "$work/validate/accepted_tx.dat" 2>&1) || {
    c12_log "$node" ERROR "$keyout"
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$keyout" >>"$NIGHT_LOG_DIR/$node.log"
  set +e
  B02_DATE="$NIGHT_DATE" bash "$sorter" "$work/validate/accepted_tx.dat" "$out" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0) c12_marker "$node" 0; return 0 ;;
    8) c12_log "$node" ERROR 'sort rejected the accepted stream'
       c12_marker "$node" 8; return 8 ;;
    *) c12_log "$node" ERROR "sort failed rc=$rc"; return 12 ;;
  esac
}

n_order_verify() {
  local node=$1 out
  out=$(python3 "$here/../lib/ordercheck.py" --tx "$work/sorted_tx.dat" \
    2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR 'order/duplicate check failed'
    c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}

c12_step 003a-build-sort n_build_sort
c12_step 003b-sort n_sort
c12_step 003c-order-verify n_order_verify
c12_job_exit
