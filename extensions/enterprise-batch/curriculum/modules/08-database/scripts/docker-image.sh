#!/usr/bin/env bash
# 构建模块08 的 ESQL 工具镜像（Docker，无数据库）。
# 复用 P1 的固定 GixSQL commit 与两个本地补丁：本脚本只读取 P1 目录，
# 不修改 P1 任何文件。组装一个临时构建上下文，避免与 P1 文件冲突。
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
db="$here/../db"
p1="$here/../../../validation/database"
tag=${M08_TOOL_IMAGE:-cobol-course-gixsql:m08}

command -v docker >/dev/null 2>&1 || { echo 'FAIL: docker not found' >&2; exit 12; }
docker info >/dev/null 2>&1 || { echo 'FAIL: docker daemon unavailable' >&2; exit 12; }
[[ -f "$db/Dockerfile" ]] || { echo 'FAIL: db/Dockerfile missing' >&2; exit 12; }
for p in "$p1"/gixsql-cursor-null.patch "$p1"/gixsql-closed-cursor.patch; do
  [[ -f "$p" ]] || { echo "FAIL: P1 patch missing: $p" >&2; exit 12; }
done
if [[ ${M08_FORCE_IMAGE:-0} != 1 ]] && docker image inspect "$tag" >/dev/null 2>&1; then
  echo "IMAGE-READY=$tag"
  exit 0
fi
ctx=$(mktemp -d)
cleanup() { rm -rf -- "$ctx"; }
trap 'cleanup; exit 12' ERR
trap cleanup EXIT
cp -- "$db/Dockerfile" "$ctx/Dockerfile"
cp -- "$p1"/gixsql-cursor-null.patch "$p1"/gixsql-closed-cursor.patch "$ctx/"
docker build -t "$tag" "$ctx"
echo "IMAGE-READY=$tag"
