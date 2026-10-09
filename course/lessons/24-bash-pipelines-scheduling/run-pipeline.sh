#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cobc_bin=${COBC:-cobc}
build_dir="$script_dir/build"
log_file=${LOG_FILE:-"$build_dir/batch.log"}
mkdir -p "$build_dir"
command -v "$cobc_bin" >/dev/null 2>&1 || {
  printf 'GNUCOBOL compiler not found: %s\n' "$cobc_bin" >&2
  exit 127
}
"$cobc_bin" -x -Wall -o "$build_dir/program" "$script_dir/L24.COB"
if "$build_dir/program" 2>&1 | tee -a "$log_file"; then
  printf 'batch succeeded\n' | tee -a "$log_file"
else
  status=$?
  printf 'batch failed: exit=%s\n' "$status" | tee -a "$log_file" >&2
  exit "$status"
fi
