#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
copybook_dir="$script_dir/copybooks"
build_dir=${BUILD_DIR:-"$script_dir/build"}
cobc_bin=${COBC:-cobc}

if [[ "$build_dir" != /* ]]; then
  build_dir="$script_dir/$build_dir"
fi

check_sources() {
  "$cobc_bin" -I "$copybook_dir" -fsyntax-only \
    "$script_dir/lesson.cob" \
    "$script_dir/post_transaction_28.cob" \
    "$script_dir/report_account_28.cob"
}

build_project() {
  check_sources
  mkdir -p "$build_dir"
  "$cobc_bin" -c -Wall -I "$copybook_dir" \
    -o "$build_dir/post_transaction_28.o" \
    "$script_dir/post_transaction_28.cob"
  "$cobc_bin" -c -Wall -I "$copybook_dir" \
    -o "$build_dir/report_account_28.o" \
    "$script_dir/report_account_28.cob"
  "$cobc_bin" -x -I "$copybook_dir" -o "$build_dir/lesson_28" \
    "$script_dir/lesson.cob" \
    "$build_dir/post_transaction_28.o" \
    "$build_dir/report_account_28.o"
}

case ${1:-build} in
  check)
    check_sources
    ;;
  build)
    build_project
    ;;
  run)
    build_project
    (cd "$build_dir" && ./lesson_28)
    ;;
  clean)
    rm -rf -- "$build_dir"
    ;;
  *)
    printf 'Usage: %s {check|build|run|clean}\n' "$0" >&2
    exit 64
    ;;
esac
