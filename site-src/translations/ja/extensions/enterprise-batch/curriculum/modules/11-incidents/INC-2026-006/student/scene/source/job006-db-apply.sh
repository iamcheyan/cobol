#!/usr/bin/env bash
# JOB006 DB 更新と冪等台帳：受け入れ済み取引をオフラインのチェックポイントストアに
# 適用します。台帳が信頼できる情報源です。クラッシュ後や同日再実行時に
# 二重引き落としは発生しません。コミットを盲目的に再試行せず、復旧時には必ず
# 最初に db.py status を読み取ります。
set -Eeuo pipefail
export LC_ALL=C
job=JOB006
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_DB_DIR BANK_BUSINESS_DATE BANK_RUN_ID \
  BANK_LOG_DIR || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

inject=""
case "${BANK_CRASH_AT:-}" in
  before-db-commit) inject=before ;;
  mid-db-commit) inject=mid ;;
  after-db-commit) inject=after ;;
esac
b_joblog "$job" INFO "pre-apply ledger state: $(python3 "$here/../lib/db.py" status \
  --db "$BANK_DB_DIR" --business-date "$BANK_BUSINESS_DATE" 2>/dev/null || true)"

set +e
if [[ -n $inject ]]; then
  python3 "$here/../lib/db.py" apply --db "$BANK_DB_DIR" \
    --business-date "$BANK_BUSINESS_DATE" --run-id "$BANK_RUN_ID" \
    --accepted "$BANK_RUN_DIR/work/closing/accepted.dat" \
    --candidate-master "$BANK_RUN_DIR/work/closing/master.dat" \
    --inject "$inject" >"$BANK_RUN_DIR/work/db/apply.json" \
    2>>"$BANK_LOG_DIR/$job.log"
else
  python3 "$here/../lib/db.py" apply --db "$BANK_DB_DIR" \
    --business-date "$BANK_BUSINESS_DATE" --run-id "$BANK_RUN_ID" \
    --accepted "$BANK_RUN_DIR/work/closing/accepted.dat" \
    --candidate-master "$BANK_RUN_DIR/work/closing/master.dat" \
    >"$BANK_RUN_DIR/work/db/apply.json" 2>>"$BANK_LOG_DIR/$job.log"
fi
rc=$?
set -e
case "$rc" in
  0|4) b_marker "$job" "$rc"; exit "$rc" ;;
  8) b_log "$job" ERROR 'idempotency/balance check failed'; exit 8 ;;
  12) b_log "$job" ERROR 'DB apply system failure'; exit 12 ;;
  97) b_log "$job" INFO 'injected crash during DB commit'; exit 97 ;;
  *) b_log "$job" ERROR "unexpected apply rc=$rc mapped 12"; exit 12 ;;
esac
