# 06 文件处理（6 小时）

建议 6 小时，先修模块 05。对应大纲 06.1 SELECT/FD/SD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF；
06.2 定长字节记录 vs LINE SEQUENTIAL、换行不计入逻辑宽度、长度异常检测；06.3 缺失/空文件、
短/长行、非法数字、重复 ID、未知状态与输入控制总数；06.4 相对/索引文件 REWRITE/DELETE 与
锁的阅读实验及适用边界。

业务需求：夜间批处理的 **JOB002 长度与业务校验** 要读取上游送来的 ACCOUNT v1 主文件（47
字节定长），逐条判成“接收/拒绝”，写明字段级原因，记录文件状态，给出输入控制总数，并产出
一个**合法且有序**的 ACCOUNT v1 文件，交给模块 07 的顺序突合直接使用。你要交付的就是这个
校验程序 `FILEVAL.COB`。

## 1. 输入从哪来、格式与前提

- 输入是 ASCII、LF 终止的 ACCOUNT v1 文件，每条逻辑记录 **47 字节**（**LF 不计入**）：
  1–10 `account_id`、11–18 `customer_id`、19–21 `currency`、22 `balance_sign`、
  23–35 `opening_balance`、36 `account_status`、37–44 `business_date`、45–47 `layout_version`。
- 复用冻结接口 `curriculum/bank/copybooks/ACCOUNT-V1.CPY`；本模块不修改它。
- 前提：文件已按 `account_id` 升序排列；营业日由参数给出且必须与记录的 `business_date`
  一致；`currency` 首期为 `JPY`；`layout_version` 必须为 `001`。
- 空文件（0 字节）**允许**，表示当日 0 个账户；缺失/不可读文件是系统失败（RC12）。
- 定长字节读取：程序自己数 1..47 字节并识别 LF，因此能发现短行、长行、CRLF、缺末尾 LF。

## 2. 从干净 checkout 构建、运行与复位

需要 Linux x86-64、GnuCOBOL 3.2（`cobc -info` 报索引后端 BDB）、Bash、GNU coreutils、
Python 3（仅验收）。macOS/WSL 未验证。**不要**用 `-std=cobol85`。

```bash
lab=curriculum/modules/06-files
bash "$lab/scripts/build.sh" /tmp/fileval
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/valid.dat" \
  /tmp/bank-fileval-normal 20261009
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-fileval-normal
```

`run.sh` 只接受不存在的新输出目录，先写私有 stage，核对后整体发布。派生文件都在输出目录内：
`accepted.dat`、`rejected.dat`、`report.txt`、`filestatus.log`、`run.txt`、`compiler.txt`、
`source.sha256`、`inputs.sha256`、`outputs.sha256`、`account.input.dat`（输入快照）。
不覆盖 `fixtures/` 原件。`reset.sh` 只删带本课程标记且不在仓库内的目录。

## 3. 预期输出、RC、笔数与金额

```text
ACCT|<id>|ACCEPT|<A|C|F>|<符号><18位>
ACCT|<id>|REJECT|<原因>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|BALANCE=<符号><18位>
```

`accepted.dat` 是原样 47 字节合法记录；`rejected.dat` 是原始 47 字节 + `|` + 原因；
`filestatus.log` 记录 `OPEN|ACCOUNT|00` 与 `EOF|ACCOUNT|10`。RC：

| RC | 含义 | 输出政策 |
|---:|---|---|
| 0 | 无业务拒绝，读入=接收+拒绝 | 发布 |
| 4 | 有字段级业务拒绝 | 发布含拒绝明细的已核对结果 |
| 8 | 契约错误：长度、CRLF、缺末尾 LF、逆序、错误 layout、错误营业日 | 整批失败，不发布 |
| 12 | 文件/权限/系统失败（含输入缺失，FILE STATUS 35） | 整批失败，不发布 |

字段级拒绝原因（**固定优先级**）：

