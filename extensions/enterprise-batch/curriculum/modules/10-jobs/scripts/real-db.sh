#!/usr/bin/env bash
# Module 10 real-DB route for JOB004 (extraction) and JOB006 (apply).
#
#   real-db.sh OUTPUT_DIR [BUSINESS_DATE]
#
# Reuses the P1-validated GixSQL/PostgreSQL toolchain and the canonical module
# 08 ESQL programs:
#   * SNAPSHOT.COB -- real cursor extraction (JOB004) of the day's customer
#     view, reconciled byte-for-byte against the frozen upstream feed;
#   * APPLY.COB    -- real single-transaction apply (JOB006): the idempotency
#     ledger, balance updates and batch commit are committed together, so a
#     retry after an unknown COMMIT result never re-posts.
# Balances, ledger rows and commit rows are read back through an INDEPENDENT
# psql connection, never from the program's own stdout.
#
# The offline file-checkpoint route (scripts/run.sh) is the default teaching
# path; this script is the real-DB evidence route and does not replace it.
#
# RC: 0 verified; 2 real DB environment unavailable (UNVERIFIED);
#     8 a business assertion failed; 12 build/DB/system failure.
set -Eeuo pipefail
export LC_ALL=C
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo 'Usage: real-db.sh OUTPUT_DIR [BUSINESS_DATE]' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$module/../../.." && pwd)
m08="$repo/curriculum/modules/08-database"
p1="$repo/curriculum/validation/database"
date=${2:-20261009}
# Profile knobs let the capstone (module 12) reuse this canonical harness:
# its DB layer composes the module 10 contract, so the same ESQL programs and
# seed shapes apply.  Defaults are the module 10 normal day.
realmod=${REALDB_MODULE:-$module}
dataset=${REALDB_DATASET:-$module/fixtures/normal}
expected_file=${REALDB_EXPECTED:-$module/expected/normal.closing.txt}
layout=${REALDB_LAYOUT:-}
[[ $date =~ ^[0-9]{8}$ ]] || { echo 'FAIL: bad business date' >&2; exit 12; }
# This route compiles the instructor ESQL programs; in a student bundle they
# are absent, so report UNVERIFIED instead of a hard failure.
if [[ ! -f $repo/instructor/modules/08-database/SNAPSHOT.COB \
      || ! -f $repo/instructor/modules/08-database/APPLY.COB ]]; then
  echo 'UNVERIFIED: instructor ESQL programs absent (real DB not verified)' >&2
  exit 2
fi

output=$(realpath -m -- "$1")
[[ ! -e $output && ! -L $output ]] || { echo "FAIL: output exists: $output" >&2; exit 12; }
parent=$(dirname -- "$output")
[[ -d $parent && -w $parent ]] || { echo 'FAIL: parent not writable' >&2; exit 12; }

command -v docker >/dev/null 2>&1 || {
  echo 'UNVERIFIED: docker not installed (real DB not verified)' >&2; exit 2; }
docker info >/dev/null 2>&1 || {
  echo 'UNVERIFIED: docker daemon unavailable (real DB not verified)' >&2; exit 2; }

export M08_TOOL_IMAGE=${M08_TOOL_IMAGE:-cobol-course-gixsql:m10}
tag=$M08_TOOL_IMAGE
runid="m10-$$-$RANDOM"
net="$runid-net"
db="$runid-db"
stage=''
lock="$output.lock"
mkdir -- "$lock" 2>/dev/null || { echo 'FAIL: lock exists' >&2; exit 12; }
cleanup() {
  docker rm -f "$db" >/dev/null 2>&1 || true
  docker network rm "$net" >/dev/null 2>&1 || true
  [[ -z $stage ]] || rm -rf -- "$stage"
  rmdir -- "$lock" 2>/dev/null || true
}
trap cleanup EXIT

# --- tool image (reuses the P1 Dockerfile + GixSQL patches) ------------------
if ! bash "$m08/scripts/docker-image.sh" >/dev/null; then
  echo 'UNVERIFIED: cannot build GixSQL tool image' >&2; exit 2
fi

stage=$(mktemp -d "$parent/.m10-realdb.XXXXXXXX")
mkdir "$stage/bin"
docker network create "$net" >/dev/null
docker run -d --name "$db" --network "$net" --network-alias database \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:17@sha256:e38411452a464af89e5adadb8d223bf53b898d47d6ef918b2d58c08707350449 >/dev/null
ready=0
for _ in {1..60}; do
  if docker exec "$db" pg_isready -U postgres >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
[[ $ready == 1 ]] || { echo 'FAIL: database not ready' >&2; exit 12; }

schema() { docker exec -i "$db" psql -U postgres -q -v ON_ERROR_STOP=1; }
q() { docker exec "$db" psql -U postgres -Atc "$1"; }

