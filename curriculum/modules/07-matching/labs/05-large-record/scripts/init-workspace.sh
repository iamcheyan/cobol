#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=${1:?usage: init-workspace.sh NEW-DIR}
[[ ! -e $root && ! -L $root ]] || exit 12
mkdir -p -- "$root"
cp -- "$here/../starter/BATCHL4.COB" "$root/BATCHL4.COB"
printf '%s\n' 'B04-workspace-v1' > "$root/.b04-workspace"
