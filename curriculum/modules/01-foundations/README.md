# 01 COBOL 与 Legacy 系统（3 小时）

建议工时 3 小时（含阅读、实验、证据整理）。先修：会用终端、能编辑文本、理解变量/条件/循环。
无需大型机或数据库经验。平台仅 Linux x86-64 已实际验证；macOS/WSL/ARM 未验证。

## 1. 业务背景：银行为什么需要夜间批处理

这家模拟银行白天通过**联机（online）**渠道受理客户请求，逐笔立即可见；到晚上则运行
**夜间 Batch（批量）**，在营业日结束时集中处理当日定格的输入，产出次日期初、拒绝明细、
异常清单和下游文件。联机强调**低延迟、单笔**；Batch 强调**可重放、可对账、单次跑一批**。

学员接到的任务：作为刚接手这套 Legacy 的维护开发者，先建立环境与全局认识，能回答
“这是程序还是 JOB”“输入从哪来、输出到哪去”“一个 JOB 失败时发生什么”，并亲手编译、
运行、定位一次失败的构建。本模块产出**环境证据**、**最小银行批处理入口**和**源码到执行
文件的关系图**，供后续模块在真实账户/交易数据上继续扩展。

关键区分（本模块必须能口头解释）：

- **Program（程序）**：一个可编译、可执行的 COBOL 单元，负责一段明确的数据处理。
- **JOB（作业）**：把参数、输入快照、工作目录、锁、校验、发布、日志、返回码组合起来的
  运行编排。本模块用 `scripts/run.sh` 扮演 JOB，用 `BANK-ENTRY.COB` 扮演 Program。
- **营业日（business date）**：由参数显式给出，禁止默认使用机器当前日期。
- **RC 0/4/8/12**：本课程约定 0 正常、4 允许的业务 Warning、8 业务/契约异常、12 系统异常。

初始系统图（后续模块会逐步展开）：

```mermaid
flowchart LR
  ONL[联机交易] --> TX[交易输入]
  TX --> J001[JOB001 接收与校验]
  J001 --> J002[JOB002 校验与清洗]
  J002 --> J005[JOB005 突合/入账]
  J005 --> J008[JOB008 发布下游文件]
  J008 --> RPT[日报/拒绝明细]
```

## 2. 输入从哪来、格式是什么、哪些前提已保证

输入是 `ACCOUNT v1`（与
[银行系统设计](../../../docs/curriculum/BANK-SYSTEM.md) 第 2 节一致的**冻结接口**），
**47 字节/条**、ASCII、每条后跟 `LF`，`LF` 不计入记录长度。字段偏移、编码、合法值见
[DESIGN](DESIGN.md)。营业日由 JOB 参数给出（本模块默认 `20261009`）。前提：上游保证只
投放本营业日的账户快照；长度、字符集、排序仍需本 JOB 自行验证，不能默认信任。

## 3. 从干净 checkout 构建、运行、复位

需要 Linux x86-64、GnuCOBOL 3.2、Bash、coreutils、Python 3（仅验收驱动）。参考实现位于
`instructor/modules/01-foundations/`，`starter/` 可编译但未实现（返回 RC12）。所有输出写入
**新的**输出目录；不覆盖输入或既有输出。

> **学生包（无 `instructor/`）行为**：公开仓库含参考实现，`run.sh` 默认编译它，因此下面
> 的 `normal` 例子返回 RC0。用 `package-student.sh` 生成的学员包**不含** `instructor/`，
> 此时 `run.sh`/`build.sh` 默认编译你自己的 `starter/BANK-ENTRY.COB`：`build.sh` 仍 RC0
> （starter 可编译），`run.sh` 在你补全 TODO 前按设计返回 RC12 且不发布。想验证任意其它
> 源码（例如你自己另存的完成版）时设置 `COURSE_SOURCE=/path/to/BANK-ENTRY.COB`。

