# 模块 06 设计：ACCOUNT v1 文件契约与状态语义

## 1. 接口与字节布局

ACCOUNT v1 = 47 字节，ASCII，LF 终止，LF 不计入逻辑宽度。字段与
`curriculum/bank/copybooks/ACCOUNT-V1.CPY` 一致：

| 位置 | 长度 | COBOL 名 | 规则 |
|---:|---:|---|---|
| 1–10 | 10 | ACCOUNT-ID | 数字，升序，唯一 |
| 11–18 | 8 | CUSTOMER-ID | 数字，引用客户 |
| 19–21 | 3 | ACCOUNT-CURRENCY | 首期 `JPY` |
| 22 | 1 | BALANCE-SIGN | `+` / `-` |
| 23–35 | 13 | OPENING-BALANCE | 数字，最小单位整数 |
| 36 | 1 | ACCOUNT-STATUS | `A` 正常 / `F` 冻结 / `C` 关闭 |
| 37–44 | 8 | ACCOUNT-DATE | `YYYYMMDD`，须等于作业营业日 |
| 45–47 | 3 | ACCOUNT-LAYOUT | `001` |

`TRANSACTION v1`（55B）在本模块不被修改，仅作为下游模块 07 的契约存在。

## 2. 读取模型（为什么逐字节）

`FILEVAL.COB` 用 `ORGANIZATION IS SEQUENTIAL`、`01 A-BYTE PIC X` 逐字节读取，自行识别
`X'0A'`：

- 逻辑记录字节数必须在 1..47；不足 → `SHORT-RECORD`；已满 47 又遇非 LF 字节 →
  `LONG-RECORD`；遇 `X'0D'` → `CRLF-NOT-ALLOWED`；EOF 仍有未终止字节 → `MISSING-FINAL-LF`。
- 以上均为文件契约错误 RC8。
- `LINE SEQUENTIAL` 会剥除换行，逻辑宽度看不出换行是否合法；06.2 用
  `scripts/line-seq-probe.COB` 实测两者字节差（见第 5 节）。

## 3. 处理状态与顺序

```text
OPEN INPUT/OUTPUT/LOG → 装状态表{A,C,F}
  循环：READ-RECORD（结构校验）→ PROCESS-RECORD
  1. layout ≠ 001 → RC8
  2. id 非数字 → BAD-ACCOUNT-ID；数字则判逆序(RC8)/重复(DUPLICATE-ID)
  3. REASON 仍空 → customer_id 非数字? BAD-CUSTOMER-ID
  4. → currency ≠ JPY? UNKNOWN-CURRENCY
  5. → sign ∉ {+,-}? BAD-SIGN
  6. → balance 非数字? BAD-BALANCE
  7. → date 非数字/非日历? BAD-DATE；否则 ≠ 营业日? DATE-MISMATCH
  8. → status SEARCH ALL {A,C,F}；未命中 UNKNOWN-STATUS
  9. 空 → 写 accepted 并累加带符号余额；否则写 rejected
CLOSE → READ = ACCEPT + REJECT → 打印 CONTROL，写 filestatus.log
```

## 4. 拒绝原因优先级与 RC

1. `BAD-ACCOUNT-ID` → 2. `DUPLICATE-ID` → 3. `BAD-CUSTOMER-ID` →
4. `UNKNOWN-CURRENCY` → 5. `BAD-SIGN` → 6. `BAD-BALANCE` → 7. `BAD-DATE` /
`DATE-MISMATCH` → 8. `UNKNOWN-STATUS`。

`UNSORTED-INPUT` 与长度/换行/layout 错误是**契约错误 RC8**，不属于逐笔业务拒绝。

| RC | 含义 |
|---:|---|
| 0 | 无业务拒绝，读入=接收+拒绝 |
| 4 | 有字段级业务拒绝，仍发布 |
| 8 | 契约错误（长度/CRLF/缺 LF/逆序/layout/坏营业日），不发布 |
| 12 | 文件/权限/系统失败（含缺失文件 FILE STATUS 35），不发布 |

## 5. FILE STATUS 与索引/相对文件实测（本机）

环境：Linux x86-64，GnuCOBOL 3.2.0，`cobc -info` → `indexed file handler : BDB`。
均由 `scripts/*-probe.COB` 实际执行得到（原始 RC 与状态见 evidence）。

### 5.1 顺序文件（本模块核心）

