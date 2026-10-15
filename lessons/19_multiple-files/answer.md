# 第 19 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。两项都在临时目录的夹具副本上做：

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_19 lesson.cob
```

## 1. 交易文件提前结束

在副本中仅保留 `transactions.txt` 的前两行。程序继续独立读取主档的第三条记录，即使交易流已经到达 EOF。最终汇总为：

```text
关闭完成 账户记录数=003 交易记录数=002
```

交易 EOF 只设置 `WS-TRANSACTION-EOF`；主档 EOF 标志仍为 `N`，所以主档下一轮继续读取。前两行主档与两条交易照常回显，退出码为 `0`。

## 2. 空账户主档

将副本 `accounts.txt` 清空并保留四条交易。账户文件第一次 `READ` 即到 EOF；程序继续逐条读取交易文件。最终汇总为：

```text
关闭完成 账户记录数=000 交易记录数=004
```

空主档不会把 `WS-TRANSACTION-EOF` 设为 `Y`，也不会跳过交易记录。四条交易全部回显，退出码为 `0`。

两项修改都不需要改源码：只要两个输入的 EOF、状态与计数各自独立，先结束的一侧就不会拖停另一侧。
