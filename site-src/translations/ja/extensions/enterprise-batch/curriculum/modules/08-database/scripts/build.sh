#!/usr/bin/env bash
# ESQLソースファイルを実行可能ファイルにコンパイルします（ツールイメージ内でgixpp + cobcを使用）。
# 使用法：build.sh NEW_BINARY SOURCE.COB [COPYBOOK_DIR]
# GnuCOBOLのデフォルト方言を使用します（-std=cobol85は指定しません）。固定形式の検査はcheck.pyで行います。
# 任意の作業ディレクトリから実行可能です。空白を含むパスに対応し、既存の出力先は拒否します（上書き禁止）。失敗時は12で終了します。
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
