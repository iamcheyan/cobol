#!/usr/bin/env bash
# Build the module 12 capstone COBOL programs into a target directory.
#   build.sh TARGET_DIR
# Refuses to overwrite an existing target; compiles in a temp dir first.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/.." && pwd)
cobol="$module/system/cobol"
copy="$module/system/copybooks"
target=${1:-"$PWD/capstone-bin"}
[[ ! -e $target && ! -L $target ]] || { echo 'Build target exists' >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent && -w $parent ]] || { echo 'Build parent missing' >&2; exit 12; }
tmp=$(mktemp -d "$parent/.capstone-build.XXXXXXXX") || { echo 'mktemp failed' >&2; exit 12; }
trap 'rm -rf -- "$tmp"' EXIT
# CUSTV2 is the learner's capstone deliverable: build the learner's source
# (CAPSTONE_STUDENT_CUSTV2, else the starter, else the reference answer when
# it ships in the authoring repo).  NIGHTRPT is provided system code.
custv2_src="$cobol/CUSTV2.COB"
[[ -f $custv2_src ]] || custv2_src="$module/starter/CUSTV2.COB"
[[ -n ${CAPSTONE_STUDENT_CUSTV2:-} ]] && custv2_src=$CAPSTONE_STUDENT_CUSTV2
sources=(NIGHTRPT)
if ! cobc -Wall -I "$copy" -x -o "$tmp/CUSTV2" "$custv2_src"; then
  echo 'COBOL build failed for CUSTV2' >&2
  exit 12
fi
for prog in "${sources[@]}"; do
  if ! cobc -Wall -I "$copy" -x -o "$tmp/$prog" "$cobol/$prog.COB"; then
    echo "COBOL build failed for $prog" >&2
    exit 12
  fi
done
mv -T -n -- "$tmp" "$target" || { echo 'Build target collision' >&2; exit 12; }
[[ ! -e $tmp ]] || { echo 'Build stage not moved' >&2; exit 12; }
trap - EXIT
echo "Built $target (CUSTV2 NIGHTRPT)"
