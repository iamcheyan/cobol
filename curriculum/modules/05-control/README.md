# 05 程序控制与数据清洗（4 小时）

建议 4 小时，先修模块 04。对应大纲 05.1 IF/EVALUATE/PERFORM、05.2 SEARCH/SEARCH ALL 与
STRING/UNSTRING/INSPECT/INITIALIZE、05.3 客户状态标准化与拒绝原因分类。

业务需求：夜间批处理在接入客户主数据前，必须先清洗上游送来的 CUSTOMER v1 原始文件。
上游保证不了大小写、必填和取值范围，所以 JOB002 要先把每个 27 字节记录判成“接收”或
“拒绝”，给每条拒绝写明原因，并证明**读入 = 接收 + 拒绝**。清洗后的 27 字节文件才是后续
模块可用的客户主数据。你要交付的就是这个清洗程序 `CLEANSE.COB`。

## 1. 输入从哪来、格式与前提

- 输入是 ASCII、LF 终止的 CUSTOMER v1 文件，每条逻辑记录 **27 字节**（**LF 不计入**）：
  1–8 `customer_id`、9–18 `customer_name`、19–26 `balance_demo`、27 `status`。
- 前提：文件已按 `customer_id` 升序排列（本模块不负责排序，逆序属契约错误）。
- `status` 允许大小写混用（清洗阶段会统一为大写 `A`/`D`）；`balance_demo` 是 0 起、
  上限 50,000,000 的合成实验金额（不是最终账本）。
- 营业日由命令行参数给出，不取机器当前日期，必须匹配 `ACCOUNT/TRANSACTION` 契约使用的
  同一营业日；格式为 `YYYYMMDD` 且必须是真实日历日。
- 边界与异常前提：空文件允许（0 条记录）；缺失/不可读文件是系统失败；短行、长行、CRLF、
  缺末尾 LF、逆序都是文件契约错误，整批失败且不发布。

## 2. 从干净 checkout 构建、运行与复位

需要 Linux x86-64、GnuCOBOL 3.2、Bash、GNU coreutils、Python 3（仅验收）。macOS/WSL 未验证。

```bash
lab=curriculum/modules/05-control
bash "$lab/scripts/build.sh" /tmp/cleanse      # 编译练习/参考实现
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/clean.dat" \
  /tmp/bank-cleanse-normal 20261009            # 正式 JOB 入口
bash "$lab/scripts/check.sh"                    # 全量验收
bash "$lab/scripts/reset.sh" /tmp/bank-cleanse-normal   # 复位
```

`run.sh` 只接受**不存在**的新输出目录；运行时先写到私有 stage 目录，核对通过后整体发布。
派生文件都在该输出目录内：`accepted.dat`、`rejected.dat`、`report.txt`、`run.txt`、
`source.sha256`、`compiler.txt`、`inputs.sha256`、`outputs.sha256`、`customer.input.dat`
（不可变输入快照）。它**不会**覆盖 `fixtures/` 原件或其他模块产物。`reset.sh` 只删除带本课程
标记（`run.txt`/`inputs.sha256`/`outputs.sha256`/`report.txt`）且不在仓库内的目录。

## 3. 预期输出、RC、笔数与金额

`report.txt` 每条输入记录一行，最后一行是控制行：

```text
CUST|<id>|ACCEPT|<A|D>|<8位金额>
CUST|<id>|REJECT|<原因>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|AMOUNT=18位
```

`accepted.dat` 是规范化后的 27 字节记录（状态已大写）；`rejected.dat` 是原始 27 字节 +
`|` + 原因。RC 政策：

| RC | 含义 | 输出政策 |
|---:|---|---|
| 0 | 无业务拒绝，读入=接收+拒绝 | 发布 |
| 4 | 有业务拒绝（见下），文件契约仍完整 | 发布含拒绝明细的已核对结果 |
| 8 | 文件契约错误：长度、CRLF、缺末尾 LF、逆序、错误营业日 | 整批失败，不发布 |
| 12 | 文件/权限/系统失败 | 整批失败，不发布 |

