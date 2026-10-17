#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
module="$repo/instructor/modules/04-structures"

usage() { echo 'usage: run.sh LESSON OUTPUT-DIR [INPUT]' >&2; exit 12; }

[[ $# -ge 2 ]] || usage
lesson=$1
out=$(realpath -m -- "$2")
case $lesson in
  04.1) prog=M04SHAPE;      input='' ;;
  04.2) prog=M04COPY;       input='' ;;
  04.3) prog=M04ENTERPRISE; input=${3:-} ;;
  *) usage ;;
esac
if [[ $lesson == 04.3 ]]; then
  [[ $# == 3 && -f $input && -r $input ]] || usage
else
  [[ $# == 2 ]] || usage
fi
[[ ! -e $out && ! -L $out ]] || exit 12
parent=$(dirname -- "$out")
[[ -d $parent && -w $parent ]] || exit 12
lock="$out.lock"
mkdir "$lock" 2>/dev/null || exit 12
stage=''
cleanup() { [[ -z $stage ]] || rm -rf -- "$stage"; rmdir -- "$lock" 2>/dev/null || :; }
trap cleanup EXIT
stage=$(mktemp -d "$parent/.m04-stage.XXXXXXXX")

if [[ $lesson == 04.3 ]]; then
  size=$(stat -c %s -- "$input")
  (( size % 1778 == 0 )) || { echo 'E: not a multiple of 1778' >&2; exit 8; }
  cp -- "$input" "$stage/input.dat"
  ( cd "$stage" && sha256sum input.dat > inputs.sha256 )
fi

default_source="$module/$prog.COB"
[[ -f $default_source ]] || default_source="$here/../starter/$prog.COB"
source=${COURSE_SOURCE:-"$default_source"}
"$here/build.sh" "$stage/m04" "$source"

if ( cd "$stage" && "$stage/m04" > report.txt 2> stderr.txt ); then
  rc=0
else
  rc=$?
fi
case $rc in
  0|4) ;;
  8) exit 8 ;;
  *) exit 12 ;;
esac

# 独立意味検証：対象プログラムの出力を正解とせず、Python参照モデルで構造の意味/FIELD-CATALOGから
# 期待レポートを再計算します。プレースホルダー、レコード省略、フィールド値/オフセット誤りは失敗となり非公開です。
python3 "$here/verify.py" "$lesson" "$stage" \
  || { echo 'FAIL: output rejected by independent verification' >&2; exit 8; }

cobc -V > "$stage/compiler.txt" 2>/dev/null || :
sha256sum -- "$source" > "$stage/source.sha256"
rm -f -- "$stage/m04"
(
  cd "$stage"
  if [[ -f inputs.sha256 ]]; then sha256sum -c inputs.sha256; fi
  files=(report.txt stderr.txt compiler.txt source.sha256)
  if [[ -f input.dat ]]; then files+=(input.dat inputs.sha256); fi
  sha256sum "${files[@]}" > manifest.sha256
  sha256sum -c manifest.sha256
)
mv -T -n -- "$stage" "$out" || exit 12
[[ ! -e $stage ]] || exit 12
stage=''
if (( rc == 4 )); then exit 4; fi
exit 0
