#!/usr/bin/env bash
# JOB001 Manifest の受信と検証 -- nodes 001a/001b/001c.
# 解析を始める前に受信 feed を変更不可のスナップショットとして凍結します。
# 以降の各ノードは受信ディレクトリではなく、必ずこのスナップショットを読みます。
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../lib/common.sh
source "$here/../lib/common.sh"
C12_JOB_RC=0

n_receive_manifest() {
  local node=$1 mf date
  mf="$NIGHT_INPUT/MANIFEST"
  [[ -f $mf && -r $mf ]] || { c12_log "$node" ERROR 'MANIFEST missing'; return 12; }
  date=$(sed -n 's/^business_date=//p' "$mf" | head -1)
  [[ $date == "$NIGHT_DATE" ]] || {
    c12_log "$node" ERROR "manifest date '$date' != run date"
    c12_marker "$node" 8; return 8; }
  c12_marker "$node" 0
}

n_verify_checksums() {
  local node=$1 count=0 tag name want got
  while read -r tag name want; do
    [[ $tag == file ]] || continue
    [[ -f "$NIGHT_INPUT/$name" ]] || {
      c12_log "$node" ERROR "declared input '$name' missing"; return 12; }
    got=$(c12_sha "$NIGHT_INPUT/$name")
    [[ $got == "$want" ]] || {
      c12_log "$node" ERROR "checksum mismatch for '$name'"; return 12; }
    count=$((count + 1))
  done <"$NIGHT_INPUT/MANIFEST"
  [[ $count -gt 0 ]] || { c12_log "$node" ERROR 'no files declared'; return 12; }
  c12_marker "$node" 0 "files=$count"
}

n_freeze_snapshot() {
  local node=$1 snap="$NIGHT_OUTPUT/snapshot" tag name
  rm -rf -- "$snap"
  mkdir -p -- "$snap"
  while read -r tag name _; do
    [[ $tag == file ]] || continue
    cp -- "$NIGHT_INPUT/$name" "$snap/$name"
  done <"$NIGHT_INPUT/MANIFEST"
  cp -- "$NIGHT_INPUT/MANIFEST" "$snap/MANIFEST"
  ( cd -- "$snap" && sha256sum -- ./* >snapshot.sha256 ) || {
    c12_log "$node" ERROR 'snapshot checksum build failed'; return 12; }
  c12_marker "$node" 0
}

c12_step 001a-receive-manifest n_receive_manifest
c12_step 001b-verify-checksums n_verify_checksums
c12_step 001c-freeze-snapshot n_freeze_snapshot
c12_job_exit