```bash
lab=curriculum/modules/01-foundations
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" /tmp/bank-m01-run 20261009
rc=$?
set -e
test "$rc" -eq 0
diff -u "$lab/expected/normal.control.txt" /tmp/bank-m01-run/control.txt
bash "$lab/scripts/check.sh"            # 全部契约端到端验收
```

```bash
bash "$lab/scripts/build.sh" /tmp/bankentry   # 只编译练习
bash "$lab/scripts/env-report.sh"             # 环境与源码→可执行关系证据
bash "$lab/scripts/reset.sh" /tmp/bank-m01-run # 复位（仅接受带标记的输出目录）
```

执行会覆盖的**派生文件**：新输出目录下的 `control.txt`、`accepted.dat`、`rejected.dat`、
`inputs.sha256`、`outputs.sha256`、`run.txt`、`compiler.txt`、`source.sha256`。源夹具与
`expected/` 永不被修改。`reset.sh` 只删除含 `run.txt/inputs.sha256/outputs.sha256/control.txt`
标记、且不在仓库路径内的目录。

## 4. 预期输出、RC、笔数，以及如何独立核算

`control.txt` 是固定宽度样本（计数为 12 位定宽，与 07 模块一致）：

```text
JOB|BANK-ENTRY|V1
BUSINESS-DATE|20261009
CONTROL|READ=000000000003|ACCEPTED=000000000003|REJECTED=000000000000
```

| 夹具 | RC | READ | ACCEPTED | REJECTED | 含义 |
|---:|---:|---:|---:|---:|---|
| normal | 0 | 3 | 3 | 0 | A/F/C 全部合法 |
| empty | 0 | 0 | 0 | 0 | 空文件按契约允许 |
| single | 0 | 1 | 1 | 0 | 最后一条记录 |
| unknown-status | 4 | 1 | 0 | 1 | 状态 Z 逐条拒绝，仍发布 |
| 9 个结构夹具 | 8 | — | — | — | 长度/LF/CR/账号/布局/日期/排序；不发布 |

预期由 ACCOUNT v1 契约人工核算，**不是**程序输出的复制，核算过程见
[expected/README.md](expected/README.md)。`check.py` 逐字节比对控制报告，并从原始夹具独立
推导 `accepted.dat`/`rejected.dat`；运行器内部的 `verify-publish.py` 也独立重算一次，
两者不一致即失败。

> 本模块是“环境与入口”基础，**不做金额算术**（金额语义从模块 02 的 `balance_demo` 起引入，
> 账户余额从账户模型起引入），因此控制报告只有读取/接收/拒绝笔数守恒，没有金额列；
> 金额守恒从模块 07 的入账突破开始验收。

## 5. 要修改哪里、哪些接口不能破坏

入口代码在 `starter/BANK-ENTRY.COB`（TODO 见文件内注释）；参考实现在
`instructor/modules/01-foundations/BANK-ENTRY.COB`（仅公开仓库有；学员包中不存在）。
用 `COURSE_SOURCE` 指向你自己的完成版即可让 `run.sh`/`check.sh` 验收它。**不能破坏**的接口：

- ACCOUNT v1 的 47 字节布局与字段偏移（本模块只读，不重定义）；
- `control.txt` 的行格式与 12 位定宽计数；
- 运行器的命令行契约 `run.sh INPUT NEW_OUTPUT YYYYMMDD` 与 RC 约定。

## 6. 故意破坏哪些条件，如何调查与恢复

每个课次至少一个可复现故障：

- **01.1 错误营业日**：`bash scripts/run.sh fixtures/boundary/empty.dat /tmp/x 20260230`
  → JOB 校验营业日（`TEST-DATE-YYYYMMDD`）失败，RC8、无输出。调查：确认是“日期格式/日历”
  还是“记录日期与营业日不一致”两类不同错误。
- **01.2 构建失败**：`experiments/build-failure/BROKEN-PERFORM.COB`（未定义段落）与
  `BROKEN-AREA.COB`（语句起于 Area A）。`cobc -fsyntax-only` 返回非 0，用编译器给出的
  行号/列号定位。
