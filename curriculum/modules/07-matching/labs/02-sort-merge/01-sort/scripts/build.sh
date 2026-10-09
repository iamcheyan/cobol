#!/usr/bin/env bash
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
repo=$(cd "$here/../../../../../../" && pwd)
target=${1:-"$PWD/sorttx"}
source=${2:-"${COURSE_SOURCE:-$repo/instructor/modules/07/02-sort-merge/SORTTX.COB}"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
[[ -f $source && -d $(dirname -- "$target") ]] || { echo 'Build input/parent missing' >&2; exit 12; }
tmp=$(mktemp "$(dirname -- "$target")/.sorttx.XXXXXXXX") || { echo "Build workspace failed" >&2; exit 12; }
trap 'python3 -c "import os,sys; os.unlink(sys.argv[1]) if os.path.exists(sys.argv[1]) else None" "$tmp"' EXIT
if ! cobc -Wall -I "$repo/curriculum/bank/copybooks" -x -o "$tmp" "$source"; then
  echo 'COBOL build failed' >&2
  exit 12
fi
python3 - "$tmp" "$target" <<'PY'
import os,sys
try: os.link(sys.argv[1],sys.argv[2])
except OSError as e:
 print(f'Build publish failed: {e}',file=sys.stderr); raise SystemExit(12)
os.unlink(sys.argv[1])
PY
trap - EXIT
echo "Built $target"