业务拒绝原因目录（**固定优先级**，从上到下）：

| 原因 | 触发条件 |
|---|---|
| `MISSING-ID` | `customer_id` 非数字 |
| `DUPLICATE-ID` | 数字 ID 与前一条相同（输入须升序；逆序是 RC8） |
| `MISSING-NAME` | `customer_name` 去除空字符后全为空格 |
| `BAD-AMOUNT` | `balance_demo` 非数字 |
| `AMOUNT-RANGE` | 金额数字合法但 > 50,000,000 |
| `UNKNOWN-STATUS` | 状态（已大写）不在 `{A,D}` |

**金额守恒**：`AMOUNT` = 所有被接收记录的金额之和（18 位精确十进制）。被拒绝记录的金额
不计入任何合计。`expected/` 下的文本由**人工微算例和业务规则独立确定**，不是程序输出反推；
`check.py` 再用夹具独立重建 accepted/rejected 逐字节比对，并对 `report.txt` 做整文件相等比较
（不做整文件 trim）。

## 4. 需要修改哪里、哪些接口不能破坏

任务：在 `starter/CLEANSE.COB` 上实现清洗逻辑（读文件、判长度、分类拒绝、写两类输出、算控制
总数）。**不能破坏**的接口：CUSTOMER v1 的 27 字节布局、营业日参数语义、RC 约定、原因码
拼写、`ACCOUNT v1`/`TRANSACTION v1` 契约。参考实现在
[`instructor/modules/05-control/CLEANSE.COB`](../../../instructor/modules/05-control/CLEANSE.COB)。

## 5. 故意破坏与恢复（可复现故障）

1. 把 `fixtures/normal/clean.dat` 复制到临时目录，删掉最后一条记录的末尾 LF：应 RC8、
   stderr 出现 `MISSING-FINAL-LF`，且不发布。
2. 把某条记录的 `status` 改成 `X`：应 RC4、发布 `UNKNOWN-STATUS`，其余记录仍正常。
3. 把两条记录的 ID 改成相同：第二条应 RC4 `DUPLICATE-ID`，读入=接收+拒绝仍守恒。
4. 把两条记录顺序对调：应 RC8 `UNSORTED-INPUT`，不发布，原始夹具不被改写。

调查顺序：先看 stderr 的原因码与 RC，再看 `report.txt` 是否与输入逐条对齐，最后用
`sha256sum -c inputs.sha256` 确认输入快照未变。

## 6. 插件路径与终端替代

- 插件：`:CobolGotoCopybook` 打开 `COPY "CUSTOMER-V1.CPY"` 核对 27 字节布局；
  `:CobolCalcRecord` 查看逐字段字节；`gd` 跳到段落；局部标尺确认 Area A/B。
- 终端替代：`rg -n 'REASON|SEARCH|INSPECT|STRING'`、`awk '{print length($0)}'`、
  `od -An -tc` 看换行与原始字节。两条路径都要能完成同样的业务目标。

## 7. 验收证据与失败判定

交源码、正常与至少一个 RC4、一个 RC8（无发布）证据、输入 SHA256、读入=接收+拒绝守恒、
金额守恒。模板见 [evidence/README.md](evidence/README.md)。**失败判定**：日志与断言不匹配、
RC 与原因码不符、失败案例仍发布了输出目录、或原始夹具被改写，任一即失败。

## 8. 05.1 控制流微实验（PERFORM VARYING / 内联 / 作用域 / 跌落）

