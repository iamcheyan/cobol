#!/usr/bin/env bash
# JOB004 DB 顧客スナップショット -- nodes 004a/004b/004c.
# 当日の期首口座/顧客ビューを凍結します。このスナップショットは変更不可で、
# この run 自身の記帳で書き換えることはありません。DB 層はオフラインの
# ファイル・チェックポイント・ストア（capdb.py）であり、実 DB は検証していません。
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0
capdb="$here/../lib/capdb.py"
work="$NIGHT_OUTPUT/work/db"

n_db_reachability() {
  local node=$1 n
  mkdir -p -- "$work"
  n=$(python3 "$capdb" tables | wc -l)
  [[ $n == 12 ]] || { c12_log "$node" ERROR "expected 12 tables, got $n"; return 12; }
  python3 "$capdb" calendar --db "$NIGHT_DB" --business-date "$NIGHT_DATE" \
    >>"$NIGHT_LOG_DIR/$node.log" 2>&1 || {
    c12_log "$node" ERROR 'business calendar unavailable'; return 12; }
  c12_marker "$node" 0 "tables=12"
}

n_freeze_customer() {
  local node=$1 snap="$NIGHT_DB/snapshots/$NIGHT_DATE"
  python3 "$capdb" snapshot --db "$NIGHT_DB" --business-date "$NIGHT_DATE" \
    --run-id "$NIGHT_RUN_ID" >"$work/dbsnapshot.json" \
    2>>"$NIGHT_LOG_DIR/$node.log" || {
    c12_log "$node" ERROR 'DB snapshot failed'; return 12; }
  [[ -f $snap/customer_snapshot.dat ]] || {
    c12_log "$node" ERROR 'no customer snapshot'; return 12; }
  cp -- "$snap/customer_snapshot.dat" "$work/customer_snapshot.dat"
  c12_marker "$node" 0
}

n_freeze_account() {
  local node=$1 snap="$NIGHT_DB/snapshots/$NIGHT_DATE"
  [[ -f $snap/account_master.dat ]] || {
    c12_log "$node" ERROR 'no account snapshot'; return 12; }
  cp -- "$snap/account_master.dat" "$work/account_master.dat"
  c12_marker "$node" 0
}

c12_step 004a-db-reachability n_db_reachability
c12_step 004b-freeze-customer n_freeze_customer
c12_step 004c-freeze-account n_freeze_account
c12_job_exit
