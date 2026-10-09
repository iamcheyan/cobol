#!/usr/bin/env bash
set -euo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$here/validation/layout/check.py"
python3 "$here/validation/matching/check.py"
python3 "$here/modules/07-matching/labs/01-one-to-one/scripts/check.py"
(cd "$here/modules/07-matching/labs/01-one-to-one/fixtures" && sha256sum -c SHA256SUMS)
python3 - "$here" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
for path in [*root.rglob('*.COB'), *root.rglob('*.CPY'),
             *(root.parent/'instructor').rglob('*.COB')]:
    for n, line in enumerate(path.read_text().splitlines(), 1):
        assert line.isascii(), (path, n, 'non-ASCII fixed source')
        assert len(line) <= 72, (path, n, 'beyond column 72')
        assert '\t' not in line, (path, n, 'tab')
print('PASS: all new COBOL/Copybooks within 72 columns')
PY
