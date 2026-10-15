#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
toolchain_dir=${TOOLCHAIN_DIR:-"$script_dir/build/toolchain"}
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

gixsql_url='https://github.com/mridoni/gixsql/releases/download/v1.0.20b/gixsql-ubuntu-22.04-lts-x64-1.0.20b-1.deb'
fmt_url='https://mirrors.kernel.org/ubuntu/pool/universe/f/fmtlib/libfmt8_8.1.1+ds1-2_amd64.deb'
gixsql_sha='b0f952ce3ae948a83f7940a85e75f5bbe02c7ededd16c2a9ae029e5a5dab22ca'
fmt_sha='e993359633e95411813fba0726f0391b7005668d52a71d56effe0b69d1de9877'

download() {
    local url=$1
    local destination=$2
    curl --fail --location --silent --show-error "$url" --output "$destination"
}

for tool in curl dpkg-deb sha256sum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required tool is missing: %s\n' "$tool" >&2
        exit 127
    fi
done

download "$gixsql_url" "$tmp_dir/gixsql.deb"
download "$fmt_url" "$tmp_dir/libfmt8.deb"
printf '%s  %s\n' "$gixsql_sha" "$tmp_dir/gixsql.deb" | sha256sum --check --status
printf '%s  %s\n' "$fmt_sha" "$tmp_dir/libfmt8.deb" | sha256sum --check --status

mkdir -p -- "$toolchain_dir"
dpkg-deb --extract "$tmp_dir/gixsql.deb" "$toolchain_dir"
dpkg-deb --extract "$tmp_dir/libfmt8.deb" "$toolchain_dir"

test -x "$toolchain_dir/usr/bin/gixpp"
test -f "$toolchain_dir/usr/lib/libgixsql.so"
test -f "$toolchain_dir/usr/lib/libgixsql-sqlite.so"
printf 'GixSQL toolchain extracted to %s\n' "$toolchain_dir"
printf 'Set GIXSQL_ROOT=%s/usr when building.\n' "$toolchain_dir"
