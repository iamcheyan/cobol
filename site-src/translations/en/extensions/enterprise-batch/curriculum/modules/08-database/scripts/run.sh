#!/usr/bin/env bash
# Module 08 end-to-end real DB experiment (Docker + PostgreSQL17 + GnuCOBOL3.2 + GixSQL).
# Usage: run.sh OUTPUT_DIR YYYYMMDD
#   Creates OUTPUT_DIR if absent; rejects an existing OUTPUT_DIR or <OUTPUT>.lock (no-clobber/lock).
#   Writes all artifacts to a private stage, then atomically publishes after independent psql checks;
#   any failure publishes nothing. Works from any starting directory and with paths containing spaces.
# Environment:
#   COURSE_SOURCE=learner ESQL snapshot source (defaults to instructor SNAPSHOT.COB). When set, it
#     receives exactly the same business checks as the instructor reference (RC4/RC0 + byte-for-byte
#     27B comparison); incomplete/incorrect implementations are actually rejected and not published.
#   M08_TOOL_IMAGE overrides the tool image name.
# RC: 0 all checks pass; 8 business/structure mismatch; 12 build/DB/connection/check/publication failure (no publish).
set -Eeuo pipefail
trap 'exit 12' ERR
export LC_ALL=C
if [[ $# != 2 ]]; then
  echo 'Usage: run.sh OUTPUT_DIR YYYYMMDD' >&2
  exit 12
fi
business_date=$2
[[ $business_date =~ ^[0-9]{8}$ ]] || { echo 'FAIL: bad business date' >&2; exit 8; }
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$here/../../../.." && pwd)
p1=$(cd -- "$repo/curriculum/validation/database" && pwd)
output=$(realpath -m -- "$1")
[[ ! -e $output && ! -L $output ]] || { echo "FAIL: output exists: $output" >&2; exit 12; }
parent=$(dirname -- "$output")
[[ -d $parent && -w $parent ]] || { echo 'FAIL: parent not writable' >&2; exit 12; }
lock="$output.lock"
mkdir -- "$lock" 2>/dev/null || { echo 'FAIL: lock exists' >&2; exit 12; }
export M08_TOOL_IMAGE=${M08_TOOL_IMAGE:-cobol-course-gixsql:m08}
tag=$M08_TOOL_IMAGE
runid="m08-$$-$RANDOM"
net="$runid-net"
db="$runid-db"
stage=''
cleanup() {
  docker rm -f "$db" >/dev/null 2>&1 || true
  docker network rm "$net" >/dev/null 2>&1 || true
  if [[ ${M08_DEBUG:-0} == 1 ]]; then
    echo "DEBUG stage=$stage" >&2
  else
    [[ -z $stage ]] || rm -rf -- "$stage"
  fi
  rmdir -- "$lock" 2>/dev/null || true
}
trap cleanup EXIT

# --- Tool image and DB container ---------------------------------------------
bash "$here/docker-image.sh" >/dev/null
stage=$(mktemp -d "$parent/.m08-stage.XXXXXXXX")
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
seed() {
  docker exec -i "$db" psql -U postgres -q -v ON_ERROR_STOP=1 < "$lab/db/schema.sql"
  docker exec -i "$db" psql -U postgres -q -v ON_ERROR_STOP=1 < "$lab/db/seed.sql"
}
q() { docker exec "$db" psql -U postgres -Atc "$1"; }

# --- Build (probe/application are existing support programs; snapshot defaults to learner source) ---
# ESQL-PROBE/APPLY are existing DB support programs, not exercise answers: prefer instructor tree,
# then the copies supplied in the student bundle. SNAPSHOT is the DBBATCH exercise's reference
# answer and must be excluded: compile the learner's starter by default (or explicit COURSE_SOURCE).
if [[ -f $repo/instructor/modules/08-database/ESQL-PROBE.COB ]]; then
  harnessdir="$repo/instructor/modules/08-database"
else
  harnessdir="$lab/system"
fi
bash "$here/build.sh" "$stage/bin/probe" "$harnessdir/ESQL-PROBE.COB"
bash "$here/build.sh" "$stage/bin/apply" "$harnessdir/APPLY.COB"
snapshot_bin=/work/bin/snapshot
if [[ -n ${COURSE_SOURCE:-} ]]; then
  # Learner snapshot source: same business checks as the instructor reference (see 08.3 below).
  bash "$here/build.sh" "$stage/bin/snapshot" "$(realpath -- "$COURSE_SOURCE")"
else
  default_snapshot="$repo/instructor/modules/08-database/SNAPSHOT.COB"
  [[ -f $default_snapshot ]] || default_snapshot="$lab/starter/DBBATCH.COB"
  bash "$here/build.sh" "$stage/bin/snapshot" "$default_snapshot"
fi
docker run --rm -v "$stage:/work" -w /work "$tag" bash -c 'cobc -V' > "$stage/compiler.txt"
docker run --rm -v "$p1:/p1:ro" -w /p1 "$tag" bash -c \
  'sha256sum gixsql-cursor-null.patch gixsql-closed-cursor.patch' > "$stage/p1-patches.sha256"

# Common tool-container arguments
tc=(docker run --rm --network "$net"
    -e PGHOST=database -e PGPORT=5432 -e COB_PRE_LOAD=/usr/local/lib/libgixsql.so
    -v "$stage:/work" -v "$lab:/lab:ro" -w /work "$tag")

seed

# --- 08.1 + 08.2 probes -------------------------------------------------------
if "${tc[@]}" bash -c './bin/probe' > "$stage/probe.out" 2>"$stage/probe.err"; then
  probe_rc=0
else
  probe_rc=$?
fi
if "${tc[@]}" bash -c './bin/probe fail-connect' > "$stage/probe-fail.out" 2>&1; then
  fail_rc=0
else
  fail_rc=$?
fi
grep -Fq 'PROBE=PASS' "$stage/probe.out" || { echo 'FAIL: probe did not pass' >&2; exit 12; }
[[ $probe_rc == 0 ]] || { echo "FAIL: probe RC=$probe_rc" >&2; exit 12; }
[[ $fail_rc == 12 ]] || { echo "FAIL: fail-connect RC=$fail_rc" >&2; exit 12; }
grep -Eq 'SQL-FAIL=.*:08[0-9A-Z]{3}' "$stage/probe-fail.out" \
  || { echo 'FAIL: no connection SQLSTATE 08xxx' >&2; exit 12; }

# --- 08.3 Snapshot extraction and upstream reconciliation --------------------
snap() {  # $1=upstream $2=prefix
  "${tc[@]}" env M08_BIZ_DATE="$business_date" \
    M08_SNAPSHOT="/work/$2.dat" M08_META="/work/$2-meta.txt" \
    M08_UPSTREAM="/lab/$1" M08_DIFF="/work/$2-reconcile.txt" \
    M08_CONTROL="/work/$2-control.txt" bash -c "$snapshot_bin"
}
if snap "fixtures/customer-upstream-20261009.dat" snapshot; then snap_rc=0; else snap_rc=$?; fi
if snap "fixtures/customer-upstream-20261009-nodiff.dat" snapshot-nodiff; then
  snap_ok_rc=0
else
  snap_ok_rc=$?
fi
# 08.3 Business checks use the same independent assertions for instructor and COURSE_SOURCE.
#   Differing upstream returns RC4, identical upstream RC0, and the 27B snapshot must match
#   independent expected bytes exactly. snap_rc=12 means a system-level program failure (e.g. an
#   incomplete starter): return RC12 without publishing. Other non-4/0 results or byte mismatches
#   are business/semantic failures: RC8, also without publishing.
if [[ $snap_rc == 12 ]]; then
  echo "FAIL: snapshot program system failure RC=12; nothing published" >&2
  exit 12
fi
[[ $snap_rc == 4 ]] || { echo "FAIL: snapshot diff RC=$snap_rc (want 4)" >&2; exit 8; }
[[ $snap_ok_rc == 0 ]] || { echo "FAIL: snapshot nodiff RC=$snap_ok_rc (want 0)" >&2; exit 8; }
cmp "$stage/snapshot.dat" "$lab/expected/snapshot-20261009.dat" \
  || { echo 'FAIL: snapshot bytes mismatch' >&2; exit 8; }

# --- 08.4 Rollback / commit / retry ------------------------------------------
run_apply() {  # $1=mode $2=txfile $3=runid $4=outprefix
  "${tc[@]}" env M08_BIZ_DATE="$business_date" M08_TX_FILE="/lab/$2" \
    M08_RUN_ID="$3" M08_MODE="$1" M08_CONTROL="/work/$4-control.txt" \
    bash -c './bin/apply'
}
if run_apply rollback fixtures/transactions-20261009.dat RUN-RB apply-rollback > "$stage/apply-rollback.out" 2>&1; then rb_rc=0; else rb_rc=$?; fi
rb_state=$(q "SELECT string_agg(closing_balance::text,',' ORDER BY account_id) FROM account")
rb_ledger=$(q "SELECT count(*) FROM transaction_ledger")
if run_apply apply fixtures/transactions-20261009.dat RUN-A apply-first > "$stage/apply-first.out" 2>&1; then first_rc=0; else first_rc=$?; fi
first_state=$(q "SELECT string_agg(closing_balance::text,',' ORDER BY account_id) FROM account")
first_ledger=$(q "SELECT count(*) FROM transaction_ledger")
first_commit=$(q "SELECT count(*) FROM batch_commit")
if run_apply apply fixtures/transactions-20261009.dat RUN-B apply-retry > "$stage/apply-retry.out" 2>&1; then retry_rc=0; else retry_rc=$?; fi
retry_state=$(q "SELECT string_agg(closing_balance::text,',' ORDER BY account_id) FROM account")
retry_ledger=$(q "SELECT count(*) FROM transaction_ledger")
retry_commit=$(q "SELECT count(*) FROM batch_commit")
[[ $rb_rc == 0 && $rb_state == '100,200,300' ]] || { echo "FAIL: rollback $rb_rc $rb_state" >&2; exit 8; }
[[ $first_rc == 0 && $first_state == '130,270,300' ]] || { echo "FAIL: first $first_rc $first_state" >&2; exit 8; }
[[ $first_ledger == 3 && $first_commit == 1 ]] || { echo 'FAIL: first ledger/commit' >&2; exit 8; }
[[ $retry_rc == 0 && $retry_state == '130,270,300' ]] || { echo "FAIL: retry $retry_rc $retry_state" >&2; exit 8; }
[[ $retry_ledger == 3 && $retry_commit == 1 ]] || { echo 'FAIL: retry duplicated update' >&2; exit 8; }
grep -Fq 'ALREADY-APPLIED=' "$stage/apply-retry.out" || { echo 'FAIL: retry not skipped' >&2; exit 8; }
{ echo "BALANCES=$first_state"; echo "LEDGER=$first_ledger"; echo "COMMIT=$first_commit"; } \
  > "$stage/db-after-first.txt"
{ echo "BALANCES=$retry_state"; echo "LEDGER=$retry_ledger"; echo "COMMIT=$retry_commit"; } \
  > "$stage/db-after-retry.txt"
{ echo "BALANCES=$rb_state"; echo "LEDGER=$rb_ledger"; } \
  > "$stage/db-after-rollback.txt"

# --- In-run duplicate (unique constraint 23505 + savepoint) and fresh DB state -
seed
if run_apply apply fixtures/transactions-dup-in-run.dat RUN-DUP apply-dup > "$stage/apply-dup.out" 2>&1; then
  dup_rc=0
else
  dup_rc=$?
fi
dup_ledger=$(q "SELECT count(*) FROM transaction_ledger")
dup_commit=$(q "SELECT count(*) FROM batch_commit")
dup_state=$(q "SELECT string_agg(closing_balance::text,',' ORDER BY account_id) FROM account")
[[ $dup_rc == 8 ]] || { echo "FAIL: dup-in-run RC=$dup_rc (want 8)" >&2; exit 8; }
[[ $dup_ledger == 0 && $dup_commit == 0 && $dup_state == '100,200,300' ]] \
  || { echo 'FAIL: dup-in-run not rolled back' >&2; exit 8; }
grep -Fq 'DUP-IN-RUN=' "$stage/apply-dup.out" || { echo 'FAIL: no DUP-IN-RUN' >&2; exit 8; }
{ echo "BALANCES=$dup_state"; echo "LEDGER=$dup_ledger"; echo "COMMIT=$dup_commit"; } \
  > "$stage/db-after-dup.txt"
rm -f -- "$stage/gixsql.log"

# --- Manifest, input snapshots, and publication ------------------------------
cp "$lab/db/schema.sql" "$stage/schema.sql"
cp "$lab/db/seed.sql" "$stage/seed.sql"
cp "$lab/fixtures/transactions-20261009.dat" "$stage/transactions.input.dat"
cp "$lab/fixtures/customer-upstream-20261009.dat" "$stage/upstream.input.dat"
(cd "$stage" && sha256sum transactions.input.dat upstream.input.dat schema.sql seed.sql \
  > inputs.sha256)
docker image inspect "$tag" --format '{{.Id}}' > "$stage/image-id.txt"
printf 'BUSINESS_DATE=%s\nRUN_ID=%s\n' "$business_date" "$runid" > "$stage/run.txt"
rm -rf -- "$stage/bin"
(cd "$stage" && find . -type f ! -name manifest.sha256 -printf '%P\n' | sort \
  | xargs -d '\n' sha256sum > manifest.sha256)
(cd "$stage" && sha256sum -c inputs.sha256 && sha256sum -c manifest.sha256)
mv -T -n -- "$stage" "$output" || { echo 'FAIL: publish failed' >&2; exit 12; }
[[ ! -e $stage ]] || { echo 'FAIL: stage not moved' >&2; exit 12; }
echo 'PASS: module08 real-DB run published'
exit 0
