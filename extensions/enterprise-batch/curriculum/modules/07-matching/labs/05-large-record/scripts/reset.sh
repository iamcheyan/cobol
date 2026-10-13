#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=${1:?usage: reset.sh WORKSPACE}
[[ -d $root && ! -L $root && -f $root/.b04-workspace ]] || exit 12
[[ $(cat -- "$root/.b04-workspace") == B04-workspace-v1 ]] || exit 12
# Acquire the SAME per-output lock the runner creates (run.sh does
# `lock="$out.lock"; mkdir "$lock"`). mkdir is atomic: any existing directory,
# regular file or symlink (even a dangling one) makes it fail, so a live run
# and reset can never both proceed. Holding the lock through the delete closes
# the check-then-delete race; on any refusal nothing is modified.
lock="$root/output.lock"
if ! mkdir -- "$lock" 2>/dev/null; then
  exit 12
fi
cleanup() { rmdir -- "$lock" 2>/dev/null || true; }
trap cleanup EXIT
if [[ -e $root/output || -L $root/output ]]; then
  python3 "$here/reset-output.py" "$root/output"
fi
