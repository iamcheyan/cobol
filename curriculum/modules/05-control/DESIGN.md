# 模块 05 设计：CUSTOMER v1 清洗契约

## 1. 接口与字节布局

CUSTOMER v1 = 27 字节，ASCII，LF 终止，LF 不计入逻辑宽度。字段与 `copybooks/CUSTOMER-V1.CPY`
一致：

| 位置 | 长度 | COBOL 名 | 规则 |
|---:|---:|---|---|
| 1–8 | 8 | CUST-ID | 8 位数字，保留前导零，清洗阶段要求升序 |
| 9–18 | 10 | CUST-NAME | ASCII，右侧空格补齐，必填 |
| 19–26 | 8 | CUST-BALANCE | 数字，0 ≤ 值 ≤ 50,000,000 |
| 27 | 1 | CUST-STATUS | 原始可大小写；规范化为 `A`/`D` |

本模块**不修改** `curriculum/bank/copybooks/ACCOUNT-V1.CPY`（47B）与
`TRANSACTION-V1.CPY`（55B）；清洗后的客户文件与它们使用同一营业日参数。

## 2. 读取模型（为什么逐字节）

程序用 `ORGANIZATION IS SEQUENTIAL`、`01 C-BYTE PIC X` 逐字节读取，自己识别 LF：

- 遇到 `X'0A'` 表示一条逻辑记录结束；LF 之前的字节数必须在 1..27。
- 字节数 < 27 → `SHORT-RECORD`；累计已到 27 又遇到非 LF 字节 → `LONG-RECORD`；
  出现 `X'0D'` → `CRLF-NOT-ALLOWED`；EOF 时还有未终止字节 → `MISSING-FINAL-LF`。
- 以上四类都是文件契约错误，RC8。

用 `LINE SEQUENTIAL` 会替调用方剥掉换行、也无法在逻辑宽度里暴露超长记录，因此本模块刻意
不用它；模块 06 会用夹具对照两者的字节差异。

## 3. 处理状态与顺序

```text
OPEN INPUT/OUTPUT → 设置状态表
  循环：READ-RECORD → PROCESS-RECORD
PROCESS-RECORD:
  1. 结构校验（长度/CRLF）已在读取阶段完成
  2. id 数字？否 → MISSING-ID；是 → 逆序? RC8；与上条相同? DUPLICATE-ID；否则记 PREV-ID
  3. REASON 仍空 → 名字去空后非空? 否则 MISSING-NAME
  4. REASON 仍空 → 金额数字? 否则 BAD-AMOUNT；> 上限? AMOUNT-RANGE
  5. REASON 仍空 → 状态 INSPECT 大写 → SEARCH ALL 表{A,D}；未命中 UNKNOWN-STATUS
  6. REASON 空 → 写 accepted.dat、累计金额；否则写 rejected.dat
CLOSE → 校验 READ = ACCEPT + REJECT → 打印 CONTROL
```

`SEARCH ALL` 扫描的 `STATUS-TABLE` 声明 `ASCENDING KEY` 且按 A<D 装载，满足二分搜索前提；
未排序表的反例见 `scripts/search-all-probe.COB`。

## 4. 拒绝原因优先级（业务政策）

数字 ID 行先做重复判断，再做名字/金额/状态，因此一条记录可能同时违规时取最先命中者：

1. `MISSING-ID` → 2. `DUPLICATE-ID` → 3. `MISSING-NAME` → 4. `BAD-AMOUNT` /
   `AMOUNT-RANGE` → 5. `UNKNOWN-STATUS`。

`UNSORTED-INPUT`（数字 ID 小于上一条）与长度类错误是**契约错误 RC8**，不属于逐笔业务拒绝。

## 5. 输出与 RC

| 产物 | 内容 |
|---|---|
| `accepted.dat` | 规范化 27B 记录（状态大写），LF 终止 |
| `rejected.dat` | 原始 27B + `\|` + 原因，LF 终止 |
| `report.txt` | 逐条 `CUST|...` 行 + 末尾 `CONTROL|...` |
| `filestatus`/`compiler.txt`/`source.sha256` | 运行与来源证据 |

RC：0 无拒绝；4 有业务拒绝；8 契约错误（长度/CRLF/缺 LF/逆序/坏营业日）；12 系统失败。

## 6. 人工微算例（`fixtures/invalid/mixed.dat`）

| 记录 | 关键字段 | 判定 | 理由 |
|---:|---|---|---|
| 1 | id 00000001, name "  Alice", bal 00000050, st `a` | ACCEPT A | 状态 `a`→`A`∈{A,D}；金额 50≤上限 |
| 2 | id 00000002, name 全空格 | REJECT MISSING-NAME | 必填为空 |
| 3 | id 00000003, bal 50000001, st `D` | REJECT AMOUNT-RANGE | 50000001 > 50,000,000 |
| 4 | id 00000004, bal `00000XYZ` | REJECT BAD-AMOUNT | 非数字 |
| 5 | id 00000005, st `Q` | REJECT UNKNOWN-STATUS | `Q`∉{A,D} |
| 6 | id 00000005（重复）, 其余合法 | REJECT DUPLICATE-ID | 与前条同 ID |

读入 6 = 接收 1 + 拒绝 5；`AMOUNT` = 50（只有记录 1 计入）。所有 `expected/*.txt` 均按本表
和同规则人工核算，再运行参考实现核对一致。

## 7. 边界与限制

- 空文件（0 字节）合法：READ=0、RC0。
- 上限 50,000,000 为合成实验政策；真实系统应按字段目录定义，不得静默套用。
- 只处理 ASCII 与单币种最小单位整数，不做小数换算；多字节/EBCDIC 属单独实验。
- 已实际验证平台：Linux x86-64、GnuCOBOL 3.2（本机 BDB 后端）。其他平台未验证。
- 运行时可能出现 `libcob: warning`（libxml 版本提示）环境噪声，与业务 RC 无关。

## 8. 控制流语义（05.1 微实验）

固定格式下段落/节以“下一个段落头”结束，不是以空行或句点结束：

- `PERFORM 2000-FIRST` 只执行该段落，到段落边界即隐式返回，**不会**掉进 3000-SECOND。
- `PERFORM 2000-FIRST THRU 3000-SECOND` 从 2000-FIRST 起连续执行，直到 3000-SECOND 内
  的 `EXIT`（或 `EXIT PARAGRAPH`）；这既是“作用域”，也是最容易写出 fall-through 的地方。
- `PERFORM VARYING I FROM 1 BY 1 UNTIL …` 先判 `UNTIL` 再执行；`PERFORM n TIMES …
  END-PERFORM` 是内联循环，默认 TEST BEFORE。

以上由 `scripts/control-flow-probe.COB` 实测，`check.py::check_control_flow` 锁定逐行输出。
