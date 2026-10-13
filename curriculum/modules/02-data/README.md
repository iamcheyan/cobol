# 02 数据定义与客户 Record（4 小时）

建议工时 4 小时。先修：模块 01（环境、编译、固定格式列规则）。平台仅 Linux x86-64 已实际
验证；macOS/WSL/ARM 未验证。

## 1. 业务背景：客户主数据为什么要单独建模

银行夜间流程要处理账户与交易，但在那之前必须先有一套可信的**客户主数据**：谁在系统里、
叫什么、当前是有效还是停用。账户与交易都引用客户 ID。学员接到的任务：为 CUSTOMER v1
建立**字段目录与契约**，写一个能校验客户文件、按业务规则拒绝坏记录、并核对总额的最小
装载程序；同时用一个小实验说清 `PIC` 逻辑位数与实际存储字节、隐式小数、`MOVE` 类别转换
和截断补齐。这是后续账户模型（ACCOUNT v1）与 JOB 的上游基础。

## 2. 输入从哪来、格式是什么、哪些前提已保证

输入是 `CUSTOMER v1`（**冻结契约，27 字节/条**），来源与
[银行系统设计](../../../docs/curriculum/BANK-SYSTEM.md) 第 2 节一致，本模块提供实物
Copybook [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY)。文件为 ASCII、LF 终止，
`LF` 不计入记录长度；名称先限制 ASCII，避免把字符数误当字节数。前提：上游只投放当日客户
快照；长度、字符、排序、必填仍需本 JOB 独立验证。

> 关于“区分”：CUSTOMER v1 的 27 字节里，第 27 字节只有 `customer_status`（`A`/`D`），它是
> **状态，不是客户区分**；v1 布局内**没有**客户区分字段。BANK-SYSTEM 的“客户区分”是客户 DB
> 属性，模块 11 的“1 位扩 2 位”维护**不得**改写这第 27 字节，必须先定义独立、版本化的企业客户
> 布局（复用或对齐模块 07 L4 的 `ENTERPRISE-CUSTOMER-V1`，见
> [curriculum/bank/README.md](../../bank/README.md)），保留 27 字节教学接口并要求讲清两者关系后
> 再做 v2 迁移。`balance_demo` 是本模块的实验金额（单位分、无符号），**不是**最终账本；进入
> 账户模型后余额移入 ACCOUNT v1（47 字节），迁移原因与步骤见 [DESIGN](DESIGN.md)。

## 3. 从干净 checkout 构建、运行、复位

需要 Linux x86-64、GnuCOBOL 3.2、Bash、coreutils、Python 3（仅验收驱动）。参考实现位于
`instructor/modules/02-data/`，`starter/` 可编译但未实现（RC12）。所有输出写入**新**输出目录。

```bash
lab=curriculum/modules/02-data
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/customer.dat" /tmp/bank-m02-run
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m02-run/control.txt
bash "$lab/scripts/check.sh"     # 全部契约端到端验收（含 MOVE/类型/布局实验）
```

```bash
bash "$lab/scripts/build.sh" /tmp/custload     # 只编译练习
bash "$lab/scripts/reset.sh" /tmp/bank-m02-run # 复位（仅接受带标记的输出目录）
```

执行会覆盖的**派生文件**：新输出目录下的 `control.txt`、`accepted.dat`、`rejected.dat`、
`inputs.sha256`、`outputs.sha256`、`run.txt`、`compiler.txt`、`source.sha256`。源夹具与
`expected/` 永不被修改。

## 4. 预期输出、RC、笔数、金额与独立核算

`control.txt`（计数 12 位定宽、余额合计 18 位定宽）：

```text
JOB|CUSTLOAD|V1
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000|BALANCE-TOTAL=000000000010012394
```

