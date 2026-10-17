#!/usr/bin/env bash
# JOB004 DB customer snapshot: freeze the day's opening account/customer view.
# NOTE: the DB layer is an offline file checkpoint store (lib/db.py);
# a real DB is NOT wired or verified in this module.
set -Eeuo pipefail
export LC_ALL=C
job=JOB004
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_DB_DIR BANK_BUSINESS_DATE BANK_RUN_ID \
  BANK_LOG_DIR || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

work="$BANK_RUN_DIR/work/db"
mkdir -p -- "$work"
set +e
python3 "$here/../lib/db.py" snapshot --db "$BANK_DB_DIR" \
  --business-date "$BANK_BUSINESS_DATE" --run-id "$BANK_RUN_ID" \
  >"$work/dbsnapshot.json" 2>>"$BANK_LOG_DIR/$job.log"
rc=$?
set -e
case "$rc" in
  0) ;;
  12) b_log "$job" ERROR 'DB snapshot failed'; exit 12 ;;
  *) b_log "$job" ERROR "unexpected snapshot rc=$rc mapped 12"; exit 12 ;;
esac
snap="$BANK_DB_DIR/snapshots/$BANK_BUSINESS_DATE"
[[ -f $snap/account_master.dat ]] || { b_log "$job" ERROR 'no account snapshot'; exit 12; }
cp -- "$snap/account_master.dat" "$work/account_master.dat"
cp -- "$snap/customer_snapshot.dat" "$work/customer_snapshot.dat"
b_joblog "$job" INFO "snapshot frozen ($(cat "$work/dbsnapshot.json"))"
b_marker "$job" 0
exit 0
