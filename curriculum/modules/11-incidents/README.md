# 模块 11：障害调查与维护（11.1–11.5）

建议 9 小时。先修：模块 06（文件契约）、07（SORT/顺序突合）、10（JOB 运维）。
本模块把“会跑”升级为“会查、会修、会证明”：你接到一套**冻结的银行夜间
系统快照**（`system/`），要在**不篡改原始坏数据、不放宽断言**的前提下，
按事故调查流程定位根因、最小修复、恢复重跑，并完成一次**企业客户区分**
字段的维护变更（先调查后修改；作用于独立、版本化的企业客户布局，绝不
改动 27 字节 CUSTOMER v1 第 27 字节的记录状态）。

> 平台：仅 **Linux x86-64** 实际验证（GnuCOBOL 3.2、Bash 5、GNU
> coreutils、Python 3.13）。macOS/WSL/其他架构**未验证**。
>
> **DB 层说明**：本模块**没有**接入真实 PostgreSQL，JOB004/JOB006 使用
> `system/lib/db.py` 的**离线文件检查点**模拟数据库事务语义与唯一键契约。
> 所有与 DB 相关的证据必须标注“**DB 未验证**”，不得据此声称真实数据库
> 流水线可用。

## 1. 业务为什么需要它 / 你接到什么需求

银行夜间批处理一旦出错，值班人员要**先保留现场、再定位**：从调度器状态、
JOB Log、RC、输入清单建立时间线，区分“没发布”和“发布了错误结果”，找到
根因，做最小修复并证明恢复后数据一致。本模块给你七个**真实可复现**的
事故现场（11.1–11.4），以及一次字段扩展的维护调查（11.5）。

## 2. 输入、来源、格式与已保证前提

被调查系统是 `system/`（冻结快照，源自模块 10 的夜间流，含真实 COBOL
校验器/突合器与离线 DB 检查点）。固定接口（canonical 定义在
`curriculum/bank/copybooks/` 与 `system/copybooks/`）：

