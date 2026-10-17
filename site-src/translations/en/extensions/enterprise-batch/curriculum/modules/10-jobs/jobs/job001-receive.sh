#!/usr/bin/env bash
# JOB001 Receive and verify the Manifest: freeze the received feed as an immutable
# input snapshot and verify the delivery checksums before anything else.
set -Eeuo pipefail
export LC_ALL=C
job=JOB001
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
b_require "$job" BANK_RUN_DIR BANK_BUSINESS_DATE BANK_LOG_DIR BANK_INPUT \
  || exit "$?"
b_done "$job" && { b_log "$job" INFO 'resume: already complete'; exit 0; }
b_joblog "$job" INFO "receive from $BANK_INPUT date=$BANK_BUSINESS_DATE"

manifest="$BANK_INPUT/MANIFEST"
[[ -f $manifest && -r $manifest ]] || {
  b_log "$job" ERROR 'MANIFEST missing or unreadable'; exit 12; }
manifest_date=$(sed -n 's/^business_date=//p' "$manifest" | head -1)
[[ $manifest_date == "$BANK_BUSINESS_DATE" ]] || {
  b_log "$job" ERROR "manifest date '$manifest_date' != run date"; exit 8; }

snap="$BANK_RUN_DIR/snapshot"
mkdir -p -- "$snap"
count=0
while read -r tag name hash; do
  [[ $tag == file ]] || continue
  src="$BANK_INPUT/$name"
  [[ -f $src && -r $src ]] || {
    b_log "$job" ERROR "declared input '$name' missing"; exit 12; }
  actual=$(b_sha "$src")
  [[ $actual == "$hash" ]] || {
    b_log "$job" ERROR "checksum mismatch for '$name'"; exit 12; }
  cp -- "$src" "$snap/$name"
  count=$((count + 1))
done <"$manifest"
[[ $count -gt 0 ]] || { b_log "$job" ERROR 'manifest declares no files'; exit 12; }
cp -- "$manifest" "$snap/MANIFEST"
(
  cd -- "$snap"
  sha256sum -- ./* >snapshot.sha256
) || { b_log "$job" ERROR 'snapshot checksum failed'; exit 12; }
b_joblog "$job" INFO "frozen $count file(s) into snapshot"
b_marker "$job" 0 "files=$count"
exit 0
