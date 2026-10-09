#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# == 1 && -d $1 ]] || { echo 'usage: init-workspace.sh existing-empty-dir' >&2; exit 12; }
python3 - "$1" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]).resolve()
if any(root.iterdir()):
    raise SystemExit('Workspace must be empty')
marker = root / '.b02-merge-owned'
try:
    with marker.open('x', encoding='ascii') as stream:
        stream.write('B02-MERGE-v1\n')
except (FileExistsError, OSError) as error:
    raise SystemExit(f'Cannot mark workspace: {error}')
PY