| 原因 | 触发条件 |
|---|---|
| `BAD-ACCOUNT-ID` | `account_id` 非数字 |
| `DUPLICATE-ID` | 数字 ID 与前一条相同（逆序是 RC8） |
| `BAD-CUSTOMER-ID` | `customer_id` 非数字 |
| `UNKNOWN-CURRENCY` | `currency` ≠ `JPY` |
| `BAD-SIGN` | `balance_sign` ∉ `{+,-}` |
| `BAD-BALANCE` | `opening_balance` 非数字 |
| `BAD-DATE` | `business_date` 非数字或非真实日历日 |
| `DATE-MISMATCH` | 日期合法但不等于作业营业日 |
| `UNKNOWN-STATUS` | `account_status` ∉ `{A,C,F}` |

**控制总数**：`READ = ACCEPT + REJECT`；`BALANCE` = 被接收记录的带符号期初余额之和（18 位
精确十进制）。拒绝记录不计入 `BALANCE`。`expected/` 由人工算例独立确定，`check.py` 再用夹具
独立重建 accepted/rejected 逐字节比对。

## 4. 需要修改哪里、哪些接口不能破坏

在 `starter/FILEVAL.COB` 上实现读取、校验、分类和三类输出。**不能破坏**：ACCOUNT v1 的 47
字节布局、营业日参数语义、RC 约定、原因码拼写、`TRANSACTION v1` 契约。参考实现：
[`instructor/modules/06-files/FILEVAL.COB`](../../../instructor/modules/06-files/FILEVAL.COB)。

## 5. 故意破坏与恢复（可复现故障）

1. 复制 `fixtures/normal/valid.dat` 到临时目录并删掉末条 LF：RC8 `MISSING-FINAL-LF`，不发布。
2. 把某条 `currency` 改成 `USD`：RC4 `UNKNOWN-CURRENCY`，其余记录照常。
3. 把某条 `business_date` 改成 `20261008`：RC4 `DATE-MISMATCH`。
4. 把 `layout_version` 改成 `002`：RC8 `BAD-LAYOUT-VERSION`，不发布。
5. 把两条记录对调：RC8 `UNSORTED-INPUT`。

调查顺序：先读 stderr 的原因码与 RC，再核对 `report.txt` 与输入逐条对齐，最后
`sha256sum -c inputs.sha256` 确认输入快照未变；失败时确认没有发布目录。

## 6. 插件路径与终端替代

- 插件：`:CobolGotoCopybook` 打开 `ACCOUNT-V1.CPY` 核对 47 字节；`:CobolCalcRecord` 看字段
  字节；`gd` 跳段落；标尺确认 Area A/B。
- 终端替代：`rg -n 'FILE STATUS|EOF|TEST-DATE|SEARCH'`、`awk '{print length($0)}'`、
  `od -An -tc` 看 LF/CRLF 与原始字节。两条路径都要能完成同样的业务目标。

## 7. 验收证据与失败判定

交源码、正常与至少一个 RC4、一个 RC8（无发布）、RC12（缺失文件）证据、输入 SHA256、读入=
接收+拒绝守恒、`BALANCE` 守恒、`filestatus.log`。模板见 [evidence/README.md](evidence/README.md)。
**失败判定**：RC/原因码不符、失败案例仍发布输出、原始夹具被改写、或 `filestatus.log` 与
契约不符，任一即失败。

## 8. 06.2 / 06.4 阅读实验（本机实测）

- [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB)：同一条 5 字节逻辑记录，用
  `LINE SEQUENTIAL` 写出的文件原始 **6 字节（含 LF）**，用定长 `SEQUENTIAL` 写出 **5 字节**；
  把 LINE 文件按字节读回能看到 `X'0A'`。证明**LF 存在但不计入逻辑宽度**，而定长逐字节模型
  才能暴露它。
- [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB)：BDB 索引文件的
  `WRITE/READ/REWRITE/DELETE` 及状态码（含同一进程重复 `OPEN` 的 `41`）。
- [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB)：`OPEN I-O` 后停在
  stdin 上的持有者，用来做**真正的两进程争锁实验**（不是同进程重开）。
- [`scripts/relative-probe.COB`](scripts/relative-probe.COB)：相对文件的
  `WRITE/READ/REWRITE/DELETE`（`RELATIVE KEY`）。
