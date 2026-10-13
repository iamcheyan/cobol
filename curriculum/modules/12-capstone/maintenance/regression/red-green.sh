#!/usr/bin/env bash
# Maintenance RED -> GREEN evidence: the enterprise customer
# classification extension (1 -> 2).
#
#   red-green.sh [WORKDIR]
#
# RED   : the as-delivered starter (v1 only) is run against the extension
#         day's 32 byte CAP-CUSTOMER-FEED v2 feed.  It must NOT accept v2
#         (nonzero RC) and must publish nothing.
# GREEN : the reference CUSTV2 (v2 aware) accepts the same feed (RC0).
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
module=$(cd -- "$here/../.." && pwd)
repo=$(cd -- "$module/../../.." && pwd)
work=${1:-"$PWD/m12-red-green"}
rm -rf -- "$work"
mkdir -p -- "$work"
feed="$module/fixtures/extension/customer.dat"
copy="$module/system/copybooks"

build() {  # build SOURCE OUT
  cobc -Wall -I "$copy" -x -o "$2" "$1" >/dev/null 2>&1
}

red_src="$module/starter/CUSTV2.COB"
# GREEN uses the learner's completed CUSTV2: an explicit CAPSTONE_STUDENT_CUSTV2
# wins, else the reference answer when it ships (authoring repo), else the
# learner's starter (student bundle, completed in place).
green_src=${CAPSTONE_STUDENT_CUSTV2:-}
if [[ -z $green_src ]]; then
  green_src="$module/system/cobol/CUSTV2.COB"
  [[ -f $green_src ]] || green_src="$module/starter/CUSTV2.COB"
fi
build "$red_src" "$work/red" || { echo 'RED build failed' >&2; exit 12; }
build "$green_src" "$work/green" || { echo 'GREEN build failed' >&2; exit 12; }

run_one() {  # run_one BIN TAG ; echo RC
  local bin=$1 tag=$2 rc=0
  rm -rf -- "$work/$tag-out"
  mkdir -p -- "$work/$tag-out"
  set +e
  CUSTV2_IN="$feed" \
  CUSTV2_OUT="$work/$tag-out/customer_v2.dat" \
  CUSTV2_REJECTED="$work/$tag-out/rejected.txt" \
  CUSTV2_CONTROL="$work/$tag-out/control.txt" \
  CUSTV2_LAYOUT=v2 \
    "$bin" >"$work/$tag-out/stdout.txt" 2>"$work/$tag-out/stderr.txt"
  rc=$?
  set -e
  echo "$rc"
}

red_rc=$(run_one "$work/red" red)
green_rc=$(run_one "$work/green" green)

red_published=no
[[ -f $work/red-out/customer_v2.dat ]] && red_published=yes
echo "RED=$red_rc"
echo "GREEN=$green_rc"
echo "RED_PUBLISHED=$red_published"

fail=0
[[ $red_rc != 0 ]] || { echo 'RED unexpectedly accepted v2' >&2; fail=1; }
[[ $red_published == no ]] || { echo 'RED published output on failure' >&2; fail=1; }
[[ $green_rc == 0 ]] || { echo 'GREEN did not accept v2' >&2; fail=1; }
[[ -f $work/green-out/customer_v2.dat ]] || { echo 'GREEN produced no v2 stream' >&2; fail=1; }
[[ $fail == 0 ]] || exit 1
echo 'PASS: RED (v1-only) then GREEN (v2-aware) on the extension feed'
