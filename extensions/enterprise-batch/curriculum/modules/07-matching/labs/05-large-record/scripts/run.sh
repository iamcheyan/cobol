#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../../../../" && pwd)
[[ $# == 3 ]] || { echo 'usage: run.sh OLD-FIXED NEW-FIXED OUTPUT-DIR' >&2; exit 12; }
for input in "$1" "$2"; do [[ -f $input && -r $input ]] || exit 12; done
[[ $1 != "$2" ]] || exit 12
for input in "$1" "$2"; do [[ $(stat -c %s -- "$input") -gt 0 ]] || :; size=$(stat -c %s -- "$input"); (( size % 1778 == 0 )) || exit 8; done
out=$(realpath -m -- "$3"); [[ ! -e $out && ! -L $out ]] || exit 12
parent=$(dirname -- "$out"); [[ -d $parent && -w $parent ]] || exit 12
lock="$out.lock"; mkdir "$lock" 2>/dev/null || exit 12
stage=''; cleanup(){ [[ -z $stage ]] || rm -rf -- "$stage"; rmdir -- "$lock"; }; trap cleanup EXIT
stage=$(mktemp -d "$parent/.b04-stage.XXXXXXXX")
cp -- "$1" "$stage/old.dat"; cp -- "$2" "$stage/new.dat"
(cd "$stage" && sha256sum old.dat new.dat > inputs.sha256)
source=${COURSE_SOURCE:-"$repo/instructor/modules/07/05-large-record/BATCHL4.COB"}
"$here/build.sh" "$stage/batchl4" "$source"
export B04_OLD="$stage/old.dat" B04_NEW="$stage/new.dat"
run_id=$(cd "$stage" && sha256sum old.dat new.dat | sha256sum | cut -c1-16)
export B04_RUN_ID="$run_id"
if "$stage/batchl4" > "$stage/report.txt"; then rc=0; else rc=$?; fi
case $rc in 0|4) ;; 8|12) exit "$rc" ;; *) exit 12 ;; esac
python3 "$here/verify.py" "$stage/old.dat" "$stage/new.dat" \
  "$stage/report.txt" || exit 12
cobc -V > "$stage/compiler.txt"; sha256sum "$source" > "$stage/source.sha256"
rm "$stage/batchl4"
(cd "$stage" && sha256sum -c inputs.sha256 && sha256sum old.dat new.dat report.txt compiler.txt source.sha256 > manifest.sha256 && sha256sum -c manifest.sha256)
mv -T -n -- "$stage" "$out" || exit 12
[[ ! -e $stage ]] || exit 12
if (( rc == 4 )); then exit 4; fi
exit 0