[`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB) 用一个自包含程序实测大纲
05.1 的四个控制点，由 `check.sh` 实际编译运行并逐行断言：

```text
VARYING=15    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 5（1+2+3+4+5）
INLINE=20     PERFORM 2 TIMES … END-PERFORM（内联 PERFORM，独立作用域）
FIRST         PERFORM 2000-FIRST：只跑该段落，结束即返回（作用域止于段落边界）
SCOPE-DONE
FIRST         PERFORM 2000-FIRST THRU 3000-SECOND：执行到 3000-SECOND 的
SECOND        EXIT，因此控制**落入后续段落**（fall-through）——经典的 Area B 陷阱
THRU-DONE
```

学员修改实验：把 `PERFORM 2 TIMES` 改成 `3 TIMES`（`INLINE` 变 30）；去掉 `THRU
3000-SECOND`（`SECOND` 行消失，证明作用域止于段落）；把 `UNTIL I > 5` 改成 `> 3`
（`VARYING` 变 6）。`check.py` 的 `check_control_flow` 锁定未修改时的逐行输出。

## 9. 05.2 语言微实验（quantity 与 sorting premise）

- [`scripts/language-probe.COB`](scripts/language-probe.COB)：用 `UNSTRING` 载入无序
  `raw=canonical` 状态映射，`INSPECT` 规范化名字，`SEARCH`（线性，无序可用）查状态，
  `INITIALIZE` 清输出，`STRING` 拼报告行。
- [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB)：同一组键分别按排序/未排序
  摆放，证明 `SEARCH ALL` 的二分搜索**要求表真的按声明键序排好**，否则会漏掉存在的键。

两者由 `check.sh` 实际编译运行并断言输出。

## 10. 大纲要求 ↔ 可运行实操对应表

每一行都指向真实、可运行、被 `check.sh` 断言的源码/夹具，而非空文件或关键词。

| 大纲要求 | 源码 | 输入 | 学员修改/故障 | expected / check | 证据 |
|---|---|---|---|---|---|
| 05.1 IF/EVALUATE | `instructor/.../CLEANSE.COB` `4000-PROCESS`（嵌套 IF）、`3000-READ-RECORD`（EVALUATE） | `fixtures/*` | 把某条 `status` 改 `X` | `expected/invalid-unknown-status.txt`；`run_case` 逐字节比对 | `evidence/README.md` |
| 05.1 PERFORM 段落 | `CLEANSE.COB` PERFORM 3000/4000/5000/6000 | `fixtures/normal/clean.dat` | 注释掉 `PERFORM 5000-EMIT-ACCEPT` | `check_protection`/`run_case` 契约不变即失败 | 同左 |
| 05.1 PERFORM UNTIL | `CLEANSE.COB` `1000-MAIN`、`3000-READ-RECORD` 读循环 | 同上 | 去掉 `UNTIL EOF-FLAG = 1` 的终止 | 无限读/计数不符即失败 | 同左 |
| 05.1 PERFORM VARYING | [`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB) | 无（自包含） | `UNTIL I > 5` 改 `> 3` | `check_control_flow`：`VARYING=15` | `evidence/README.md` |
| 05.1 内联 PERFORM | 同上 | 同上 | `2 TIMES` 改 `3 TIMES` | `INLINE=20` | 同左 |
| 05.1 作用域与落入后续段落 | 同上（`PERFORM 2000-FIRST` vs `THRU 3000-SECOND`） | 同上 | 去掉 `THRU` | `FIRST/SCOPE-DONE/FIRST/SECOND/THRU-DONE` | 同左 |
| 05.2 SEARCH（线性，无序可用） | [`scripts/language-probe.COB`](scripts/language-probe.COB) | 临时 `map.txt`/`names.txt` | 换一个未映射状态 | `NORM...UNMAPPED` | `check_probes` |
| 05.2 SEARCH ALL（排序前提） | [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB) | 自包含 | 打乱 `S-KEY` 顺序 | `SORTED=FOUND` / `UNSORTED=MISS` | 同左 |
| 05.2 STRING/UNSTRING/INSPECT/INITIALIZE | `language-probe.COB` | 同上 | 去掉 `INSPECT … REPLACING` | `NORM|00000001|Alice|ACTIVE` | 同左 |
| 05.3 状态标准化/必填/金额范围/拒绝分类 | `instructor/.../CLEANSE.COB` | `fixtures/normal`、`invalid`、`boundary` | 改 `status`/`name`/金额越界 | `expected/*.txt`；`run_case` 与 `verify-publish.py` 独立重算 | `evidence/README.md` |