| 操作 | 状态 | 含义 |
|---|---|---|
| `OPEN INPUT` 存在 | `00` | 成功 |
| 读到末尾 | `10` | EOF（at end） |
| `OPEN INPUT` 缺失 | `35` | file not found → RC12 |
| 空文件先读 | `10` | 合法 0 条 |

`SD`（Sort Description）排序描述项与 `SORT … USING/GIVING` 的配对见
`scripts/sort-sd-probe.COB`（06.1 声明实验；模块 07 才做突合算法）。

### 5.2 LINE SEQUENTIAL vs 定长字节

| 写法 | 原始文件字节 | 逻辑记录宽度 |
|---|---:|---|
| `LINE SEQUENTIAL` 写 `HELLO` | 6（`HELLO\n`） | 5（LF 被隐藏） |
| 定长 `SEQUENTIAL` 写 `HELLO` | 5 | 5 |

把 LINE 文件按字节读回可看到 `X'0A'`，证明 LF 存在但不计入逻辑宽度。

### 5.3 索引文件（BDB）

| 操作 | 状态 |
|---|---|
| `OPEN OUTPUT` 新建 | `00` |
| `WRITE` 新键 | `00` |
| `WRITE` 重复键 | `22`（duplicate key） |
| `READ KEY` 命中 | `00` |
| `REWRITE` | `00` |
| `READ KEY` 不存在 | `23`（record not found） |
| `DELETE` 已存在 | `00` |
| 删除后 `READ` | `23` |
| 同一进程再次 `OPEN INPUT` 已打开文件 | `41`（already open） |
| `OPEN INPUT` 缺失文件 | `35` |

### 5.4 相对文件

| 操作 | 状态 |
|---|---|
| `OPEN OUTPUT` 新建 | `00` |
| `WRITE`（RELATIVE KEY 1、2） | `00` |
| 重复键再次 `WRITE` | `22` |
| `READ` 命中 | `00` |
| `REWRITE` | `00` |
| `READ` 越界键（9）/键 0 | `23` |
| `DELETE` | `00` |
| 删除后 `READ` | `23` |

### 5.5 适用边界（重要）

- **默认不提供跨进程互斥（本机实测，非文档臆断）**：用 `scripts/indexed-hold-probe.COB`
  让两个进程同时 `OPEN I-O` 同一 BDB 索引文件，**两者都得到 `00`**（`check.py::
  check_cross_process_lock` 并发实测）。同一进程内重复 `OPEN` 返回 `41` **不能**代表
  两进程行为，二者不可互相推断。GnuCOBOL/BDB 默认不独占锁定整个文件，因此并发一致性必须
  由 JOB 层外部锁保证；本课 `run.sh` 用 `output.lock` 目录做单实例保护（`check_protection`
  并发跑两个 `run.sh`：一个 `RC0`，另一个 `RC12` 且 stderr `Run locked`），二者不可互相
  替代。
- 索引/相对文件只用于本模块的**阅读实验**与模块 07 的临时账本；主校验流程仍是顺序读，
  不使用 DB Join、Python 或全量数组。

## 6. 人工微算例（`fixtures/invalid/mixed.dat`）

| 记录 | 关键字段 | 判定 |
|---:|---|---|
| 1 | id1, JPY, +, 1000, A, 20261009 | ACCEPT +1000 |
| 2 | id2, USD | REJECT UNKNOWN-CURRENCY |
| 3 | id3, `*` 符号 | REJECT BAD-SIGN |
| 4 | id4, 状态 `Z` | REJECT UNKNOWN-STATUS |
| 5 | id5, 日期 20261008 | REJECT DATE-MISMATCH |
| 6 | id6, JPY, +, 100, A | ACCEPT +100 |

读入 6 = 接收 2 + 拒绝 4；BALANCE = 1000 + 100 = 1100。`normal/valid.dat`：
+1000 + +50 − 500 = **550**。

## 7. 边界与限制

- 空文件合法（READ=0、RC0）；缺失文件 RC12 且不发布。
- `BALANCE` 为 18 位精确十进制带符号；单条 13 位。不做小数换算。
- 只处理 ASCII 与单币种最小单位整数；多字节/EBCDIC 属单独实验。
- 已实际验证平台：Linux x86-64、GnuCOBOL 3.2（BDB）。其他平台未验证。
- 运行时 `libcob: warning`（libxml 版本提示）是环境噪声，与业务 RC 无关。