- **CUSTOMER v1：27 字节** — id(8)/name(10)/balance_demo(8)/**status**(1，A 有效/D 停用)。
- **ACCOUNT v1：47 字节** — id(10)/customer(8)/currency(3)/sign(1)/balance(13)/
  status(1)/date(8)/version(3)。
- **TRANSACTION v1：55 字节** — account(10)/txid(16)/date(8)/sequence(6)/
  direction(1)/amount(13)/status(1)。

> **记录状态 ≠ 客户区分**：CUSTOMER v1 第 27 字节是**记录状态**（A/D）。
> 11.5 维护课要加宽的“客户区分”**不在**该字节，而在**独立、版本化的企业
> 客户布局** `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`。该练习布局
> **刻意使用独立名称**（不与模块 07 L4 canonical 大记录
> `ENTERPRISE-CUSTOMER-V1`，1778 字节/175 字段同名），避免同名却布局不同的
> 版本漂移；两者共享同一 `CUSTOMER-CLASSIFICATION` 语义。对应 canonical
> 说明见 `curriculum/bank/README.md` 与 `docs/curriculum/BANK-SYSTEM.md` §2。

已保证：ASCII 合成数据、LF 换行、LF 不计入逻辑长度、营业日不默认取机器
日期、每条逻辑记录后一个 LF。短/长记录、非法数字、重复交易号、逆序、
0 字节文件、资源失败、控制总数不符都属**必须被发现**的异常。

## 3. 从干净 checkout 构建、运行、复位

```bash
cd /home/tetsuya/development/cobol

# 正常夜间流（RC0，无拒绝）
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db \
  --business-date 20261009 --run-id demo
echo "rc=$?"     # 预期 0

# 保留失败现场（事故调查用）
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input  curriculum/modules/11-incidents/fixtures/INC-2026-004 \
  --output /tmp/m11-incident --db /tmp/m11-db2 \
  --business-date 20261009 --run-id demo --keep-scene
echo "rc=$?"     # 预期 8

# 状态与复位
bash curriculum/modules/11-incidents/scripts/run.sh \
  --input curriculum/modules/11-incidents/fixtures/normal \
  --output /tmp/m11-night --db /tmp/m11-db --business-date 20261009 \
  --command status
bash curriculum/modules/11-incidents/scripts/reset.sh /tmp/m11-night
```

会覆盖的派生文件：仅 `--output` 目录内内容。**输入夹具、`system/` 源码、
共享 `fixtures/` 与已有输出永不被覆盖**；重复/非课程输出目录以 RC12 拒绝。

## 4. 预期输出、RC、笔数与金额（独立核算）

`.author 工具` 在 `instructor/modules/11-incidents/tools/gen_course.py`，
它**重新实现**冻结契约的业务规则产生 `expected/`，不读取任何课程程序输出。

`normal` 夹具：3 账户（期初 1000 / 50 / 0），4 条交易。

| 指标 | 值 | 来源 |
|---|---:|---|
| 接收 | 4 | 夹具行数 |
| 校验接受 / 拒绝 | 4 / 0 | 业务规则 |
| 突合接受 / 拒绝 | 4 / 0 | `closing = opening + C − D` |
| 账本入账 | 4 | 幂等键 |
| 期初/贷/借/期末总额 | 1050 / 625 / 200 / **1475** | 守恒式 |
| 期末余额 | acc1 1300、acc2 150、acc3 25 | `closing = opening + C − D` |

完整数值见 `expected/normal.control.txt` 与 `expected/normal.closing.txt`；
事故的期望行为见 `expected/incidents.txt`；客户**状态**抽取见
`expected/customer-v1.txt`，企业客户**区分** v1/v2 抽取见
`expected/enterprise-class-v1.txt` / `enterprise-class-v2.txt`。

RC 约定：`0` 正常；`4` 契约允许的 Warning（逐笔业务拒绝）；`8` 业务/契约
异常；`12` 系统异常。**步骤失败一律不发布**（`publish/<run_id>` 不生成）。

## 5. 需要修改哪里、哪些接口不能破坏

- 七个事故以**中性事件 ID** 命名（`INC-2026-001`…`INC-2026-007`），各在
  `INC-2026-00X/`：先按 `INC-2026-00X/student/README.md` 调查。根因、
  最小修复与「事件 ID ↔ 讲师编号」映射见讲师包
  `instructor/modules/11-incidents/INSTRUCTOR.md`（仅教师/按需提示）。
- 维护变更在 `maintenance/`：先交**影響調査書**等五份交付，评审后再实现
  （作用于独立、版本化的企业客户布局，参考实现与证据在
  `instructor/modules/11-incidents/maintenance/`，起始骨架
  `starter/M11CUST2.COB`）。
- **不能破坏**：三种冻结记录宽度与偏移（CUSTOMER v1 第 27 字节始终是
  记录状态 A/D）；`work/`、`publish/` 目录契约；`control.txt` 的键；
  RC 0/4/8/12 语义；幂等账本键 `(business_date, transaction_id)`；
  `STATUS|<id>|<status>` 下游行格式。

## 6. 七个可复现故障（中性事件 ID，仅给症状，根因见讲师包）

事件 ID 与目录名是中性编号，**不披露根因**；每包只提供现象、时间线、
日志与既存系统源码，由学员自行定位。根因、分级提示与讲师编号的对应见
`instructor/modules/11-incidents/INSTRUCTOR.md`。

| 事件 | 目录 | 现象（仅症状，不含根因） | 原始 RC |
|---|---|---|---:|
| 事件 001 | `INC-2026-001/` | 校验节点中止，当日无发布 | 8 |
| 事件 002 | `INC-2026-002/` | 批次成功却发布了与业务台账不符的余额 | 0（缺陷） |
| 事件 003 | `INC-2026-003/` | 接收节点中止，无发布 | 12 |
| 事件 004 | `INC-2026-004/` | 突合节点中止，候选未生成 | 8 |
| 事件 005 | `INC-2026-005/` | 排序节点中止，无发布 | 12 |
| 事件 006 | `INC-2026-006/` | 批次成功但控制总数与上游声明不符 | 0（缺陷） |
| 事件 007 | `INC-2026-007/` | 校验节点中止，当日无发布 | 8 |

每个包**仅凭自身 student/ 目录**即可复现（`student/run.sh`），并附
调度器状态、JOB Log、Shell/源码、Copybook、原始输入、参数/Manifest、
DB 种子或 SQL Log。事故调查交付顺序：**现象与影响范围 → 时间线 →
假设与证据 → 最小复现 → 根因 → 修复/回滚 → 恢复与重跑 → 防再发**。

## 7. 插件操作与纯终端替代

- 插件：用 `gd`/`:CobolGotoDef` 跳段落、`K`/`:CobolPreview` 预览 Copybook、
  Aerial 大纲浏览 `system/`，保存 COBOL 时用诊断确认 72 列/Area A/B。
- 纯终端替代（插件缺失也能完成）：
  ```bash
  rg -n 'WS-STRUCT|out of order|ledger_index|declared' \
     curriculum/modules/11-incidents/system
  od -An -tc curriculum/modules/11-incidents/fixtures/normal/transaction.dat
  sort -c -k1.1,1.10 curriculum/modules/11-incidents/fixtures/INC-2026-004/account_seed.dat
  ```

## 8. 需要交什么证据、什么算失败

按 [evidence/README.md](evidence/README.md) 提交：每个事件的复现命令、
原始 RC、时间线、根因、最小修复、恢复/重跑；维护变更的五份交付与回归。

判为**失败**的情形：把 RC0 当业务正确；用篡改原始输入或放宽断言“修复”
事故；失败却产生正式发布；把系统失败写成业务拒绝；声称真实 DB 已验证；
维护未先调查即修改 PIC；覆盖/改写 V1 原始文件。

验收自检：

```bash
bash curriculum/modules/11-incidents/scripts/check.sh
```

（讲师维护参考自检仅存在于讲师仓，不随学生包发布：
`instructor/modules/11-incidents/maintenance/check.sh`。）

讲师根因、参考实现与 RED→GREEN 记录见
`instructor/modules/11-incidents/INSTRUCTOR.md`。
