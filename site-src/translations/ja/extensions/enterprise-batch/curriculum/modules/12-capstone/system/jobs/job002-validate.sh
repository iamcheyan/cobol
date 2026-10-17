#!/usr/bin/env bash
# JOB002 長さと業務検証 -- nodes 002a/002b/002c/002d/002e.
# 最初に生バイト幅を検証します（trim 済みの picture に依存しません）。次に、
# canonical モジュール 10 validator が取引業務ルールを検証し、capstone の CUSTV2 が
# 企業顧客ビュー（独立したバージョン管理レイアウト）を v2 形式に正規化します。
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
snap="$NIGHT_OUTPUT/snapshot"
work="$NIGHT_OUTPUT/work"
bin="$work/bin"

n_length_check() {
  local node=$1 out
  out=$(python3 "$here/../lib/validate.py" length \
    --tx "$snap/transaction.dat" --customer "$snap/customer.dat" \
    --layout "$NIGHT_LAYOUT" 2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR 'raw length check failed'; c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}

n_numeric_check() {
  local node=$1 out
  out=$(python3 "$here/../lib/validate.py" numeric \
    --tx "$snap/transaction.dat" --customer "$snap/customer.dat" \
    --layout "$NIGHT_LAYOUT" 2>>"$NIGHT_LOG_DIR/$node.log") || {
    c12_log "$node" ERROR 'numeric check failed'; c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}

n_business_rules() {
  local node=$1 vdir="$work/validate" rc=0
  mkdir -p -- "$vdir" "$bin"
  c12_build "$(c12_bankval_source)" "$bin/bankval" || {
    c12_log "$node" ERROR 'BANKVAL build failed'; return 12; }
  set +e
  BANKVAL_IN="$snap/transaction.dat" \
  BANKVAL_ACCEPTED="$vdir/accepted_tx.dat" \
  BANKVAL_REJECTED="$vdir/rejected.txt" \
  BANKVAL_CONTROL="$vdir/control.txt" \
  BANKVAL_DATE="$NIGHT_DATE" \
    "$bin/bankval" >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0|4) c12_marker "$node" "$rc"; return "$rc" ;;
    8|12) c12_log "$node" ERROR "BANKVAL rc=$rc"; c12_marker "$node" "$rc"; return "$rc" ;;
    *) c12_bump 12; return 12 ;;
  esac
}

n_customer_validate() {
  local node=$1 cdir="$work/customer" rc=0
  mkdir -p -- "$cdir" "$bin"
  c12_build "$(c12_custv2_source)" \
    "$bin/custv2" || { c12_log "$node" ERROR 'CUSTV2 build failed'; return 12; }
  set +e
  CUSTV2_IN="$snap/customer.dat" \
  CUSTV2_OUT="$cdir/customer_v2.dat" \
  CUSTV2_REJECTED="$cdir/rejected.txt" \
  CUSTV2_CONTROL="$cdir/control.txt" \
  CUSTV2_LAYOUT="$NIGHT_LAYOUT" \
    "$bin/custv2" >>"$NIGHT_LOG_DIR/$node.log" 2>&1
  rc=$?
  set -e
  case "$rc" in
    0|4) c12_marker "$node" "$rc"; return "$rc" ;;
    8|12) c12_log "$node" ERROR "CUSTV2 rc=$rc"; c12_marker "$node" "$rc"; return "$rc" ;;
    *) c12_bump 12; return 12 ;;
  esac
}

n_reject_report() {
  local node=$1 vrej crej
  vrej=$(wc -l <"$work/validate/rejected.txt" 2>/dev/null || echo 0)
  crej=$(wc -l <"$work/customer/rejected.txt" 2>/dev/null || echo 0)
  {
    printf 'business_date=%s\n' "$NIGHT_DATE"
    printf 'transaction_rejects=%s\n' "$vrej"
    printf 'customer_rejects=%s\n' "$crej"
  } >"$work/validate/reject-summary.txt"
  c12_marker "$node" 0
}

c12_step 002a-length-check n_length_check
c12_step 002b-numeric-check n_numeric_check
c12_step 002c-business-rules n_business_rules
c12_step 002d-customer-validate n_customer_validate
c12_step 002e-reject-report n_reject_report
c12_job_exit
