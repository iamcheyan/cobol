# 模块 01 讲师说明

## 参考实现与结构

- `BANK-ENTRY.COB`：完整入口。逐字节读取（`PIC X(1)` 直到 `X'0A'`），因此长度校验基于
  **原始字节**，不会先 MOVE 进 47 字节字段再判断而掩盖短/长记录。
- 学员入口 `starter/BANK-ENTRY.COB` 可编译，缺实现时 `RETURN-CODE=12`，运行器据此不发布。
- 校验顺序：营业日参数 → OPEN → 逐记录结构校验（长度/字符/布局/日期/币种/符号/金额/排序）
  → 状态业务规则 → 守恒 → 报告。

## 提示阶梯

1. 先让学员区分 Program 与 JOB，指出 `run.sh` 才是 JOB（参数、锁、快照、发布）。
2. 长度校验必须在读原始字节时进行；指出 `LINE SEQUENTIAL` 直接读进定长字段会静默补齐/截断。
3. 让学员手算 normal 的 READ/ACCEPTED/REJECTED，再与 `expected/normal.control.txt` 比对。
4. 强调第 73-80 列被编译器彻底忽略；`TRUNC-BAD.COB.src` 的第 73 列数字是静默错误的来源。
5. 若 RC 与预期不符，先看 `run.txt` 的营业日、再看 `FILE-STATUS` 诊断，最后才怀疑业务逻辑。

## 根因与触发

| 夹具/实验 | 根因 | 预期 |
|---|---|---|
| boundary/no-final-lf | 末条记录缺 LF，EOF 时缓冲非空 | RC8 无发布 |
| invalid/short、long | 原始字节长度 ≠47 | RC8 无发布 |
| invalid/crlf | 记录含 CR | RC8 无发布 |
| invalid/bad-id | 账号含非数字 | RC8 无发布 |
| invalid/bad-layout | 布局 ≠001 | RC8 无发布 |
| invalid/bad-date | 记录日期 ≠营业日 | RC8 无发布 |
| invalid/duplicate-id、unsorted | 账号非严格升序/重复键 | RC8 无发布 |
| invalid/unknown-status | 状态 ∉{A,F,C} | RC4 发布拒绝 |
| BROKEN-PERFORM | `PERFORM` 目标段落未定义 | `cobc` 非 0，定位到行 |
| BROKEN-AREA | 语句起于 Area A | `cobc` 非 0，指标符列错误 |
| TRUNC-BAD | 第 73 列数字被忽略，`111110`→`11111` | 结果 `11112`（预期 `111111`） |

## 关键审查点

- 长度/字符/排序校验必须基于原始字节，不能用定长字段的补齐结果冒充。
- RC8 必须**整批失败且不产生输出目录**；不得把契约错误降级为逐条拒绝。
- `run.sh` 的锁、暂存目录、`mv -T -n` 发布与 `verify-publish.py` 独立重算不可省略。
- 12 位定宽计数是刻意保留的银行定宽风格，不要“美化”成无补零文本，否则破坏接口。
- 第 72 列边界：任何 `.COB` 都必须 ≤72 列；唯一例外是以 `.COB.src` 存放的截断实验模板，
  由 `check.py` 复制为 `.COB` 后编译，不要把它改名为 `.COB`。

## 评分量表（100 分）

| 项目 | 分值 | 满分证据 |
|---|---:|---|
| 环境证据与源码→执行文件关系 | 20 | `env-report.sh` 输出、`cobc -V`、`file`/`ldd` |
| 入口实现与字节级校验 | 30 | 原始长度/LF/字符/排序校验；RC0/4 正确发布 |
| 故障保护与调查 | 25 | RC8 无发布、构建失败定位、列截断解释 |
| 独立核算与守恒 | 15 | 手算控制报告、READ=ACCEPTED+REJECTED |
| 证据与限制说明 | 10 | 命令、原始 RC、校验和、平台限制 |

接口完整性 RC8、失败仍发布、把定长补齐结果当成原始长度、把列截断当“编译器 bug”而不检查
列宽，均属关键缺陷，对应评分项最高记 0。

## 常见误区

把 `LINE SEQUENTIAL` 读入定长字段后判断长度（掩盖短/长记录）；忽略末尾 LF 缺失；把
`UNKNOWN-STATUS` 当成结构错误（会错误地不发布）；把营业日默认为机器当前日期；把
`starter` 直接当参考实现。