- [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB)：`SD` 排序描述项与
  `SORT … ASCENDING KEY … USING/GIVING` 配对，把乱序 `LINE SEQUENTIAL` 输入排成有序输出
  （06.1 的 SD/SORT 声明，不涉及模块 07 的突合算法）。

实测状态码与**适用边界**见 [DESIGN.md](DESIGN.md) 第 5 节。关键结论（本机实测，非文档臆断）：

- 同一进程内重复 `OPEN` 同一文件返回 `41`；**这不能代表两个进程的行为**。
- 两个进程同时 `OPEN I-O` 同一 BDB 索引文件，**两者都得到 `00`**（`indexed-hold-probe`
  由 `check.py::check_cross_process_lock` 实际并发跑出）→ 默认 GnuCOBOL/BDB 句柄层
  **不提供跨进程互斥**。
- 因此并发一致性必须由 JOB 层外部锁保证：本课 `run.sh` 用 `output.lock` 目录做单实例
  保护，`check.py::check_protection` 同时启动两个 `run.sh`，断言恰好一个 `RC0`、另一个
  `RC12` 且 stderr 为 `Run locked`，结果目录与锁随后都干净。06.4 正是要你读懂这条界限。

## 9. 大纲要求 ↔ 可运行实操对应表

每一行都指向真实、可运行、被 `check.sh` 断言的源码/夹具。

| 大纲要求 | 源码 | 输入 | 学员修改/故障 | expected / check | 证据 |
|---|---|---|---|---|---|
| 06.1 SELECT/FD/OPEN/READ/WRITE/CLOSE/FILE STATUS/EOF | `instructor/.../FILEVAL.COB` | `fixtures/normal/valid.dat` | 删掉末条 LF | `filestatus.log`、`expected/normal-valid.txt`；`run_case` | `evidence/README.md` |
| 06.1 SD（排序描述项） | [`scripts/sort-sd-probe.COB`](scripts/sort-sd-probe.COB) | 临时 `in.dat` 乱序 | 改 `ASCENDING` 为 `DESCENDING` | `check_line_sequential_and_sd`：`ALICE/BOB/CAROL` | `check_probes` |
| 06.2 定长 vs LINE SEQUENTIAL | [`scripts/line-seq-probe.COB`](scripts/line-seq-probe.COB) | 临时 `line.dat`/`fixed.dat` | 改写成 `LINE SEQUENTIAL` 读回 | `LINE-RAW-BYTES=06` vs `FIXED-RAW-BYTES=05` | `check_probes` |
| 06.2 长度异常检测 | `FILEVAL.COB` 逐字节读 | `fixtures/invalid/{short,long}-record.dat`、`no-trailing-lf.dat`、`crlf.dat` | 改短/改长/加 CR | RC8、无发布；`run_case` | `evidence/README.md` |
| 06.3 缺失/空文件/非法数字/重复 ID/未知状态/控制总数 | `FILEVAL.COB` | `fixtures/boundary`、`invalid` | 缺文件→RC12；空文件→RC0 | `expected/*.txt`；`run_case`+`verify-publish.py` | 同左 |
| 06.4 索引文件 WRITE/READ/REWRITE/DELETE | [`scripts/indexed-probe.COB`](scripts/indexed-probe.COB) | 临时 `ix.dat` | 重复键、缺键 | `DUPLICATE=22`、`MISSING=23`、`REOPEN=41` | `check_probes` |
| 06.4 相对文件 | [`scripts/relative-probe.COB`](scripts/relative-probe.COB) | 临时 `rel.dat` | 越界键 9 | `READ9=23` | `check_probes` |
| 06.4 两进程争锁与适用边界 | [`scripts/indexed-hold-probe.COB`](scripts/indexed-hold-probe.COB) + `run.sh` `.lock` | 并发两个持有者 / 两个 `run.sh` | 去掉 `run.sh` 的 `.lock` | 两进程 `HOLD-OPEN=00`；JOB 锁 `RC0`/`RC12 Run locked` | `check_cross_process_lock`、`check_protection` |

