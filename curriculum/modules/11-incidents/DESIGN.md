# 模块 11 设计：事故调查框架、冻结快照与维护变更

对应大纲 11.1–11.5。本文件定义被调查系统、事故包结构、证据模型与维护
变更设计。学员任务与验收见 [README](README.md)，讲师根因见
`instructor/modules/11-incidents/`。

## 1. 被调查系统：冻结快照 `system/`

模块 11 携带一套**可独立运行**的银行夜间系统快照，源自模块 10 的
JOB001–JOB009 设计（canonical 源仍为模块 07/10 的参考实现）。快照是
“收到陌生系统”的现场：事故包针对它复现，**不修改模块 01–10 的文件**。

```mermaid
flowchart LR
  J1[JOB001 receive] --> J2[JOB002 validate<br/>M11VAL.COB]
  J2 --> J3[JOB003 sort<br/>system sort + verify]
  J3 --> J4[JOB004 db-snapshot<br/>db.py]
  J4 --> J5[JOB005 match<br/>M11MATCH.COB]
  J5 --> J6[JOB006 db-apply<br/>db.py idempotent]
  J6 --> J7[JOB007 control+cust<br/>control.py + M11CUST.COB]
  J7 --> J8[JOB008 publish<br/>atomic + manifest]
  J8 --> J9[JOB009 complete]
```

| JOB | 输入（只读） | 输出/检查点 | 允许前置 RC | 失败后 |
|---|---|---|---|---|
| 001 | 接收目录 + MANIFEST | `snapshot/`（不可变）+ 校验和 | — | RC8/12 不进入校验 |
| 002 | 快照 + 布局契约 | `work/validate/` | 仅 RC0/4 | 结构错误 RC8，业务拒绝 RC4 |
| 003 | accepted 交易 | `work/sorted_tx.dat` + 有序性证据 | 仅 RC0 | 临时空间/权限 RC12 |
| 004 | 营业日 + DB store | `work/db/` 快照 | 仅 RC0 | 失败 RC12，不用过期数据 |
| 005 | 快照账户 + 有序交易 | `work/closing/`（候选，隔离） | RC0/4 | 逆序/溢出 RC8；候选不发布 |
| 006 | 候选 + 幂等键 | 账本 + commit | RC0/4 | 先查账本，再决定恢复 |
| 007 | 明细/拒绝/账本 + 客户快照 | `work/control/`、`work/customer/` | 仅 RC0 | 不通过 RC8，不能发布 |
| 008 | 已核对候选 | `publish/<run_id>/` + CURRENT | 仅 RC0 | 已提交则只恢复发布 |
| 009 | 完成证据 | `state/complete.marker` | 仅 RC0 | 状态可查，不覆盖原运行 |

RC 语义同模块 10：`0/4/8/12`；非约定子进程码在 Shell 边界映射 RC12。

## 2. 事故包结构（11.1–11.4）

每个 `INC-2026-00X/`：

```text
INC-2026-00X/student/
  README.md            现象与影响范围 → 时间线（不含根因）
  hints.md             逐层提示阶梯
  run.sh               仅凭本包复现（--keep-scene 保留现场）
  input/               原始输入副本（可能含坏数据，未改动）
  scene/
    scheduler-status.txt  调度器 JOB 状态与 RC
    run.env               参数（营业日/run_id/路径）
    MANIFEST              输入清单（含上游声明控制总数时）
    console.txt           调度器控制台所见
    logs/                 JOB Log 与 nightly.log
    source/               Shell、COBOL、Python 源码副本
    copybooks/            v1 冻结接口副本
    db-schema.sql / sql-log.txt / ledger-victim.dat  （涉及 DB 契约的事件）
    published-*.txt/.dat  已发布产物（RC0 缺陷类事件）
```

讲师侧：`instructor/modules/11-incidents/inc-XX/` 保存根因、触发条件、
逐层提示、误导线索、证据、最小修复、恢复/重跑、防再发与评分点；涉及代码
缺陷的事件另存 `fix/` 与 RED→GREEN harness。事件 ID ↔ 讲师编号映射只在
讲师包 `INSTRUCTOR.md`。

