# 第 32 课修改练习参考答案

本文件只回答 `exercise.md` 中编号的两项修改练习，不回答举一反三题。

## 1. 入账一笔 1.00 到 A000000003

在 `fixtures/transactions.txt` 增加：

```text
A000000003D000000100
```

字段拆分：账户 `A000000003`，类型 `D`，金额 `000000100` 分即 1.00。该账户初始余额为 2.00，因此过账后的文件余额为 3.00。运行 `./build.sh run` 后可见：

```text
POSTED TX=006 ACCOUNT=A000000003 TYPE=D BALANCE=0000003.00
SYNC UPDATED ACCOUNT=A000000003 BALANCE=0000003.00
SUMMARY ACCOUNTS=03 TX=006 POSTED=003 REJECTED=003 UPDATED=002 UNCHANGED=001 INSERTED=000
```

`build/run/accepted.txt` 多出 TX=006；`build/run/account-report.txt` 把 A000000003 列为 `UPDATED`。SQLite 中该账户的余额为 3.00。

## 2. 从初始数据库删除 A000000005

从 `schema.sql` 的 `INSERT INTO ACCOUNT_SNAPSHOT VALUES` 列表中删除：

```sql
('A000000005', 'C0001005', 250.75)
```

执行 `./build.sh run`。输入主档仍有 A000000005，查询无行后程序插入其客户号和主档余额：

```text
SYNC INSERTED ACCOUNT=A000000005 BALANCE=0000250.75
SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=001 UNCHANGED=001 INSERTED=001
```

再执行 `./build.sh run-existing`。数据库已有该账户且字段相同，因此结果变为：

```text
SYNC UNCHANGED ACCOUNT=A000000005 BALANCE=0000250.75
SUMMARY ACCOUNTS=03 TX=005 POSTED=002 REJECTED=003 UPDATED=001 UNCHANGED=002 INSERTED=000
```

`run-existing` 保留数据库状态；`run` 会重新建库，所以两次命令分别验证初次插入和重跑后的幂等分类。
