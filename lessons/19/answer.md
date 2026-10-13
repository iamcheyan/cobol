# 第 19 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。

## 1. 交易文件提前结束

在临时副本中仅保留 `transactions.txt` 的前两行。程序继续独立读取主档的第三条记录，即使交易流已经到达 EOF。最终汇总为：

```text
CLOSE=OK ACCOUNTS=003 TRANSACTIONS=002
```

交易 EOF 只设置 `WS-TRANSACTION-EOF`；主档 EOF 标志仍为 `N`，所以主档下一轮继续读取。

## 2. 空账户主档

将临时目录中的 `accounts.txt` 清空并保留原始四条交易。账户文件第一次 READ 即到 EOF；程序继续逐条读取交易文件。最终汇总为：

```text
CLOSE=OK ACCOUNTS=000 TRANSACTIONS=004
```

空主档不会把 `WS-TRANSACTION-EOF` 设为 `Y`，也不会跳过交易记录。
