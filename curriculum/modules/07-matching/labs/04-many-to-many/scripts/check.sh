#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$here/check.py"
python3 "$here/check-source.py"
(cd "$here/.." && sha256sum -c SHA256SUMS)
