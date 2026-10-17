#!/usr/bin/env bash
# JOB008 下流ファイル公開：専用runディレクトリ内でステージングし、
# manifestを検証してからアトミックに公開する。ステージング途中の結果や既存の
# 結果を今回の実行結果として見せてはならない。
set -Eeuo pipefail
export LC_ALL=C
job=JOB008
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_RUN_ID BANK_LOG_DIR \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }

publishroot="$BANK_RUN_DIR/publish/$BANK_RUN_ID"
stage="$BANK_RUN_DIR/work/publish/$BANK_RUN_ID"
mkdir -p -- "$BANK_RUN_DIR/publish" "$BANK_RUN_DIR/work/publish"

if [[ -d $publishroot ]]; then
  # mv後、CURRENT更新前にクラッシュした場合の再公開。
  # このrunに対応し、完全に検証済みのmanifestだけを受け入れる。
  if ! python3 "$here/../lib/verify_publish.py" --dir "$publishroot" \
        --run-id "$BANK_RUN_ID" --business-date "$BANK_BUSINESS_DATE"; then
    b_log "$job" ERROR 'existing publish dir failed verification'; exit 12
  fi
  b_joblog "$job" INFO 'reusing verified publish dir from interrupted run'
else
  rm -rf -- "$stage"
  mkdir -p -- "$stage"
  cp -- "$BANK_RUN_DIR/work/closing/master.dat" "$stage/closing-master.dat"
  cp -- "$BANK_RUN_DIR/work/closing/accepted.dat" "$stage/accepted-tx.dat"
  cp -- "$BANK_RUN_DIR/work/closing/rejected.dat" "$stage/rejected-match.dat"
  cp -- "$BANK_RUN_DIR/work/validate/rejected.txt" "$stage/rejected-validate.txt"
  cp -- "$BANK_RUN_DIR/work/control/control.txt" "$stage/control-report.txt"
  cp -- "$BANK_RUN_DIR/work/control/report.txt" "$stage/control-report-human.txt"
  python3 "$here/../lib/manifest.py" --dir "$stage" \
    --run-id "$BANK_RUN_ID" --business-date "$BANK_BUSINESS_DATE" \
    --engine offline-file-checkpoint || { b_log "$job" ERROR 'manifest build failed'; exit 12; }
  # ディレクトリを可視化する前に、ステージング済みmanifestを検証する。
  python3 "$here/../lib/verify_publish.py" --dir "$stage" \
    --run-id "$BANK_RUN_ID" --business-date "$BANK_BUSINESS_DATE" \
    || { b_log "$job" ERROR 'staged manifest verification failed'; exit 12; }
  if [[ ${BANK_CRASH_AT:-} == during-publish ]]; then
    b_log "$job" INFO 'injected crash during publish (staged, not switched)'
    exit 97
  fi
  mv -T -n -- "$stage" "$publishroot" || {
    b_log "$job" ERROR 'publish collision'; exit 12; }
  [[ ! -e $stage ]] || { b_log "$job" ERROR 'staged dir still present'; exit 12; }
fi

# 今回のmanifestを検証した後に限り、ここでCURRENTポインターを移動する。
cur_tmp="$BANK_RUN_DIR/publish/.CURRENT.$BANK_RUN_ID"
printf '%s\n' "$BANK_RUN_ID" >"$cur_tmp"
mv -f -- "$cur_tmp" "$BANK_RUN_DIR/publish/CURRENT"
[[ $(cat "$BANK_RUN_DIR/publish/CURRENT") == "$BANK_RUN_ID" ]] || {
  b_log "$job" ERROR 'CURRENT pointer not updated'; exit 12; }
b_joblog "$job" INFO "published $publishroot"
b_marker "$job" 0
exit 0
