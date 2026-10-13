#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
cobc_bin=${COBC:-cobc}

command -v "$cobc_bin" >/dev/null
"$cobc_bin" -x -Wall -o "$tmp_dir/program" "$script_dir/BASH_TEST.COB"
output=$("$tmp_dir/program")
expected=$'Regression check passed.\nRecords processed: 3'
if [[ "$output" != "$expected" ]]; then
  printf 'Output mismatch\nExpected:\n%s\nActual:\n%s\n' "$expected" "$output" >&2
  exit 1
fi
printf 'PASS: output matched expected result\n'
