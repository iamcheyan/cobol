#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir=${BUILD_DIR:-"$script_dir/build"}
# 默认复用第 29 课安装的共享 GixSQL 工具链；课目录已更名为 29_embedded-sql。
# 第 29 课工具链缺失或被移动时，用 GIXSQL_ROOT 指向其 usr 目录。
gixsql_root=${GIXSQL_ROOT:-"$script_dir/../29_embedded-sql/build/toolchain/usr"}
gixpp="$gixsql_root/bin/gixpp"
copy_dir="$gixsql_root/share/gixsql/copy"
lib_dir="$gixsql_root/lib"
source_file="$script_dir/lesson.cob"
preprocessed="$build_dir/lesson_30.cbsql"
executable="$build_dir/lesson_30"

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

require_tool() {
    command -v "$1" >/dev/null 2>&1 || die "Required command is missing: $1"
}

prepare() {
    require_tool cobc
    test -x "$gixpp" || die "GixSQL preprocessor not found: $gixpp; install it in Lesson 29"
    test -f "$copy_dir/SQLCA.cpy" || die "GixSQL SQLCA copybook not found: $copy_dir/SQLCA.cpy"
    mkdir -p -- "$build_dir"
    "$gixpp" -e -I "$copy_dir" -i "$source_file" -o "$preprocessed"
}

build_program() {
    prepare
    multiarch=$(gcc -print-multiarch)
    cobc -x -fstatic-call "$preprocessed" -I "$copy_dir" \
        -L "$lib_dir" -L "$lib_dir/$multiarch" -lgixsql \
        -Q "-Wl,-rpath-link,$lib_dir/$multiarch" -o "$executable"
}

run_database() {
    local fixture=$1
    require_tool sqlite3
    build_program
    local database="$build_dir/cursor.db"
    rm -f -- "$database"
    sqlite3 "$database" < "$script_dir/$fixture"
    local multiarch
    multiarch=$(gcc -print-multiarch)
    local runtime_lib_path="$lib_dir:$lib_dir/$multiarch${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    DATASRC="sqlite://$database" \
    DATASRC_USR='' \
    DATASRC_PWD='' \
    GIXSQL_NOREC_CODE=100 \
    LD_LIBRARY_PATH="$runtime_lib_path" \
        "$executable"
}

case ${1:-} in
    check)
        prepare
        cobc -fsyntax-only -I "$copy_dir" "$preprocessed"
        ;;
    build)
        build_program
        ;;
    run)
        run_database schema.sql
        ;;
    run-empty)
        run_database schema-empty.sql
        ;;
    clean)
        rm -rf -- "$build_dir"
        # gixpp 把 gixsql.log 写在输入文件旁边（不受 CWD 影响），这里一并清掉
        rm -f -- "$script_dir/gixsql.log"
        ;;
    *)
        printf 'Usage: %s {check|build|run|run-empty|clean}\n' "$0" >&2
        exit 64
        ;;
esac
