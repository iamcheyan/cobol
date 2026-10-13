#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
out=${1:?usage: reset.sh OUTPUT-DIR}
[[ -d $out && ! -L $out ]] || exit 12
[[ ! -e $out.lock && ! -L $out.lock ]] || exit 12
python3 "$here/reset-output.py" "$out"