- **01.3 列截断**：`experiments/columns/TRUNC-BAD.COB.src` 中 `COMPUTE` 行第 73 列有一个
  数字，被编译器静默忽略，`111110` 变成 `11111`，结果由 `111111` 变为 `11112`。恢复见
  `TRUNC-GOOD.COB`（把字面量放进 12–72 列）。

调查原则：先保留原始夹具与原始 RC，再从编译器/运行器诊断定位，最后用最小修复验证；
不得通过修改夹具或放宽断言“修复”。

## 7. 插件路径与纯终端替代

- **插件路径**：用固定格式标尺确认第 7/8/12/72 列；把光标放在源码任意行，观察 Winbar
  的 Area A/B 提示与第 72 列越界红色波浪线；用 `:CobolGotoDef` 跳到 `PERFORM` 目标段落。
  对 `COPY` 行用 `:CobolGotoCopybook` 打开 canonical 接口。
- **终端替代**：`awk '{print NR, length($0)}' 文件` 检查是否越过 72 列；
  `rg -n 'PERFORM|DIVISION|SECTION' 文件` 查看结构；`cobc -fsyntax-only 文件` 触发诊断。
  插件估算不得作为字节布局的最终依据。

## 8. 完成需要交什么证据，何种结果算失败

按 [evidence/README.md](evidence/README.md) 模板提交：环境证据（`cobc -V`、`uname`、
`file`/`ldd` 输出）、normal/empty/single/unknown-status 的运行命令与原始 RC、control 报告、
一个 RC8 无发布证据、列截断前后结果、输入 SHA256。**失败判据**：`check.py` 或
`verify-publish.py` 与断言不符；RC8 夹具产生了输出目录；源夹具 SHA256 变化；把程序当前
输出当作 expected。

## 课次任务与插件/终端对照

### 课次 01.1 业务日、联机 vs 夜间 Batch、Program vs JOB

- 阅读并复述系统图；说明营业日为何必须显式传入（运行 `env-report.sh` 后观察 `run.txt` 里的
  `business_date`）。
- **动手修改练习**：把 `run.sh` 的营业日改为 `20240229`（闰日）与 `20260230`（非法日），
  预测并核对 RC。
- **可复现故障**：省略第三个参数 → 用法错误 RC12；给出非法日历日期 → RC8。
- **插件/终端**：插件用 Winbar 显示当前段落；终端用 `sed -n` 查看 `run.txt`。

### 课次 01.2 GNUCOBOL 编译/链接/运行时/构建目录

- 运行 `env-report.sh`，画出 `BANK-ENTRY.COB → cobc → C → cc → bankentry(ELF) → libcob` 的
  关系图（见 [DESIGN](DESIGN.md)）。
- **动手修改练习**：编译 `starter/BANK-ENTRY.COB`，让它先返回 RC12；再补全 TODO 使 normal
  通过（对照 `instructor` 参考实现）。
- **可复现故障**：分别编译 `experiments/build-failure/BROKEN-PERFORM.COB` 和
  `BROKEN-AREA.COB`，从诊断定位失败行并解释原因。
- **插件/终端**：插件用诊断波浪线；终端用 `cobc -fsyntax-only`。

### 课次 01.3 DIVISION/SECTION/Paragraph、句点与范围；固定/自由格式

- 在参考源码中圈出四个 DIVISION、`1000-MAIN` 段落与各段落的句点边界。
- **动手修改练习**：对比 `experiments/columns/FIXED.COB` 与 `FREE.COB`（同逻辑、两种格式），
  确认输出一致；再把 `TRUNC-BAD.COB.src` 复制为 `.COB` 编译运行，解释为何结果是 `11112`，
  然后用 `TRUNC-GOOD.COB` 修复为 `111111`。
- **可复现故障**：故意让某行越过第 72 列，观察编译器静默截断（无报错但结果错误）。
- **插件/终端**：插件用标尺与越界告警；终端用 `awk` 统计列宽、`cobc` 编译验证。

参考实现与根因、提示阶梯、评分说明见 `instructor/modules/01-foundations/`。
