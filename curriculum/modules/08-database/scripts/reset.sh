#!/usr/bin/env bash
# 模块08 复位接口。
#   reset.sh --db          对“正在运行的课程库”重放 db/schema.sql + db/seed.sql。
#                          需要 PGHOST 等已由调用者设置；不触碰其他数据库。
#   reset.sh --containers  删除本模块遗留的一次性 m08-*-db 容器与 m08-*-net 网络。
# 本地自动化实验使用一次性容器，退出即销毁；此脚本用于手动/重复实验。
# 存在任意 *.lock 时拒绝 --db 复位（避免与运行中的发布竞争）。
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd -- "$here/.." && pwd)
mode=${1:-}
case "$mode" in
  --db)
    command -v psql >/dev/null 2>&1 || { echo 'FAIL: psql not found' >&2; exit 12; }
    [[ -n ${PGHOST:-} ]] || { echo 'FAIL: PGHOST not set' >&2; exit 12; }
    if find . -maxdepth 3 -type d -name '*.lock' -print -quit 2>/dev/null | grep -q .; then
      echo 'FAIL: workspace lock present; reset refused' >&2
      exit 12
    fi
    psql -v ON_ERROR_STOP=1 -q -f "$lab/db/schema.sql"
    psql -v ON_ERROR_STOP=1 -q -f "$lab/db/seed.sql"
    echo 'RESET-DB=OK'
    ;;
  --containers)
    command -v docker >/dev/null 2>&1 || { echo 'FAIL: docker not found' >&2; exit 12; }
    ids=$(docker ps -aq --filter 'name=^m08-.*-db$' || true)
    [[ -z $ids ]] || docker rm -f $ids >/dev/null
    nets=$(docker network ls -q --filter 'name=^m08-.*-net$' || true)
    [[ -z $nets ]] || docker network rm $nets >/dev/null
    echo 'RESET-CONTAINERS=OK'
    ;;
  *)
    echo 'Usage: reset.sh --db | --containers' >&2
    exit 12
    ;;
esac