## 3. 七类事件与期望行为（触发/根因见讲师包）

事件 ID 中性、不含根因；触发条件与根因仅在讲师包。下表只给
`as_found_rc`/`desired_rc`/`publish_before`/`publish_after` 契约，
记录在 `expected/incidents.txt`。

| 事件 | as-found RC | 期望 RC | as-found 发布 |
|---|---:|---:|---|
| INC-2026-001 | 8 | 8 | 否 |
| INC-2026-002 | 0（缺陷） | 8 | **是（缺陷）** |
| INC-2026-003 | 12 | 12 | 否 |
| INC-2026-004 | 8 | 8 | 否 |
| INC-2026-005 | 12 | 12 | 否 |
| INC-2026-006 | 0（缺陷） | 8 | **是（缺陷）** |
| INC-2026-007 | 8 | 8 | 否 |

代码缺陷类事件的修复由 `instructor/.../tools/red-green.sh` 演示 RED→GREEN。

## 4. 证据与保鲜

- 输入不可变：事故包 `input/` 是原始副本；`run.sh --keep-scene` 保留失败
  `work/` 现场；共享 `fixtures/` 有 `SHA256SUMS`，`check.py` 在运行前后
  比对，**运行不得修改夹具**。
- 修复不篡改坏数据、不放宽断言：代码缺陷类事件的修复是**新增校验**，
  使坏输入以 RC8 阻断，而非“让断言通过”。
- 恢复原则：以幂等账本 / commit / Manifest / 校验和核实事实，绝不凭
  Shell 日志最后一行推断事务状态。

## 5. 维护变更（11.5）设计

需求：把**独立、版本化的企业客户布局** `ENTERPRISE-CLASS` 的客户区分
`CUSTOMER-CLASSIFICATION` 由 `PIC X(1)`→`PIC X(2)`，布局 `001`→`002`，
`A→A1` 等；旧文件不得原地改写。**不得**把该区分寄生到 27 字节 CUSTOMER v1
的第 27 字节（那里是记录状态 A/D）；CUSTOMER v1 保持不变。交付顺序：先
五份调查文档，评审后再实现。

> **命名与关系**：课程 canonical 的大记录是模块 07 L4 的
> `ENTERPRISE-CUSTOMER-V1`（175 字段 / 1778 字节）。本模块的 23 字节练习
> 布局**刻意改用独立名称** `ENTERPRISE-CLASS-V1`，避免与 canonical 同名却
> 布局不同（版本漂移）；两者共享同一分类字段语义（`CUSTOMER-CLASSIFICATION`
> `X(1)`→`X(2)`），本模块只是该语义的精简练习投影。

基线：`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`（布局 001，23B）；
目标：`ENTERPRISE-CLASS-V2`（布局 002，24B）。详尽设计见
`instructor/modules/11-incidents/maintenance/`：
`INFLUENCE-INVESTIGATION.md`（影響調査書）、`CHANGE-LIST.md`（修正対象
一覧）、`CHANGE-PLAN.md`（修正方針）、`TEST-CASES.md`、`EVIDENCE-PLAN.md`，
参考实现 `M11CUST2.COB` + `migrate-customer.py` + `check.sh`。

关键字节能性：分类字段在记录**末尾**，V1→V2 只 +1 字节，之前字段偏移
不变；但记录总长变化影响所有定长读取、校验和与下游切片。

## 6. 复用与边界

- 快照的离线 DB/控制/发布辅助（`db.py`/`control.py`/`manifest.py`/
  `verify_publish.py`/`common.sh`）是模块 10 的**副本**，用于事故现场；
  canonical 仍在模块 10，二者不互相引用，避免漂移。
- 事故材料是**副本**，不改动模块 01–10 的任何文件。
- JCL/JP1 仅阅读映射（模块 10 提供）；本模块不声明任何大型机可运行。
- 平台仅 Linux x86-64；真实 DB **未接入/未验证**，所有 DB 证据标注
  “DB 未验证”。

## 7. 规模

微型：每事故夹具 ≤ 10 行，可人工核算。快照系统约数百行 COBOL + 若干
Shell/Python，复杂度用于“读陌生系统 + 调查”，非靠行数凑规模。
