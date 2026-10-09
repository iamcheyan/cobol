#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project="cobol-p1-$$"
network="$project-net"
cleanup() {
  docker rm -f "$project-db" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT
test -f "$here/PROBE.COB" || { echo 'FAIL: SQL probe missing' >&2; exit 1; }
docker build -t cobol-course-esql:p1 "$here"
docker network create "$network" >/dev/null
# Trust is restricted to this disposable network; no host port or volume.
docker run -d --name "$project-db" --network "$network" \
  --network-alias database -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:17@sha256:e38411452a464af89e5adadb8d223bf53b898d47d6ef918b2d58c08707350449 >/dev/null
ready=0
for attempt in {1..60}; do
  if docker exec "$project-db" pg_isready -U postgres >/dev/null 2>&1; then
    ready=1; break
  fi
  sleep 1
done
[[ $ready == 1 ]] || { echo 'FAIL: database not ready' >&2; exit 1; }
docker exec -i "$project-db" psql -U postgres -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE p1_account (id INTEGER PRIMARY KEY, amount INTEGER, memo TEXT);
INSERT INTO p1_account VALUES (1, 100, NULL), (2, 200, 'ready');
SQL
log=$(mktemp)
trap 'rm -f "$log"; cleanup' EXIT
docker run --rm --network "$network" \
  -e PGHOST=database -e PGPORT=5432 -e COB_PRE_LOAD=/usr/local/lib/libocesql.so \
  -v "$here:/source:ro" cobol-course-esql:p1 \
  bash -euc 'cp /source/PROBE.COB .; \
    ocesql PROBE.COB PROBE.cob; \
    cobc -Wall -x -I /usr/local/share/open-cobol-esql/copy \
      -L /usr/local/lib -locesql -o probe PROBE.cob; ./probe' | tee "$log"
for expected in 'NULL=YES' 'ROWS=2' 'EOF=02000' \
    'DUPLICATE=23505' 'ROLLBACK=100' 'COMMIT=101'; do
  grep -Fxq "$expected" "$log" || { echo "FAIL: $expected" >&2; exit 1; }
done
actual=$(docker exec "$project-db" psql -U postgres -Atc \
  'SELECT amount FROM p1_account WHERE id=1')
[[ $actual == 101 ]] || { echo 'FAIL: persisted commit mismatch'; exit 1; }
echo 'PASS: real SQL cursor, NULL, EOF, unique violation, rollback, commit'
