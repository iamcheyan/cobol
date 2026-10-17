#!/usr/bin/env bash
# モジュール08のリセットインターフェース。
#   reset.sh --db          「実行中のコースDB」にdb/schema.sql + db/seed.sqlを再適用します。
#                          PGHOSTなどは呼び出し側で設定してください。他のデータベースには触れません。
#   reset.sh --containers  本モジュールの一時m08-*-dbコンテナーとm08-*-netネットワークを削除します。
# ローカル自動実験は一時コンテナーを使い、終了時に削除します。このスクリプトは手動/反復実験用です。
# *.lockが存在する場合は--dbリセットを拒否します（実行中の公開処理との競合を防ぎます）。
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
