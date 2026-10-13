# 模块 04 作者执行记录（2026-10-10）

环境：Linux x86_64；`cobc (GnuCOBOL) 3.2.0`，默认方言。
命令在仓库根 `/home/tetsuya/development/cobol` 执行；Copybook 只读复用
`instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY`
（sha256 `3cf66e93…b5b98`）。

## 1. RED（学员 starter 必须失败且不发布）

    COURSE_SOURCE=curriculum/modules/04-structures/starter/M04ENTERPRISE.COB \
      bash curriculum/modules/04-structures/scripts/run.sh 04.3 /tmp/ev-m04-starter \
      curriculum/modules/04-structures/fixtures/normal/enterprise-2.dat

原始 RC = **12**；输出目录不存在（零发布）。

## 2. GREEN（讲师参考实现）

    bash curriculum/modules/04-structures/scripts/check.sh

RC = **0**，输出 `PASS: module 04 structures, COPY shift, 175-field measured layout`。
该检查同时：
- 用 GnuCOBOL `ADDRESS OF` 逐字段测量 175 个叶子偏移，与 `FIELD-CATALOG.csv` 全部一致
  （记录 1,778B）；
- 用 COPY REPLACING 生成 V2，测得 `LENGTH OF` 1,778→1,779；
  `SYNC-STATE` 偏移 1778→1779（+1），`CUSTOMER-CLASSIFICATION` 偏移两版同为 460；
- 生成 `evidence/M04-layout-author.json`。

## 3. 可复现编译故障

    cobc -fsyntax-only curriculum/modules/04-structures/faults/odo-not-last.COB
    # error: 'BAD-ITEM' cannot have OCCURS DEPENDING because of 'BAD-TRAILER'
    cobc -fsyntax-only curriculum/modules/04-structures/faults/redefines-not-adjacent.COB
    # error: REDEFINES 句は参照元の項目の直後になければなりません

两者 RC ≠ 0，由 `check.py` 断言。

## 4. 结构错误 → RC8 零发布

    bash .../run.sh 04.3 /tmp/out \
      curriculum/modules/04-structures/fixtures/invalid/enterprise-bad-length.dat
    # RC 8；/tmp/out 不存在

同类：版本 `009`、ABI `BADABI`、非数字 `CUSTOMER-ID` 均 RC8 零发布。

## 5. 手算与实测对照（摘录）

| 项 | 手算 | `ADDRESS OF`/`LENGTH OF` 实测 |
|---|---|---|
| 记录长度 | 1,778 | 1,778 |
| CUSTOMER-CLASSIFICATION 偏移 | 460 | 460 |
| SYNC-STATE 偏移 (V1) | 1,778 | 1,778 |
| 加宽后 SYNC-STATE 偏移 (V2) | 1,779 | 1,779 |
| ODO count=3 长度 | 17 | 17 |
| ODO count=7 长度 | 37 | 37 |

## 限制

- 仅 Linux x86-64 / GnuCOBOL 3.2 实测；ODO 的 `LENGTH OF` 行为需换编译器重测。
- 04.3 只做结构/长度/版本/键校验，不做 07.6 的全字段业务域比较。
- 运行期 libxml 警告为环境噪声，记入 `stderr.txt`。
