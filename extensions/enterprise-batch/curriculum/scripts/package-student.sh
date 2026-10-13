#!/usr/bin/env bash
# Build a repeatable learner bundle that excludes instructor answers.
#
# Usage: bash curriculum/scripts/package-student.sh [OUTPUT-DIR]
#   OUTPUT-DIR defaults to ./dist/student-<git-short-sha|nodist>
#
# The bundle contains only the learner-facing material: curriculum/ (all labs,
# fixtures, expected, scripts and learner evidence templates) plus the design
# docs under docs/.  It never contains instructor/ (reference answers, root
# causes, answer snapshots), compiled binaries, editor caches or the private
# orchestration files.  A MANIFEST lists every included path so the bundle can
# be audited and reproduced.
#
# Answer classification is by *role and content*, not by filename alone:
#   role "instructor"  - everything under instructor/ is an answer/hint/score.
#   role "embedded"    - a complete reference implementation that the module
#                        README designates as the answer to the *current*
#                        exercise even though it lives inside the student tree
#                        (curriculum/).  It is paired with the student starter
#                        that must ship instead.
# Once the included set is chosen, every shipped file is hashed and compared
# against the classified embedded answers; an exact content match fails the
# build even if the file was renamed or moved, so a filename-only scan cannot
# be bypassed.
set -Eeuo pipefail
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../.." && pwd)
out=${1:-"$repo/dist/student-$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo nodist)"}
case $out in /*) ;; *) out="$PWD/$out";; esac
[[ ! -e $out ]] || { echo "refusing to overwrite existing $out" >&2; exit 12; }

includes=(curriculum docs README.md)

# --- Answer role table -----------------------------------------------------
# Embedded exercise answers: "<answer path>|<student starter path>".  The
# answer must exist and stay out of the bundle; the starter must ship so the
# learner has the task.  Keep this list in sync with each module README.
embedded_answers=(
  "curriculum/modules/12-capstone/system/cobol/CUSTV2.COB|curriculum/modules/12-capstone/starter/CUSTV2.COB"
)

cd "$repo"
is_embedded_answer() {
  local path=$1 pair
  for pair in "${embedded_answers[@]}"; do
    [[ $path != "${pair%%|*}" ]] || return 0
  done
  return 1
}

# Collect a deterministic, sorted file list; fail if any answer path crept in.
# Learner bundles must not carry reference answers, instructor hint/scoring
# files (even when they sit under curriculum/) or reproducible-build caches.
mapfile -t files < <(
  find "${includes[@]}" -type f \
    ! -path '*/__pycache__/*' ! -name '*.pyc' ! -name '*.o' ! -name '*.so' \
    ! -path '*/instructor/*' ! -iname 'INSTRUCTOR.md' -print | LC_ALL=C sort
)
kept=()
for f in "${files[@]}"; do
  case "/$f/" in
    *"/instructor/"*) echo "answer path in bundle: $f" >&2; exit 12;;
  esac
  [[ ${f##*/} != INSTRUCTOR.md ]] || { echo "instructor note in bundle: $f" >&2; exit 12; }
  if is_embedded_answer "$f"; then
    continue
  fi
  kept+=("$f")
done

# --- Role/content integrity for the embedded answers -----------------------
# Verify the classification is real: each embedded answer exists, its paired
# starter exists and ships, and the answer is a genuinely different (completed)
# artifact rather than a stale copy of the starter.
for pair in "${embedded_answers[@]}"; do
  answer=${pair%%|*}
  starter=${pair##*|}
  [[ -f $answer ]] || { echo "classified answer missing: $answer" >&2; exit 12; }
  [[ -f $starter ]] || { echo "student starter missing: $starter" >&2; exit 12; }
  [[ $answer != "$starter" ]] || { echo "answer equals starter: $answer" >&2; exit 12; }
  found=0
  for f in "${kept[@]}"; do
    [[ $f != "$starter" ]] || found=1
    [[ $f != "$answer" ]] || { echo "answer leaked: $f" >&2; exit 12; }
  done
  [[ $found == 1 ]] || { echo "starter not shipped: $starter" >&2; exit 12; }
  if cmp -s -- "$answer" "$starter"; then
    echo "answer and starter identical: $answer" >&2
    exit 12
  fi
done

# --- Content cross-check: no shipped file may duplicate an embedded answer --
# Only the embedded exercise answers are content-checked.  Copybooks and other
# canonical interfaces legitimately appear on both sides (a canonical contract is
# meant to be shared), so matching the whole instructor tree would be noise.
# Restricting to the classified answers still catches a renamed or relocated
# copy of the actual solution, which a filename scan alone would miss.
declare -A answer_digests=()
for pair in "${embedded_answers[@]}"; do
  a=${pair%%|*}
  answer_digests["$(sha256sum -- "$a" | cut -d' ' -f1)"]=$a
done
for f in "${kept[@]}"; do
  d=$(sha256sum -- "$f" | cut -d' ' -f1)
  if [[ -n ${answer_digests[$d]:-} ]]; then
    echo "shipped file duplicates answer ${answer_digests[$d]}: $f" >&2
    exit 12
  fi
done

mkdir -p "$out"
manifest="$out/MANIFEST.txt"
: > "$manifest"
for f in "${kept[@]}"; do printf '%s\n' "$f" >> "$manifest"; done

(cd "$repo" && tar --create --file - --files-from "$out/MANIFEST.txt") | \
  tar --extract --directory "$out"
sha256sum "$manifest" > "$out/MANIFEST.sha256"
tarball="$out.tar.gz"
tar --create --gzip --file "$tarball" --directory "$out" .
echo "student bundle: $tarball"
echo "sha256: $(sha256sum "$tarball" | cut -d' ' -f1)"
echo "files: ${#kept[@]}"
