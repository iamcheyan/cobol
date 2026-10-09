#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# == 1 ]] || { echo 'usage: reset.sh marked-workspace' >&2; exit 12; }
python3 - "$1" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1]).resolve()
marker = root / '.b02-merge-owned'
if not root.is_dir() or not marker.is_file() or marker.read_text() != 'B02-MERGE-v1\n':
    print('Refusing reset: workspace marker missing', file=sys.stderr)
    raise SystemExit(12)
lock = root / 'merged.dat.lock'
if lock.exists() or lock.is_symlink():
    print('Refusing reset: output lock exists; verify its owner first', file=sys.stderr)
    raise SystemExit(12)
for name in ('mergetx', 'merged.dat'):
    path = root / name
    if path.is_symlink() or (path.exists() and not path.is_file()):
        print(f'Refusing unexpected artifact type: {name}', file=sys.stderr)
        raise SystemExit(12)
    if path.exists():
        path.unlink()
print('Reset generated MERGE binary/output; workspace and unrelated files preserved')
PY