| 夹具 | RC | READ | ACCEPTED | REJECTED | 余额合计 | 含义 |
|---:|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | 10012394 | 全部合法 |
| empty | 0 | 0 | 0 | 0 | 0 | 空文件按契约允许 |
| single | 0 | 1 | 1 | 0 | 500 | 最后一条 |
| max-balance | 0 | 1 | 1 | 0 | 99999999 | 8 位上限 |
| name-full | 0 | 1 | 1 | 0 | 1000 | 名称正好 10 字符 |
| name-missing | 4 | 1 | 0 | 1 | 0 | 名称全空格 |
| bad-amount | 4 | 1 | 0 | 1 | 0 | 余额含非数字 |
| unknown-status | 4 | 1 | 0 | 1 | 0 | 状态非 A/D |
| 7 个结构夹具 | 8 | — | — | — | — | 长度/LF/CR/ID/排序；不发布 |

独立核算见 [expected/README.md](expected/README.md)。`check.py` 逐字节比对控制报告并从原始
夹具独立推导 `accepted.dat`/`rejected.dat`；运行器内部 `verify-publish.py` 再独立重算一次。

## 5. 要修改哪里、哪些接口不能破坏

入口在 `starter/CUSTLOAD.COB`（TODO 见文件内注释）；参考实现在
`instructor/modules/02-data/CUSTLOAD.COB`。**不能破坏**：CUSTOMER v1 的 27 字节布局与字段
偏移、`control.txt` 行格式与 12/18 位定宽、运行器契约 `run.sh INPUT NEW_OUTPUT` 与 RC 约定。

## 6. 故意破坏哪些条件，如何调查与恢复

- **02.1 位/字节误解**：把 `customer_id` 当成数字 `PIC 9(8)` 处理并尝试 `COMPUTE`，或把
  10 字符名称当成 10 字节以外的东西；用 `prefix LENGTH OF` 观察真实字节数。可复制
  `CUSTOMER-V1.CPY` 改动一个 `PIC` 后重编，看长度如何变化。
- **02.2 MOVE 截断/补齐/类别转换**：运行 `experiments/move/MOVELAB.COB`（见第 7 节），把
  `MOVE 12345 TO WS-T1 (PIC 9(3))` 的结果 `345` 与预期核对；把 `12345.67` 移入 `9(3)V99`
  得到 `345.67`，解释高位截断与隐式小数。
- **02.3 偏移错误**：编译 `experiments/layout/LENGTH-PROBE.COB`，先用
  `copybooks/` 得到 `CUSTOMER-RECORD=27`，再换成 `experiments/layout/`（名称被**故意错写**成
  `X(11)`）得到 `CUSTOMER-RECORD=28`、`NAME-LENGTH=11`。这是一个**错误布局演示/非契约**：
  它证明改一个 `PIC` 会移动其后所有字段偏移，因此任何真实布局变更都必须先做影响调查、版本化
  并保留旧接口；它**不是** CUSTOMER v1 的 27→28 迁移。恢复即改回 `X(10)`。

调查原则：保留原始夹具与原始 RC，先看 `FILE-STATUS`/长度诊断，再定位字段偏移；不得通过放宽
断言“修复”。

## 7. 插件路径与纯终端替代

- **插件路径**：用 `:CobolGotoCopybook` 打开 `COPY "CUSTOMER-V1.CPY"` 的 canonical 接口；用
  Aerial/大纲查看 01/05 级层级；用 PIC 字节提示核对 `PIC X(10)`=10B、`PIC 9(8)`=8B。
- **终端替代**：`awk '{print length($0)}'` 检查记录宽度；`od -An -tc` 确认 LF；`cobc` 编译
  `MOVELAB.COB` 得到 MOVE 实验表；`rg -n 'PIC|COPY|VALUE|88|77' 文件` 查看数据声明。插件
  估算不得作为字节布局的最终依据。

## 8. 完成需要交什么证据，何种结果算失败

按 [evidence/README.md](evidence/README.md) 提交：字段目录、normal/边界/异常的运行命令与原始
RC、control 报告、MOVE 实验表与类型实验（`TYPESLAB`）结果（含规则解释）、一个 RC8 无发布证据、
输入 SHA256。**失败判据**：
`check.py` 与断言不符；RC8 夹具产生了输出目录；源夹具 SHA256 变化；把程序当前输出当作
expected；把 CUSTOMER v1 的 27 字节改成别的长度。

