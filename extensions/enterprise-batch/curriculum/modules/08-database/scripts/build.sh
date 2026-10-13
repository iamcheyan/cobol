#!/usr/bin/env bash
# 编译一个 ESQL 源文件为可执行文件（在工具镜像内 gixpp + cobc）。
# 用法：build.sh NEW_BINARY SOURCE.COB [COPYBOOK_DIR]
# 采用 GnuCOBOL 默认方言（不传 -std=cobol85）；固定格式检查在 check.py。
# 任意启动目录、路径含空格、目标已存在则拒绝（no-clobber），失败退出12。
set -Eeuo pipefail
trap 'exit 12' ERR
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo 'Usage: build.sh NEW_BINARY SOURCE.COB [COPYBOOK_DIR]' >&2
  exit 12
fi
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd -- "$here/.." && pwd)
target=$1
source=$(realpath -- "$2")
copydir=$(realpath -- "${3:-$lab/copybooks}")
bankdir=$(realpath -- "$lab/../../bank/copybooks")
[[ -f $source ]] || { echo "FAIL: source missing: $source" >&2; exit 12; }
[[ -d $copydir ]] || { echo "FAIL: copybook dir missing" >&2; exit 12; }
[[ -d $bankdir ]] || { echo "FAIL: canonical copybook dir missing" >&2; exit 12; }
[[ ! -e $target && ! -L $target ]] || { echo "FAIL: target exists: $target" >&2; exit 12; }
parent=$(dirname -- "$target")
[[ -d $parent && -w $parent ]] || { echo "FAIL: target dir not writable" >&2; exit 12; }
export M08_TOOL_IMAGE=${M08_TOOL_IMAGE:-cobol-course-gixsql:m08}
tag=$M08_TOOL_IMAGE
bash "$here/docker-image.sh" >/dev/null
tmp=$(mktemp -d)
cleanup() { rm -rf -- "$tmp"; }
trap 'cleanup; exit 12' ERR
trap cleanup EXIT
cp -- "$source" "$tmp/PROG.COB"
docker run --rm -v "$tmp:/work" -v "$copydir:/copy:ro" -v "$bankdir:/bank:ro" -w /work "$tag" bash -euc '
  gixpp -e -S -I /usr/local/share/gixsql/copy -i PROG.COB -o PROG.pp.cob
  cobc -Wall -x -I /usr/local/share/gixsql/copy -I /copy -I /bank \
    -L /usr/local/lib -lgixsql -o PROG PROG.pp.cob
'
mv -n -- "$tmp/PROG" "$target"
[[ ! -e $tmp/PROG ]] || { echo 'FAIL: move failed' >&2; exit 12; }
trap cleanup EXIT
