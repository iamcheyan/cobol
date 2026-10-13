# 独立预期与人工核算（模块 02）

预期由 CUSTOMER v1 契约与 COBOL `MOVE` 规则人工推导，不是程序输出。`check.py` 逐字节比对
控制报告与 `movelab.txt`，并从原始夹具独立推导 `accepted.dat`/`rejected.dat`。

## CUSTOMER v1 装载核算

规则：27 字节/条；ID 8 位数字且严格升序；名称非全空格；`balance_demo` 8 位数字（单位分，
无符号）；状态 `A`/`D`。拒绝优先级 `NAME-MISSING` > `BAD-AMOUNT` > `UNKNOWN-STATUS`。
`BALANCE-TOTAL` 只累计接收记录。

**normal**：`ALICE 12345` + `BOB 50` + `CAROL 9999999`，状态 A/D/A 均合法。
12345 + 50 + 9999999 = **10012394**；接收 3、拒绝 0。

```text
READ=3  ACCEPTED=3  REJECTED=0  BALANCE-TOTAL=10012394
```

**empty**：0 字节，允许为空 → 全 0。

**single**：`SOLO 500` → 接收 1，合计 500。

**max-balance**：`MAX 99999999`（8 位上限）→ 接收 1，合计 99999999。

**name-full**：名称正好 10 字符 `ABCDEFGHIJ` → 接收 1，合计 1000。

**name-missing**：名称 10 个空格 → 拒绝 1，原因 `NAME-MISSING`，合计 0。

**bad-amount**：`balance_demo` = `00000A00`（含字母 A）→ 拒绝 1，原因 `BAD-AMOUNT`，合计 0。

**unknown-status**：状态 `Z` → 拒绝 1，原因 `UNKNOWN-STATUS`，合计 0。

拒绝记录格式为原始 27 字节 + `|` + 原因，例如：

```text
00000006          00000000A|NAME-MISSING
00000007BADBAL    00000A00A|BAD-AMOUNT
00000008STATUS    00000000Z|UNKNOWN-STATUS
```

## 结构夹具（RC8，无正式 expected）

`short`(26B)、`long`(28B)、`crlf`、`bad-id`、`duplicate-id`、`unsorted`、`no-final-lf` 均
违反接口契约，契约要求**整批失败、不产生任何输出目录**，因此没有正式报告；通过条件是
「没有输出目录且源夹具 SHA256 不变」。

## MOVE 实验表（`expected/movelab.txt`）

规则来源：COBOL 定点小数的**十进制对齐**与**字母数字左对齐/右补空格**语义。

| 案例 | 表达式 | 预期字节 | 依据 |
|---|---|---|---|
| A | `PIC 9(3)V99 VALUE 41.5` 显示 | `A|041.50|` | 隐式小数显示补点；3+2 位 |
| B | `41.5 → PIC 9(5)` | `B|00041|` | 小数对齐后取整数 41 |
| C | `PIC 9(5) 41 → PIC X(5)` | `C|00041|` | 数值→字母数字保留 5 位显示数字 |
| D | `'AB' → PIC X(5)` | `D|AB   |` | 字母数字右补 3 空格 |
| E | `S9(3) LEADING SEPARATE -12` | `E|-012|` | 符号前分隔占 1 字节 |
| F | `S9(3)V99 LEADING SEPARATE -1.25` | `F|-001.25|` | 符号 + 隐式小数 |
| G | `'ABCDEFGH' → PIC X(5)` | `G|ABCDE|` | 右侧截断，保留左边 5 字符 |
| H | `12345 → PIC 9(3)` | `H|345|` | 数值高位截断，保留低位 |
| I | `12345.67 → PIC 9(3)V99` | `I|345.67|` | 高位截断，小数保留 |

## 类型与层级实验表（`expected/typeslab.txt`）

输入 `fixtures/types/typeinput.dat`：三条 5 字节记录 `ABCDE` / `AB123` / `AB CD`。规则来源：
`IS ALPHABETIC` 对字母与空格为真、对数字为假；`MOVE` 不做类别校验。

| 记录 | `PIC X(5)` 原值 | 移入 `PIC A(5)` | `IS ALPHABETIC` | 类别 |
|---|---|---|---|---|
| `ABCDE` | `ABCDE` | `ABCDE` | 真 | `A` |
| `AB123` | `AB123` | `AB123` | 假 | `M` |
| `AB CD` | `AB CD` | `AB CD` | 真 | `A` |

`78 WS-LIMIT VALUE 25` 显示 `25`；`77 WS-COUNT` 逐条计数到 `00003`。预期全文（逐字节）：

```text
TYPESLAB|V1
LIMIT|25|
00001|ABCDE|ABCDE|A|
00002|AB123|AB123|M|
00003|AB CD|AB CD|A|
COUNT|00003|
```

可复现故障：把含数字的 `X` 数据移入 `PIC A` **不会**被自动拒绝（见记录 2）；把数值项
`MOVE` 到 `PIC A` 会在编译期直接失败，`check.py` 断言该 `MOVE` 非零退出。

## 布局实验

`LENGTH-PROBE` 对 canonical Copybook 输出 `CUSTOMER-RECORD=27`、`NAME-LENGTH=10`；对**故意
错写、非契约**的 `X(11)` 变体输出 `28`、`11`。这证明单字段 `PIC` 变化会移动整条记录长度与
后续偏移；该变体是错误布局演示，不是 CUSTOMER v1 契约，也不是 27→28 迁移。

## 发布条件

`control.txt` 两行、计数/合计与上方核算一致，且 `accepted.dat`/`rejected.dat` 逐字节匹配，
`movelab.txt`、`typeslab.txt` 与实验输出逐字节匹配，才算通过。