seed_db() {
  schema < "$m08/db/schema.sql"
  python3 "$module/lib/realdb_seed.py" \
    --account "$dataset/account_seed.dat" \
    --customer "$upstream" --date "$date" | schema
}

# The frozen 27 byte canonical CUSTOMER v1 view for this day.  Module 10 ships
# it directly as customer_seed.dat (27 B); the capstone feeds a wider
# CAP-CUSTOMER-FEED (31 B) whose first 27 bytes ARE the canonical customer v1,
# so the prefix is derived here.
feed=''
for cand in "$dataset/customer.dat" "$dataset/customer_seed.dat"; do
  [[ -f $cand ]] && { feed=$cand; break; }
done
[[ -n $feed ]] || { echo 'FAIL: no customer feed in dataset' >&2; exit 12; }
upstream="$stage/customer27.dat"
cut -b1-27 -- "$feed" >"$upstream"

# --- module chain: produce the real JOB004/JOB005 products ------------------
set +e
run_args=(--input "$dataset" --output "$stage/m10out" --db "$stage/m10db"
          --business-date "$date" --run-id realdb)
[[ -z $layout ]] || run_args+=(--layout "$layout")
bash "$realmod/scripts/run.sh" "${run_args[@]}" >"$stage/m10-run.log" 2>&1
m10rc=$?
set -e
[[ $m10rc == 0 || $m10rc == 4 ]] || {
  echo "FAIL: module chain rc=$m10rc" >&2; exit 12; }
accepted="$stage/m10out/work/closing/accepted.dat"
[[ -f $accepted ]] || { echo 'FAIL: no accepted.dat from JOB005' >&2; exit 12; }

# --- build canonical ESQL programs ------------------------------------------
bash "$m08/scripts/build.sh" "$stage/bin/snapshot" \
  "$repo/instructor/modules/08-database/SNAPSHOT.COB" >/dev/null
bash "$m08/scripts/build.sh" "$stage/bin/apply" \
  "$repo/instructor/modules/08-database/APPLY.COB" >/dev/null

tc=(docker run --rm --network "$net"
    -e PGHOST=database -e PGPORT=5432 -e COB_PRE_LOAD=/usr/local/lib/libgixsql.so
    -v "$stage:/work" -w /work "$tag")

seed_db

# --- JOB004: real cursor extraction (SNAPSHOT.COB) --------------------------
"${tc[@]}" env M08_BIZ_DATE="$date" M08_SNAPSHOT="/work/snapshot.dat" \
  M08_META="/work/snapshot-meta.txt" \
  M08_UPSTREAM="/work/customer27.dat" \
  M08_DIFF="/work/snapshot-reconcile.txt" M08_CONTROL="/work/snapshot-control.txt" \
  bash -c './bin/snapshot' >"$stage/snapshot.out" 2>&1 || {
    echo 'FAIL: real extraction (SNAPSHOT.COB) failed' >&2; exit 12; }
# The extracted 27B canonical customer view must equal the frozen feed prefix.
if ! cmp -s "$stage/snapshot.dat" "$upstream"; then
  echo 'FAIL: extracted snapshot != frozen 27B canonical customer view' >&2
  exit 8
fi
if grep -Eq 'DIFFS=[1-9]' "$stage/snapshot-control.txt"; then
  echo 'FAIL: extraction reported field differences vs frozen feed' >&2; exit 8
fi

apply_run() {  # apply_run RUN_ID TX_FILE MODE OUTPREFIX
  "${tc[@]}" env M08_BIZ_DATE="$date" M08_TX_FILE="$2" M08_RUN_ID="$1" \
    M08_MODE="$3" M08_CONTROL="/work/$4-control.txt" \
    bash -c './bin/apply'
}

# --- JOB006: single-transaction apply (APPLY.COB) ---------------------------
if apply_run RUN-A /work/m10out/work/closing/accepted.dat apply apply-first \
    >"$stage/apply-first.out" 2>&1; then first_rc=0; else first_rc=$?; fi
grep -Fq 'COMMITTED=YES' "$stage/apply-first.out" || {
  echo 'FAIL: first apply did not commit' >&2; exit 12; }
bal=$(q "SELECT string_agg(closing_balance::text, ',' ORDER BY account_id) FROM account")
ledger=$(q "SELECT count(*) FROM transaction_ledger")
commit=$(q "SELECT count(*) FROM batch_commit")
exp_bal=$(python3 - "$expected_file" <<'PY'
import sys
vals = []
for line in open(sys.argv[1]):
    line = line.strip()
    if not line:
        continue
    vals.append(str(int(line.split("=", 1)[1])))
print(",".join(vals))
PY
)
exp_open=$(python3 - "$dataset/account_seed.dat" <<'PY'
import sys
vals = []
for raw in open(sys.argv[1], "rb").read().splitlines():
    if not raw:
        continue
    value = int(raw[22:35].decode("ascii"))
    if raw[21:22] == b"-":
        value = -value
    vals.append(str(value))
print(",".join(vals))
PY
)
exp_ledger=$(awk 'END { print NR }' "$accepted")
[[ $first_rc == 0 && $bal == "$exp_bal" ]] || {
  echo "FAIL: DB balances $bal != expected $exp_bal (rc=$first_rc)" >&2; exit 8; }
