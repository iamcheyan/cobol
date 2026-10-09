#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_file="$script_dir/L22.COB"
build_dir="$script_dir/build"
cobc_bin=${COBC:-cobc}

if ! command -v "$cobc_bin" >/dev/null 2>&1; then
  printf 'GNUCOBOL compiler not found: %s\n' "$cobc_bin" >&2
  exit 127
fi
mkdir -p "$build_dir"
"$cobc_bin" -x -Wall -o "$build_dir/bash-build" "$source_file"
"$build_dir/bash-build" "$@"
