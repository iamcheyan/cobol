#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${BUILD_DIR:-"$script_dir/build"}
gixsql_root=${GIXSQL_ROOT:-"$script_dir/../29_embedded-sql/build/toolchain/usr"}
gixpp="$gixsql_root/bin/gixpp"
sql_copy_dir="$gixsql_root/share/gixsql/copy"
lib_dir="$gixsql_root/lib"
copybook_dir="$script_dir/copybooks"
database="$build_dir/lesson32.db"
run_dir="$build_dir/run"
cobc_bin=${COBC:-cobc}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Required command is missing: %s\n' "$1" >&2
        exit 127
    }
}

prepare() {
    require_tool "$cobc_bin"
    test -x "$gixpp" || {
        printf 'GixSQL preprocessor not found: %s\n' "$gixpp" >&2
        exit 1
    }
    test -f "$sql_copy_dir/SQLCA.cpy" || {
        printf 'GixSQL SQLCA copybook not found: %s\n' \
            "$sql_copy_dir/SQLCA.cpy" >&2
        exit 1
    }
    mkdir -p -- "$build_dir"
    "$gixpp" -e -I "$sql_copy_dir" -I "$copybook_dir" \
        -i "$script_dir/sync_db_32.cob" \
        -o "$build_dir/sync_db_32.cbsql"
}

check_sources() {
    prepare
    "$cobc_bin" -fsyntax-only -I "$copybook_dir" \
        "$script_dir/lesson.cob" "$script_dir/load_post_32.cob"
    "$cobc_bin" -fsyntax-only -I "$copybook_dir" \
        -I "$sql_copy_dir" "$build_dir/sync_db_32.cbsql"
}

build_project() {
    check_sources
    "$cobc_bin" -c -fstatic-call -Wall -I "$copybook_dir" \
        -o "$build_dir/load_post_32.o" \
        "$script_dir/load_post_32.cob"
    "$cobc_bin" -c -fstatic-call -Wall -I "$copybook_dir" \
        -I "$sql_copy_dir" -o "$build_dir/sync_db_32.o" \
        "$build_dir/sync_db_32.cbsql"
    multiarch=$(gcc -print-multiarch)
    "$cobc_bin" -x -fstatic-call -Wall -I "$copybook_dir" \
        -o "$build_dir/lesson_32" "$script_dir/lesson.cob" \
        "$build_dir/load_post_32.o" "$build_dir/sync_db_32.o" \
        -L "$lib_dir" -L "$lib_dir/$multiarch" -lgixsql \
        -Q "-Wl,-rpath-link,$lib_dir/$multiarch"
}

prepare_run_dir() {
    rm -rf -- "$run_dir"
    mkdir -p -- "$run_dir"
    cp -- "$script_dir/fixtures/accounts.txt" "$run_dir/accounts.txt"
    cp -- "$script_dir/fixtures/transactions.txt" \
        "$run_dir/transactions.txt"
    cp -- "$build_dir/lesson_32" "$run_dir/lesson_32"
}

run_program() {
    local multiarch
    multiarch=$(gcc -print-multiarch)
    local runtime_lib_path="$lib_dir:$lib_dir/$multiarch${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    DATASRC="sqlite://$database" \
    DATASRC_USR='' \
    DATASRC_PWD='' \
    GIXSQL_NOREC_CODE=100 \
    LD_LIBRARY_PATH="$runtime_lib_path" \
        "$run_dir/lesson_32"
}

case ${1:-} in
    check)
        check_sources
        ;;
    build)
        build_project
        ;;
    run)
        require_tool sqlite3
        build_project
        rm -f -- "$database"
        sqlite3 "$database" < "$script_dir/schema.sql"
        prepare_run_dir
        (cd -- "$run_dir" && run_program)
        ;;
    run-existing)
        require_tool sqlite3
        test -f "$database" || {
            printf 'Database missing; run ./build.sh run first\n' >&2
            exit 1
        }
        test -x "$build_dir/lesson_32" || build_project
        prepare_run_dir
        (cd -- "$run_dir" && run_program)
        ;;
    clean)
        rm -rf -- "$build_dir"
        # gixppはgixsql.logを入力ファイルの隣に（CWDに関係なく）書くため、ここで一緒に削除する
        rm -f -- "$script_dir/gixsql.log"
        ;;
    *)
        printf 'Usage: %s {check|build|run|run-existing|clean}\n' "$0" >&2
        exit 64
        ;;
esac
