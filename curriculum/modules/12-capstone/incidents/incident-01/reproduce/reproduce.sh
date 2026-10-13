#!/usr/bin/env bash
# Reproduce the incident-01 night exactly as the materials describe.
#
#   reproduce.sh [WORKDIR]
#
# Runs the delivered capstone against the frozen incident feed with the
# recorded parameters, then dumps the raw artifacts a responder needs:
# exit codes, scheduler state, job logs and the feed itself.  It does NOT
# state a root cause; finding one is the learner's task.
set -Eeuo pipefail
export LC_ALL=C
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
incident=$(cd -- "$here/.." && pwd)
module=$(cd -- "$incident/../.." && pwd)
work=${1:-"$PWD/m12-incident-01"}
rm -rf -- "$work"
mkdir -p -- "$work"

echo "==== inner params (from materials/params.txt) ===="
cat "$incident/materials/params.txt"
echo

set +e
bash "$module/scripts/run.sh" \
  --input "$incident/materials/feed" \
  --output "$work/out" \
  --db "$work/db" \
  --business-date 20261010 \
  --layout v1 \
  --run-id incident-repro \
  >"$work/reproduce.log" 2>&1
rc=$?
set -e
echo "reproduce_rc=$rc"
echo "published=$([[ -f $work/out/publish/CURRENT ]] && cat "$work/out/publish/CURRENT" || echo none)"
echo

echo "==== scheduler state after the night ===="
sed -n '1,40p' "$work/reproduce.log" || true
echo

echo "==== raw artifacts for your investigation ===="
echo "feed:  $incident/materials/feed/transaction.dat"
echo "logs:  $work/out/logs (if the failing run dir survived; a fail-safe"
echo "        failure removes the unpublished run dir by design)"
ls -la "$work" || true
echo
echo "Suggested techniques (state nothing; you must find the cause):"
echo "  cut -b 1-26 '$incident/materials/feed/transaction.dat' | sort | uniq -c"
echo "  sha256sum -c '$incident/materials/feed/MANIFEST.sha256' 2>/dev/null || true"
echo "  diff the feed against a known-good day under fixtures/"
exit 0