[[ $ledger == "$exp_ledger" && $commit == 1 ]] || {
  echo "FAIL: ledger=$ledger commit=$commit (want 4/1)" >&2; exit 8; }

# --- unknown COMMIT result: a retry after a commit must not re-post ---------
if apply_run RUN-B /work/m10out/work/closing/accepted.dat apply apply-retry \
    >"$stage/apply-retry.out" 2>&1; then retry_rc=0; else retry_rc=$?; fi
grep -Fq 'ALREADY-APPLIED=' "$stage/apply-retry.out" || {
  echo 'FAIL: retry did not skip already-applied transactions' >&2; exit 8; }
bal2=$(q "SELECT string_agg(closing_balance::text, ',' ORDER BY account_id) FROM account")
ledger2=$(q "SELECT count(*) FROM transaction_ledger")
commit2=$(q "SELECT count(*) FROM batch_commit")
[[ $retry_rc == 0 && $bal2 == "$exp_bal" && $ledger2 == "$exp_ledger" && $commit2 == 1 ]] || {
  echo "FAIL: retry changed state bal=$bal2 ledger=$ledger2 commit=$commit2" >&2
  exit 8; }

# --- concurrent retry: two apply attempts must not double-post --------------
seed_db
apply_run RUN-C /work/m10out/work/closing/accepted.dat apply apply-c \
  >"$stage/apply-c.out" 2>&1 &
pc=$!
apply_run RUN-D /work/m10out/work/closing/accepted.dat apply apply-d \
  >"$stage/apply-d.out" 2>&1 &
pd=$!
c_rc=0; wait "$pc" || c_rc=$?
d_rc=0; wait "$pd" || d_rc=$?
bal3=$(q "SELECT string_agg(closing_balance::text, ',' ORDER BY account_id) FROM account")
ledger3=$(q "SELECT count(*) FROM transaction_ledger")
commit3=$(q "SELECT count(*) FROM batch_commit")
if [[ $bal3 != "$exp_bal" || $ledger3 != "$exp_ledger" || $commit3 != 1 ]]; then
  echo "FAIL: concurrent apply double-posted bal=$bal3 ledger=$ledger3 commit=$commit3" >&2
  exit 8
fi

# --- rollback atomicity: an aborted transaction leaves nothing ---------------
seed_db
if apply_run RUN-RB /work/m10out/work/closing/accepted.dat rollback apply-rb \
    >"$stage/apply-rb.out" 2>&1; then rb_rc=0; else rb_rc=$?; fi
rb_bal=$(q "SELECT string_agg(closing_balance::text, ',' ORDER BY account_id) FROM account")
rb_ledger=$(q "SELECT count(*) FROM transaction_ledger")
rb_commit=$(q "SELECT count(*) FROM batch_commit")
[[ $rb_rc == 0 && $rb_ledger == 0 && $rb_commit == 0 && $rb_bal == "$exp_open" ]] || {
  echo "FAIL: rollback not atomic bal=$rb_bal ledger=$rb_ledger commit=$rb_commit" >&2
  exit 8; }

# --- publish the evidence directory -----------------------------------------
{
  echo "REAL_DB_VERIFIED=yes"
  echo "ENGINE=postgresql17+gixsql (image=$tag)"
  echo "BUSINESS_DATE=$date"
  echo "EXTRACT_RC=0"
  echo "BALANCES_FIRST=$bal"
  echo "BALANCES_RETRY=$bal2"
  echo "BALANCES_CONCURRENT=$bal3"
  echo "LEDGER_CONCURRENT=$ledger3"
  echo "COMMIT_CONCURRENT=$commit3"
  echo "EXPECTED_BALANCES=$exp_bal"
} >"$stage/real-db-summary.txt"
docker image inspect "$tag" --format '{{.Id}}' >"$stage/image-id.txt" 2>/dev/null || true
rm -rf -- "$stage/bin" "$stage/m10out" "$stage/m10db"
(cd "$stage" && find . -type f -printf '%P\n' | sort | xargs -d '\n' sha256sum > manifest.sha256)
mv -T -n -- "$stage" "$output" || { echo 'FAIL: publish failed' >&2; exit 12; }
[[ ! -e $stage ]] || { echo 'FAIL: stage not moved' >&2; exit 12; }
echo 'PASS: module 10 real DB (extraction + single-transaction apply + independent verify)'
exit 0
