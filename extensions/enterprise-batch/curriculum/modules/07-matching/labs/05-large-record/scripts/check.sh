#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$here/check.py"
(cd "$here/../fixtures" && sha256sum -c SHA256SUMS)
(cd "$here/.." && sha256sum -c SHA256SUMS)
