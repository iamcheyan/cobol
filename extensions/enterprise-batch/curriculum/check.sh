#!/usr/bin/env bash
# Repository-level quick acceptance for the enterprise COBOL curriculum.
#
# It runs P1 technical validation, then every module's own acceptance entry
# (each module ships scripts/check.sh, or check.sh at its root), then a
# fixed-format gate over all COBOL/Copybook sources.  A missing module entry is
# a hard failure, so this file is also the coverage gate for all 12 modules.
# Database integration is intentionally separate:
#   bash curriculum/validation/database/check.sh   (needs Docker/network)
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

echo '== P1 technical validation =='
python3 "$here/validation/layout/check.py"
python3 "$here/validation/matching/check.py"
python3 "$here/validation/interfaces/check.py"
python3 "$here/validation/authoring/check.py"

echo '== module acceptance =='
for module in "$here"/modules/*/; do
  name=$(basename "$module")
  [[ -f $module/README.md ]] || { echo "missing README: $module" >&2; exit 12; }
  if [[ -f $module/scripts/check-quick.sh ]]; then
    entry="$module/scripts/check-quick.sh"
  elif [[ -f $module/scripts/check.sh ]]; then
    entry="$module/scripts/check.sh"
  elif [[ -f $module/check.sh ]]; then
    entry="$module/check.sh"
  else
    echo "missing check entry for module: $name" >&2
    exit 12
  fi
  echo "-- module $name --"
  bash "$entry"
done

echo '== student bundle regression (R07) =='
python3 "$here/validation/student-bundle/check.py"

echo '== fixed-format gate =='
python3 - "$here" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
sources = sorted(p for p in root.rglob('*')
                 if p.suffix.lower() in {'.cob', '.cpy', '.cbl'})
sources += sorted((root.parent / 'instructor').rglob('*.COB'))
for path in sources:
    for n, line in enumerate(path.read_text().splitlines(), 1):
        assert line.isascii(), (path, n, 'non-ASCII fixed source')
        assert len(line) <= 72, (path, n, 'beyond column 72')
        assert '\t' not in line, (path, n, 'tab')
print(f'PASS: {len(sources)} COBOL/Copybook sources within 72 columns')
PY

echo '== all module and baseline checks passed =='
