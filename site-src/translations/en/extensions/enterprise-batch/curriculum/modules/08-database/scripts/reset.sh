#!/usr/bin/env bash
# Module 08 reset interface.
#   reset.sh --db          Replay db/schema.sql + db/seed.sql against the “running course database”.
#                         PGHOST, etc. must be set by the caller; no other database is touched.
#   reset.sh --containers  Remove this module's leftover one-off m08-*-db containers and m08-*-net networks.
# Local automated experiments use disposable containers that are destroyed at exit; this script is
# for manual/repeated experiments. Refuse --db reset if any *.lock exists (to avoid racing publication).
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
