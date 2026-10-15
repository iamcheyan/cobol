# 第 22 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。两项都从夹具副本开始运行：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt
```

## 1. 把孤立交易改为账户 A000000009

在 `build/transactions-unsorted.txt` 中把：

```text
A000000004D000007500
```

替换为：

```text
A000000009D000007500
```

运行 `(cd build && ./lesson_22)`。该笔与主档 `A000000009` 匹配且字段合法，进入接受文件；主档 `A000000009` 被认领，仅主档计数归零。标准输出：

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
被拒绝 账号=A000000007 REASON=BAD_AMOUNT
ACCEPTED 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=000
```

`build/accepted.txt` 变为 4 行，新增：

```text
A000000009C0001009D000007500
```

`build/rejected.txt` 只剩两条：`A000000006...NO_ACCOUNT` 与 `A000000007...BAD_AMOUNT`。

不变量自查：`接受 4 + 拒绝 2 = 输入 6`；`主档匹配 4 + 仅主档 0 = 主档 5`（无主档拒绝只剩 1 条，`6 − 1 = 5`）。退出码 `0`。

## 2. 修正账户 A000000007 的金额

先用 `build/orig-transactions.txt` 复位交易夹具，再把最后一条交易从：

```text
A000000007D00000X001
```

改为：

```text
A000000007D000000001
```

九位金额字段变为纯数字，因此该笔匹配主档 `A000000007` 后进入接受文件；金额表示 `0.01`，程序只做格式验证与写出，**不更新主档余额**。标准输出：

```text
ACCEPTED 账号=A000000001
ACCEPTED 账号=A000000003
被拒绝 账号=A000000004 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000005
被拒绝 账号=A000000006 REASON=NO_ACCOUNT
ACCEPTED 账号=A000000007
MASTER_ONLY账户 账号=A000000009
输入记录数=006 排序记录数=006
接受记录数=004
拒绝记录数=002 MASTER_ONLY账户记录数=001
```

`build/accepted.txt` 新增：

```text
A000000007C0001007D000000001
```

`build/rejected.txt` 保留 `A000000004`、`A000000006` 两条 `NO_ACCOUNT` 记录。

不变量自查：`接受 4 + 拒绝 2 = 输入 6`；`主档匹配 4 + 仅主档 1 = 主档 5`。退出码 `0`。

两题都说明同一点：输入文件的物理行序不影响结果——`SORT` 先按账户号升序重排，匹配过程只比较当前键；改变的是记录内容，不是记录顺序。