## 课次任务与插件/终端对照

### 课次 02.1 PIC X/A/9、01/05/77/78/88、VALUE、分组项与基本项

- 在 [copybooks/CUSTOMER-V1.CPY](copybooks/CUSTOMER-V1.CPY) 与
  `experiments/layout/LENGTH-PROBE.COB` 中识别 `01` 组项与 `05` 基本项。
- **可运行实验**：`experiments/types/TYPESLAB.COB` 读 `fixtures/types/typeinput.dat`，用
  `78 WS-LIMIT` 常量、`77 WS-COUNT`、`88 CLS-ALPHA/CLS-MIXED` 条件名和 `01/05` 组，把
  `PIC X(5)` 与 `PIC A(5)` 并排比较；`check.py` 与 `expected/typeslab.txt` 逐字节比对。
  关键结论：把含数字的 X 数据 `MOVE` 进 `PIC A` **不会**被自动拒绝（记录 2 判为 `M`），必须
  自己用 `IS ALPHABETIC` 校验；而把数值项 `MOVE` 进 `PIC A` 根本编译不过（失败即可复现故障）。
- **动手修改练习**：在 `starter/CUSTLOAD.COB` 中加一个 `77 WS-FLAG PIC X VALUE 'N'.` 和一个
  `88 FLAG-IS-N VALUE 'N'.`，用 `SET FLAG-IS-N TO TRUE` 触发；说明 `VALUE` 只是初值。
- **可复现故障**：把 `customer_id` 误当 `PIC 9(8)` 后，前导零在数值比较中丢失；用
  `LENGTH OF` 与十六进制观察证明真实存储仍是 8 字节 ASCII。
- **插件/终端**：插件看层级与 PIC 提示；终端用 `rg -n 'PIC|VALUE|88|77'`。

### 课次 02.2 S/V、金额范围、隐式小数、MOVE 类别转换、截断与补齐

- 运行 `experiments/move/MOVELAB.COB`（check.py 会与 `expected/movelab.txt` 逐字节比对）。
  A–I 九个案例分别演示：隐式小数 `9(3)V99` 的显示、`MOVE` 到整数 `9(5)` 丢小数、数值→字母
  数字转换、字母数字补齐、带符号前分隔显示、字母数字截断、整数高位截断、`9(3)V99` 的隐式小数。
- **动手修改练习**：新增一个 `PIC S9(5)V99` 的 `-1234.56` 案例并预测输出。
- **可复现故障**：`MOVE 12345 TO PIC 9(3)` → `345`（高位被截断，不是四舍五入）。
- **插件/终端**：插件用 PIC 字节提示；终端直接运行 MOVELAB 与 `od`。

### 课次 02.3 客户 Record v1：ID、姓名、状态与字段目录

- 建立字段目录（见 [DESIGN](DESIGN.md)），说明 `customer_id` 前导零、`customer_name` 右侧
  空格补齐、`balance_demo` 单位分、`customer_status` 的 `A`/`D` 状态含义。CUSTOMER v1
  **没有**客户区分字段，第 27 字节只有状态。
- **动手修改练习**：补全 `starter/CUSTLOAD.COB` 的 TODO，使 normal 通过并保持守恒。
- **可复现故障（非契约演示）**：`experiments/layout/` 中的错误 Copybook 故意把名称错写成
  `X(11)`，让记录变 28 字节；用 `LENGTH-PROBE` 复现并解释单字段 PIC 变化如何移动后续偏移。
  它**不是** v1 契约，也不是 27→28 迁移。
- **插件/终端**：插件 `:CobolGotoCopybook`；终端 `od -An -tc` 与 `LENGTH-PROBE`。

参考实现、根因、提示阶梯与评分见 `instructor/modules/02-data/`。
