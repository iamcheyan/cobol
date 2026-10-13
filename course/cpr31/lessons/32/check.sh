#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cpr31-capstone.XXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT
export BUILD_DIR="$work_dir/build"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

expect_file() {
    diff -u "$1" "$2" || fail "output differs: $2"
}

expect_line() {
    grep -Fq -- "$2" "$1" || fail "missing output: $2"
}

./build.sh run >"$work_dir/first.out" 2>"$work_dir/first.err"
expect_file "$script_dir/expected/first-run.txt" "$work_dir/first.out"
run_dir="$BUILD_DIR/run"
db="$BUILD_DIR/lesson32.db"
expect_file "$script_dir/expected/accepted.txt" "$run_dir/accepted.txt"
expect_file "$script_dir/expected/rejected.txt" "$run_dir/rejected.txt"
expect_file "$script_dir/expected/report.txt" "$run_dir/account-report.txt"
sqlite3 -noheader -separator '|' "$db" \
    "SELECT ACCOUNT_NO, CUSTOMER_ID, printf('%.2f', BALANCE) FROM ACCOUNT_SNAPSHOT ORDER BY ACCOUNT_NO" \
    >"$work_dir/database.out"
expect_file "$script_dir/expected/database.txt" "$work_dir/database.out"

./build.sh run-existing >"$work_dir/restart.out" 2>"$work_dir/restart.err"
expect_file "$script_dir/expected/restart.txt" "$work_dir/restart.out"

sqlite3 "$db" \
    "DELETE FROM ACCOUNT_SNAPSHOT WHERE ACCOUNT_NO = 'A000000005'"
./build.sh run-existing >"$work_dir/insert.out" 2>"$work_dir/insert.err"
expect_line "$work_dir/insert.out" \
    'SYNC INSERTED ACCOUNT=A000000005 BALANCE=0000250.75'
expect_line "$work_dir/insert.out" \
    'SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=000 UNCHANGED=002 INSERTED=001'
./build.sh run-existing >"$work_dir/after-insert.out" 2>"$work_dir/after-insert.err"
expect_file "$script_dir/expected/restart.txt" "$work_dir/after-insert.out"

multiarch=$(gcc -print-multiarch)
gixsql_root=${GIXSQL_ROOT:-"$script_dir/../29/build/toolchain/usr"}
lib_dir="$gixsql_root/lib"
runtime_lib_path="$lib_dir:$lib_dir/$multiarch${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
run_binary() {
    (
        cd -- "$run_dir"
        DATASRC="sqlite://$db" \
        DATASRC_USR='' \
        DATASRC_PWD='' \
        GIXSQL_NOREC_CODE=100 \
        LD_LIBRARY_PATH="$runtime_lib_path" \
            "$BUILD_DIR/lesson_32"
    )
}

rm -- "$run_dir/accounts.txt"
if run_binary >"$work_dir/missing-account.out" 2>"$work_dir/missing-account.err"; then
    fail 'missing account master returned success'
fi
expect_line "$work_dir/missing-account.out" 'ERROR=OPEN ACCOUNTS '
if grep -Fq 'CONNECT=OK' "$work_dir/missing-account.out"; then
    fail 'database sync ran after the account master open failed'
fi
cp -- "$script_dir/fixtures/accounts.txt" "$run_dir/accounts.txt"

sqlite3 "$db" <<'SQL'
UPDATE ACCOUNT_SNAPSHOT
   SET BALANCE = 999.00
 WHERE ACCOUNT_NO IN ('A000000001', 'A000000005');
CREATE TRIGGER reject_late_update
BEFORE UPDATE ON ACCOUNT_SNAPSHOT
WHEN OLD.ACCOUNT_NO = 'A000000005'
BEGIN
    SELECT RAISE(ABORT, 'injected update failure');
END;
SQL
if run_binary >"$work_dir/sql-failure.out" 2>"$work_dir/sql-failure.err"; then
    fail 'injected SQL update failure returned success'
fi
expect_line "$work_dir/sql-failure.out" 'ERROR=UPDATE SQLSTATE='
sqlite3 -noheader -separator '|' "$db" \
    "SELECT ACCOUNT_NO, printf('%.2f', BALANCE) FROM ACCOUNT_SNAPSHOT WHERE ACCOUNT_NO IN ('A000000001', 'A000000005') ORDER BY ACCOUNT_NO" \
    >"$work_dir/partial-database.out"
printf 'A000000001|1100.25\nA000000005|999.00\n' \
    >"$work_dir/partial-database.expected"
expect_file "$work_dir/partial-database.expected" \
    "$work_dir/partial-database.out"
sqlite3 "$db" 'DROP TRIGGER reject_late_update'
run_binary >"$work_dir/recovery.out" 2>"$work_dir/recovery.err"
expect_line "$work_dir/recovery.out" \
    'SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=001 UNCHANGED=002 INSERTED=000'
sqlite3 -noheader -separator '|' "$db" \
    "SELECT ACCOUNT_NO, printf('%.2f', BALANCE) FROM ACCOUNT_SNAPSHOT WHERE ACCOUNT_NO IN ('A000000001', 'A000000005') ORDER BY ACCOUNT_NO" \
    >"$work_dir/recovered-balances.out"
printf 'A000000001|1100.25\nA000000005|250.75\n' \
    >"$work_dir/recovered-balances.expected"
expect_file "$work_dir/recovered-balances.expected" \
    "$work_dir/recovered-balances.out"

printf 'PASS: posting, rejection, update, insert, restart, file failure, SQL partial failure, and recovery\n'
