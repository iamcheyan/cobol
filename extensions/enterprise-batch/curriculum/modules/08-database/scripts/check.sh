#!/usr/bin/env bash
# 模块08 总检查。两种模式：
#   仓库模式（有 instructor/）：离线契约 + 真实 DB 端到端 + 独立核对 +
#       讲师参考入口 + 语义错误源 + 学员起始代码 RED。
#   学生包模式（无 instructor/）：离线契约 + 真实 DB 端到端（用学员自己的
#       snapshot 实现），跳过仅依赖讲师参考与 pristine starter 的断言。
# 任意启动目录；不修改仓库内文件（产物写入 mktemp 目录）。
set -Eeuo pipefail
trap 'exit 12' ERR
here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
lab=$(cd -- "$here/.." && pwd)
repo=$(cd -- "$here/../../../.." && pwd)

if [[ -f $repo/instructor/modules/08-database/SNAPSHOT.COB ]]; then
  echo '== module 08 check: repository mode (instructor reference present) =='
  repo_mode=1
else
  echo '== module 08 check: student bundle mode (no instructor; learner source) =='
  repo_mode=0
fi

echo '== 1. 离线契约与独立 oracle =='
python3 "$here/check.py"

if ! docker info >/dev/null 2>&1; then
  echo 'UNVERIFIED: Docker 不可用，真实 DB 端到端实验未运行（不计为通过）'
  exit 3
fi

tmp=$(mktemp -d)
cleanup() { rm -rf -- "$tmp"; }
trap 'cleanup; exit 12' ERR
trap cleanup EXIT

echo '== 2. 真实 DB 端到端（Docker + PostgreSQL17 + GixSQL） =='
# 默认用学员自己的 snapshot 实现（仓库模式为讲师参考；学生包应为学员完成
# 的 starter，或显式 COURSE_SOURCE）。未完成时 RC12 且不发布。
if bash "$here/run.sh" "$tmp/out" 20261009; then
  run_rc=0
else
  run_rc=$?
fi
if [[ $run_rc != 0 ]]; then
  if [[ $repo_mode == 0 ]]; then
    echo "FAIL: learner snapshot did not complete (RC=$run_rc); " \
         'finish starter/DBBATCH.COB or set COURSE_SOURCE' >&2
    exit 12
  fi
  echo "FAIL: real DB run RC=$run_rc" >&2
  exit 12
fi

out="$tmp/out"
echo '== 3. 发布产物与独立预期对照 =='
cmp "$out/snapshot.dat" "$lab/expected/snapshot-20261009.dat"
cmp "$out/snapshot-reconcile.txt" "$lab/expected/snapshot-reconcile.txt"
cmp "$out/snapshot-control.txt" "$lab/expected/snapshot-control.txt"
cmp "$out/snapshot-nodiff-control.txt" "$lab/expected/snapshot-nodiff-control.txt"
cmp "$out/db-after-first.txt" "$lab/expected/db-after-first.txt"
cmp "$out/db-after-retry.txt" "$lab/expected/db-after-retry.txt"
cmp "$out/db-after-rollback.txt" "$lab/expected/db-after-rollback.txt"
cmp "$out/db-after-dup.txt" "$lab/expected/db-after-dup.txt"
grep -Fq 'PROBE=PASS' "$out/probe.out"
grep -Eq 'SQL-FAIL=.*:08[0-9A-Z]{3}' "$out/probe-fail.out"
while IFS= read -r key; do
  [[ -z $key ]] && continue
  grep -Fq "$key" "$out/snapshot-meta.txt" || { echo "FAIL: meta missing $key" >&2; exit 8; }
done < "$lab/expected/snapshot-meta.keys.txt"
while IFS= read -r needle; do
  [[ -z $needle ]] && continue
  grep -Fq "$needle" "$out/apply-retry.out" || { echo "FAIL: retry missing $needle" >&2; exit 8; }
done < "$lab/expected/apply-retry.must-contain.txt"
(cd "$out" && sha256sum -c inputs.sha256 >/dev/null && sha256sum -c manifest.sha256 >/dev/null)

if [[ $repo_mode == 0 ]]; then
  echo 'PASS: module08 student bundle (offline + real DB + student entry)'
  exit 0
fi

echo '== 4. 学员入口：正确参考作为 COURSE_SOURCE 完成正常流程并发布 =='
if COURSE_SOURCE="$repo/instructor/modules/08-database/SNAPSHOT.COB" \
     bash "$here/run.sh" "$tmp/refsource-out" 20261009 >"$tmp/refsource.log" 2>&1; then
  refsource_rc=0
else
  refsource_rc=$?
fi
[[ $refsource_rc == 0 ]] || { echo "FAIL: reference COURSE_SOURCE RC=$refsource_rc (want 0)" >&2; exit 12; }
[[ -f "$tmp/refsource-out/snapshot.dat" ]] \
  || { echo 'FAIL: reference COURSE_SOURCE did not publish' >&2; exit 12; }
cmp "$tmp/refsource-out/snapshot.dat" "$lab/expected/snapshot-20261009.dat" \
  || { echo 'FAIL: reference COURSE_SOURCE snapshot mismatch' >&2; exit 8; }
cmp "$tmp/refsource-out/snapshot-control.txt" "$lab/expected/snapshot-control.txt" \
  || { echo 'FAIL: reference COURSE_SOURCE control mismatch' >&2; exit 8; }

echo '== 5. 语义错误的学生实现：被业务断言拒绝、不发布 =='
# 仅一处业务字段错误、仍返回 RC4/RC0 的“学生源”；须在 27B 字节比对处被拒。
wrong="$tmp/wrong-snapshot.COB"
sed 's/HV-STATUS TO CUST-STATUS/"X" TO CUST-STATUS/' \
  "$repo/instructor/modules/08-database/SNAPSHOT.COB" > "$wrong"
grep -Fq 'MOVE "X" TO CUST-STATUS' "$wrong" \
  || { echo 'FAIL: wrong-source mutation did not apply' >&2; exit 12; }
if COURSE_SOURCE="$wrong" \
     bash "$here/run.sh" "$tmp/wrong-out" 20261009 >"$tmp/wrong.log" 2>&1; then
  wrong_rc=0
else
  wrong_rc=$?
fi
[[ $wrong_rc != 0 ]] || { echo 'FAIL: semantically wrong student source published (RC0)' >&2; exit 12; }
[[ ! -e "$tmp/wrong-out" ]] || { echo 'FAIL: wrong student source published output' >&2; exit 12; }

echo '== 6. 学员起始代码：可构建但未完成 RC12 不发布 =='
bash "$here/build.sh" "$tmp/dbbatch" "$lab/starter/DBBATCH.COB"
if COURSE_SOURCE="$lab/starter/DBBATCH.COB" \
     bash "$here/run.sh" "$tmp/student-out" 20261009 >"$tmp/student.log" 2>&1; then
  echo 'FAIL: student run unexpectedly succeeded' >&2; exit 12
else
  student_rc=$?
fi
[[ $student_rc == 12 ]] || { echo "FAIL: student RC=$student_rc (want 12)" >&2; exit 12; }
[[ ! -e "$tmp/student-out" ]] || { echo 'FAIL: student run published output' >&2; exit 12; }
rm -f "$tmp/dbbatch"

echo 'PASS: module08 full check (offline + real DB + independent verify + student entry)'