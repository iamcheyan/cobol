# 第 31 课修改练习参考答案

本文件只回答 [`exercise.md`](./exercise.md) 的两项修改练习，不提供举一反三题答案。两题都从原始 `snapshot.txt`、`schema.sql`（`lesson.cob` 不改）开始，改完执行：

```sh
./build.sh run
echo $?
cat differences.txt
sqlite3 -header build/lesson31.db "SELECT ACCOUNT_NO, FILE_STATUS, FILE_CUSTOMER, FILE_BALANCE FROM RECON_RESULT;"
```

以下输出均为在本工作区实际运行的结果。

## 1. 把第二行金额改成 `000087500`

改动位置：`snapshot.txt` 第 2 行第 19–27 列。

```text
A000000001C0001001000125075
A000000002C0001002000087500
A000000003C0001003000002500
```

预期标准输出（6 行，退出码 `0`）：

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
MATCH ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=000 ファイルのみ=001
切断=成功
```

预期 `differences.txt`（只剩 1 行，比基线少 `CHANGED` 行）：

```text
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
```

`RECON_RESULT` 仍是 3 行：`A000000001|MATCH`、`A000000002|MATCH`、`A000000003|FILE_ONLY`。

原因：文件侧 `000087500` 分 = `875.00` 元，与 `ACCOUNT_SNAPSHOT` 中 `A000000002` 的 `BALANCE` 相等，客户号也相同，所以 `3100-LOOKUP-ACCOUNT` 的 `IF WS-CUSTOMER = WS-DB-CUSTOMER AND WS-BALANCE = WS-DB-BALANCE` 成立，分类由 `CHANGED` 变 `MATCH`。计数不变量随之变化：`一致 2 + 変更 0 + ファイルのみ 1 = 文件行数 3`，`differences.txt` 行数 `1 = 変更 + ファイルのみ`。

## 2. 在 `ACCOUNT_SNAPSHOT` 里增加两个账户

改动位置：`schema.sql` 的 `INSERT INTO ACCOUNT_SNAPSHOT VALUES` 列表（前一行补逗号，最后一行用分号）。

```sql
INSERT INTO ACCOUNT_SNAPSHOT VALUES
    ('A000000001', 'C0001001', 1250.75),
    ('A000000002', 'C0001002', 875.00),
    ('A000000003', 'C0001003', 25.00),
    ('A000000099', 'C0001099', 500.00);
```

预期标准输出（6 行，退出码 `0`）：

```text
接続=成功
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
MATCH ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
集計 行数=003 一致=002 変更=001 ファイルのみ=000
切断=成功
```

预期 `differences.txt`（只剩 1 行，62 字节含换行）：

```text
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
```

数据库状态：`RECON_RESULT` 3 行（`MATCH`、`CHANGED`、`MATCH`），`ACCOUNT_SNAPSHOT` 4 行；`A000000099` 虽然存在于快照表，却**不出现**在标准输出、差异文件和 `RECON_RESULT` 中。

原因：`A000000003` 补进快照表后，第三次查询由 `SQLCODE = 100` 变为 `0`，客户号 `C0001003` 与金额 `25.00` 都与文件侧一致，该键由 `FILE_ONLY` 变 `MATCH`，`ファイルのみ` 计数归零。`A000000099` 在文件里没有对应行，而程序只遍历文件侧、按文件键查询数据库，从不为数据库独有账户生成结果——这解释了本课为什么没有 `DB_ONLY` 分类，也解释了第四条计数不变量：数据库独有账户数 = `4 − (一致 2 + 変更 1) = 1`，但它不在任何输出里。

## 两题共同的核对方式

每题都要同时核对四样东西，缺一不可：标准输出的三类分类与计数、`differences.txt` 的行数与内容、`RECON_RESULT` 的行数与分类、进程退出码（本题两题都应为 `0`）。只看摘要数字无法发现"某条记录去了哪里"这类错误；只看差异文件也无法发现结果表缺行。
