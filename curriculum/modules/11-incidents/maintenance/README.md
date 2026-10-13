# 维护变更 11.5：企业客户区分 1 位 → 2 位（学员任务）

> 这是 LEGACY 维护变更的**调查阶段**。先交影响调查，评审通过后再实现
> 修改与迁移/回滚。**禁止先改 PIC 再补调查**。
> 接口变更规格见 [LAYOUT-V1-V2.md](LAYOUT-V1-V2.md)。

## 1. 需求

上游业务要把**企业客户主档**的客户区分（classification）由 **1 位**扩展
为 **2 位**。该区分位于**独立、版本化的企业客户布局**，**不是** 27 字节
canonical CUSTOMER v1 的第 27 字节（那里是记录状态 A/D，教学接口保持不动）：

- V1：`CUSTOMER-CLASSIFICATION PIC X(1)`，值 `A/B/C/D`，布局版本 `001`，
  记录宽 **23 字节**（基线契约）。
- V2：`CUSTOMER-CLASSIFICATION PIC X(2)`，值 `A1/B1/C1/D1`，布局版本
  `002`，记录宽 **24 字节**。
- **旧 V1 文件不得原地改写**；必须走迁移 + 并行验证 + 可回滚。

> 为什么不能用 CUSTOMER v1 第 27 字节：canonical 约定该字节是**记录状态**
> （A 有效 / D 停用）。把它当“客户区分”会破坏冻结契约。参见
> `curriculum/bank/README.md`、`docs/curriculum/BANK-SYSTEM.md` §2。课程
> canonical 的大记录是模块 07 L4 的 `ENTERPRISE-CUSTOMER-V1`（175 字段 /
> 1778 字节）；本练习的 23 字节布局**改用独立名称** `ENTERPRISE-CLASS-V1`
> （见其 Copybook 头注），只保留同一分类字段语义，**不与 canonical 同名**，
> 以免版本漂移。

## 2. 你手上的系统

被调查系统是模块 11 的冻结快照 `system/`，企业客户区分出现在**独立的
版本化企业布局**与其读取/迁移链路上：

- 基线 Copybook：`maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`
  （布局 `001`，23 字节：version/id/status/name/classification）。
- 读取并输出区分的参考程序：
  `instructor/modules/11-incidents/maintenance/M11CUST2.COB`（V2，24 字节）。
- 迁移/回滚/并行验证工具：
  `instructor/modules/11-incidents/maintenance/migrate-customer.py`。
- 输入：`fixtures/enterprise-customer/customer.v1`（V1，23 字节）。
- 下游接口（企业区分抽取）：行格式 `CLASS|<id>|<class>`（1→2 字符）。
- **注意**：夜间流里的 `system/cobol/M11CUST.COB` 读的是 canonical
  CUSTOMER v1 的**记录状态**，下游发布物是 `publish/<run_id>/customer-status.txt`
  （`STATUS|<id>|<status>`）；它与企业区分是**两回事**，不要改它。
- 文档：仓库根 `docs/curriculum/BANK-SYSTEM.md`（冻结契约）、
  `docs/curriculum/AUTHORING-STANDARD.md` §6（变更交付要求）。

## 3. 交付物（评审前）

1. **影響調査書**（必含）：
   - 字段定义：字段名、PIC、字节偏移、长度、合法值、版本；
   - **所有使用位置**：Copybook、程序、排序/比较键、文件、DB、Shell、
     JOB、报表、下游接口（逐项给文件路径与行号）；
   - **依赖图**：谁读谁写、上下游方向；
   - **未知项**：不确定或未验证的部分（如真实 DB 列定义、外部消费方）。
2. **修正対象一覧**：Copybook／程序／文件／DB／Shell／JOB／设计书／
   下游接口／负责人角色，逐项列出“改什么、为什么、风险”。
3. **修正方針**：V1/V2 兼容策略；迁移步骤；回滚步骤；数据切换与
   并行验证方案（V1/V2 对照）。
4. **Test Case**：正常、边界、异常、跨版本、全流程、恢复，每项给
   `输入 → 期望 RC/输出 → 证据位置`。
5. **Evidence 计划**：每个测试的期望与证据存放位置。

> 交付物以 markdown 提交；可在本目录下自建 `TEMPLATES/` 放入表格骨架。
> 评审后（实现阶段）参考实现与证据在
> `instructor/modules/11-incidents/maintenance/`。

## 4. 评审后（实现阶段）参考

实现要求：新增/实现 `ENTERPRISE-CLASS-V2`（24 字节，`X(2)`）、更新读取
程序与下游接口格式、提供迁移与回滚工具、并行验证 V1/V2 结果、全流程回归
与恢复验证。**CUSTOMER v1（27 字节）保持不动**。参考实现与证据在
`instructor/modules/11-incidents/maintenance/`，起始骨架在
`starter/M11CUST2.COB`（可构建，未完成时返回 RC12）。

## 5. 运行现有实现与回归（调查可用的只读证据）

> 迁移/回滚工具是 **Python 脚本**（`migrate-customer.py`，shebang
> `#!/usr/bin/env python3`）。必须用 `python3` 或直接执行脚本，**不能用
> `bash` 执行**（bash 会把 Python 源码当 shell 报语法错误）。以下命令从
> 仓库根执行，路径均为仓库相对路径。

```bash
cd /home/tetsuya/development/cobol   # 仓库根
mod=curriculum/modules/11-incidents
ins=instructor/modules/11-incidents

# 迁移 V1 -> V2（python3；写新文件，不改原 V1）
python3 "$ins/maintenance/migrate-customer.py" \
  to-v2 "$mod/fixtures/enterprise-customer/customer.v1" /tmp/ent.v2
cat /tmp/ent.v2                      # 00200000001AALICE     A1 ...

# 构建并运行参考 v2 抽取器
rm -f /tmp/m11cust2
bash "$mod/system/scripts/build.sh" /tmp/m11cust2 "$ins/maintenance/M11CUST2.COB"
M11CUST_INPUT=/tmp/ent.v2 M11CUST_EXTRACT=/tmp/class.v2 \
M11CUST_REPORT=/tmp/rep.v2 /tmp/m11cust2 && cat /tmp/class.v2
# CLASS|00000001|A1 ...

# canonical CUSTOMER v1 状态抽取（回归：不受本变更影响）
rm -f /tmp/m11cust
bash "$mod/system/scripts/build.sh" /tmp/m11cust "$mod/system/cobol/M11CUST.COB"
M11CUST_INPUT="$mod/fixtures/normal/customer_seed.dat" \
M11CUST_EXTRACT=/tmp/status.v1 M11CUST_REPORT=/tmp/rep.v1 /tmp/m11cust
cat /tmp/status.v1          # STATUS|00000001|A ...

# 参考实现的维护自检（迁移/回滚/并行/跨版本/异常/偏移与黄金字节）
bash "$ins/maintenance/check.sh"
```

## 6. 必须回答（AUTHORING §6）

- 字段定义、所有使用位置、依赖图、未知项各是什么？
- 改一个字段宽度会移动哪些后续字段/偏移？对排序键与比较有何影响？
- V1 文件如何处理（拒绝/转换）？为什么不能原地改写？
- 迁移、切换、回滚分别怎么做？并行验证怎么证明等价？
- CUSTOMER v1 第 27 字节与本企业区分是什么关系？为什么不能混用？
- 覆盖了哪些外部接口与下游？未验证项如何标注？
