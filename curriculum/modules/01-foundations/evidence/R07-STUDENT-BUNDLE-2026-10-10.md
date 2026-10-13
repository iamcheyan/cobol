# R07 修复证据：学生包缺运行依赖 + 答案泄漏（2026-10-10）

对应审查条目 `tasks/enterprise-cobol-final-review-2026-10-10.md` R07。
平台：Linux x86-64，GnuCOBOL 3.2.0。基线 HEAD `ad058c5`。

## 1. 原反例（修复前，已复现）

```sh
bash curriculum/scripts/package-student.sh /tmp/r07-repro/bundle   # RC 0, files 1214
mkdir -p /tmp/r07-repro/unpack && tar -xzf bundle.tar.gz -C /tmp/r07-repro/unpack
find /tmp/r07-repro/unpack -name CUSTV2.COB
#   .../starter/CUSTV2.COB
#   .../system/cobol/CUSTV2.COB          <- 当前练习参考答案泄漏
bash curriculum/modules/01-foundations/scripts/build.sh /tmp/r07-repro/bankentry
#   cobc: .../instructor/modules/01-foundations/BANK-ENTRY.COB: No such file
#   COBOL build failed                                               BUILD_RC=12
bash curriculum/modules/01-foundations/scripts/run.sh \
  curriculum/modules/01-foundations/fixtures/normal/account.dat /tmp/r07-repro/m01out 20261009
#   cobc: .../instructor/.../BANK-ENTRY.COB: No such file            RUN_RC=12
```

原反例：模块 01 build/run 均 RC12（依赖被排除的 instructor 参考），且包中保留了
`system/cobol/CUSTV2.COB`（模块 12 README 列为当前练习参考答案）。

## 2. 修复

- `curriculum/scripts/package-student.sh`
  - 角色分类：`instructor/**` 与 `INSTRUCTOR.md` 仍为“答案/提示/评分”。
  - 新增“内嵌练习答案”角色表 `embedded_answers`，含
    `curriculum/modules/12-capstone/system/cobol/CUSTV2.COB`，并校验其配对的
    学员 starter 必须随包发布、答案与 starter 内容不同。
  - 内容交叉校验：对每个内嵌答案取 sha256，若包内**任意文件**（不论文件名）内容与之
    相同即 RC12，防止改名/搬移绕过的“按文件名扫描”。
- `curriculum/modules/01-foundations/scripts/{build,run,env-report}.sh`
  - `build.sh` 默认编译学员 `starter/BANK-ENTRY.COB`（无 instructor 也能构建）。
  - `run.sh`/`env-report.sh` 默认“有 instructor 用参考，无则用 starter”，
    `COURSE_SOURCE` 仍可覆盖。
- `curriculum/modules/01-foundations/scripts/check.py`
  - 参考实现仅在存在时扫描/断言；RED（starter 未实现必 RC12）仅在公开仓库断言，
    学生包中不再强制 starter 保持失败。
- `curriculum/modules/01-foundations/scripts/check-student-package.py`（新增永久回归，
  由模块 01 `check.sh` 调用）：真实打包→解包→按角色+内容断言无答案泄漏→在隔离包内
  构建/运行模块 01/05/06（完成后源码 RC0 且与 expected 一致；starter 默认 RC12），
  并对 05/06 在隔离包内运行完整 `check.sh`（完成后源码）验证“构建、运行、检查”闭环。

## 3. 原反例现在的结果（修复后，原始 RC）

```sh
bash curriculum/scripts/package-student.sh /tmp/r07-evidence/bundle     # RC 0
grep CUSTV2.COB bundle/MANIFEST.txt
#   curriculum/modules/12-capstone/starter/CUSTV2.COB      （仅 starter；答案已排除）
grep -c /instructor/ bundle/MANIFEST.txt                                 # 0
tar -xzf bundle.tar.gz -C unpack && cd unpack
bash curriculum/modules/01-foundations/scripts/build.sh .../bankentry    # RC 0
bash curriculum/modules/01-foundations/scripts/run.sh .../account.dat red 20261009
#   TODO: implement validated account posted-file entry                  # RC 12（starter RED）
COURSE_SOURCE=.../completed.COB bash .../run.sh .../account.dat out 20261009
#   PASS: account entry counts verified                                   # RC 0 且 control 与 expected 一致
```

| 检查 | 修复前原始 RC | 修复后原始 RC |
|---|---:|---:|
| `package-student.sh` | 0（但含答案） | 0（无答案） |
| 隔离包 `build.sh`（默认） | 12 | 0 |
| 隔离包 `run.sh`（默认 starter） | 12（缺依赖） | 12（按设计的 starter RED） |
| 隔离包 `run.sh`（完成源码） | 12 | 0 |
| 模块 01 `check.sh` | 0（未覆盖打包） | 0（含打包端到端） |

## 4. 独立业务断言与限制

- 答案判定按**任务角色与内容**：内嵌答案用显式角色表 + sha256 内容比对；
  允许既有系统源码（如模块 12 其余 `system/**`）与规范契约继续随包发布。
- 局限：内容比对为“完全相同”级别；对答案做等价改写后再混入包的场景无法自动识破，
  该风险需人工评审，已在此记录。
- 模块 12 README 中“CUSTV2 参考答案”的措辞由模块 12 负责人修改，本证据不改模块 12 文件。

## 5. 交回主代理：其他模块仍需处理（不在本代理文件归属内）

1. **模块 12 运行时依赖被隐藏的答案**：`curriculum/modules/12-capstone/system/lib/
   common.sh:161` 在夜间链中引用 `system/cobol/CUSTV2.COB`，而该文件现已从学生包排除。
   学员实现 `starter/CUSTV2.COB` 后，模块 12 需由负责人决定如何把学员实现接入运行时
   （例如改用 `starter/` 的学员产物），并同步 README 措辞。本代理未改模块 12 任何文件。
2. **其他模块校验清单仍引用已排除的 instructor 文件**（学生包中会缺失/报错），本代理
   仅在 01/05/06 做了“参考存在才断言、否则用学员源码”的加固。其余需返工：
   - 02-data：`scripts/{build,run}.sh`、`check.py`
   - 03-bytes：`scripts/{build,run}.sh`、`check.py`、`generate-fixtures.py`
   - 04-structures：`scripts/{build,run}.sh`、`check.py`
   - 08-database：`scripts/{run}.sh`、`check.{sh,py}`
   - 09-modular：`scripts/{build,run}.sh`（`check.py` 通过 env 传源，但仍依赖 instructor 模块）
   - 10-jobs：`scripts/{build,run}.sh`、`check.py`
   - 11-incidents：`scripts/check.py`
3. **模块 07 复验时未见本代理改动**：`bash curriculum/check.sh` 在模块 07
   `labs/05-large-record` 的 `SHA256SUMS` 处失败（9 项不匹配，属模块 07 负责人在途修改，
   与本代理无关）；模块 01/05/06 及 P1 在本次总入口运行中均 PASS。

