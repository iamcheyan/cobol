#!/usr/bin/env bash
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../../.." && pwd)
module="$repo/instructor/modules/03-bytes"

usage() { echo 'usage: run.sh LESSON OUTPUT-DIR [INPUT]' >&2; exit 12; }

[[ $# -ge 2 ]] || usage
lesson=$1
out=$(realpath -m -- "$2")
case $lesson in
  03.1|03.2)
    [[ $# == 2 ]] || usage
    input=''
    ;;
  03.3)
    [[ $# == 3 ]] || usage
    input=$3
    [[ -f $input && -r $input ]] || exit 12
    ;;
  *)
    usage
    ;;
esac
[[ ! -e $out && ! -L $out ]] || exit 12
parent=$(dirname -- "$out")
[[ -d $parent && -w $parent ]] || exit 12
lock="$out.lock"
mkdir "$lock" 2>/dev/null || exit 12
stage=''
cleanup() { [[ -z $stage ]] || rm -rf -- "$stage"; rmdir -- "$lock" 2>/dev/null || :; }
trap cleanup EXIT
stage=$(mktemp -d "$parent/.m03-stage.XXXXXXXX")

if [[ $lesson == 03.3 ]]; then
  size=$(stat -c %s -- "$input")
  (( size % 7 == 0 )) || { echo 'E: input length not a multiple of 7' >&2; exit 8; }
  cp -- "$input" "$stage/input.dat"
  ( cd "$stage" && sha256sum input.dat > inputs.sha256 )
fi

default_source="$module/M03BYTES.COB"
[[ -f $default_source ]] || default_source="$here/../starter/M03BYTES.COB"
source=${COURSE_SOURCE:-"$default_source"}
"$here/build.sh" "$stage/m03" "$source"

if ( cd "$stage" && M03_LESSON="${lesson#03.}" "$stage/m03" > report.txt 2> stderr.txt ); then
  rc=0
else
  rc=$?
fi
case $rc in
  0|4) ;;
  *) exit 12 ;;
esac

# 独立语义核验：不信任被测程序输出，用 Python 参考模型重算期望的 report/原始字节，
# 对输入记录、解码值/符号、记录数与布局逐项比对；占位报告、跳过记录、错误金额或符号、
# 记录数或布局不符一律失败且不发布（仅改完成标志不再能发布错误答案）。
python3 "$here/verify.py" "$lesson" "$stage" \
  || { echo 'FAIL: output rejected by independent verification' >&2; exit 8; }

cobc -V > "$stage/compiler.txt" 2>/dev/null || :
sha256sum -- "$source" > "$stage/source.sha256"
rm -f -- "$stage/m03"
(
  cd "$stage"
  if [[ -f inputs.sha256 ]]; then sha256sum -c inputs.sha256; fi
  files=(report.txt stderr.txt compiler.txt source.sha256)
  if [[ -f abi.bin ]]; then files+=(abi.bin); fi
  if [[ -f amounts.bin ]]; then files+=(amounts.bin); fi
  if [[ -f input.dat ]]; then files+=(input.dat inputs.sha256); fi
  sha256sum "${files[@]}" > manifest.sha256
  sha256sum -c manifest.sha256
)
mv -T -n -- "$stage" "$out" || exit 12
[[ ! -e $stage ]] || exit 12
stage=''
if (( rc == 4 )); then exit 4; fi
exit 0
