# 第 19 课练习：独立输入流与 EOF

本节只使用第 15–19 课讲过的内容：顺序文件 `SELECT`/`OPEN`/`READ`/`CLOSE`、`FILE STATUS`、`AT END`、`PERFORM UNTIL`、`IF` 和 `DISPLAY`。

## 修改练习（会在 `answer.md` 提供参考答案）

两项都只改**临时目录里的夹具副本**，不要改动仓库内的 `accounts.txt` / `transactions.txt`。先准备临时目录：

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_19 lesson.cob
```

1. 从副本 `transactions.txt` 删除最后两条记录（只留前两条），运行 `./lesson_19`，确认主档仍读完三条，而交易计为两条。
2. 清空副本 `accounts.txt`（保留四条交易），运行 `./lesson_19`，确认空主档在首次 `READ` 就到达 EOF，之后交易仍被逐条读取。

每次运行都记录完整输出、退出码以及两个独立计数。约束：不要为“让另一个文件继续读”而清除或共用 EOF 标志；两个输入的 EOF、状态与计数必须互相独立。参考答案见 `answer.md`。

## 举一反三（不提供答案）

为客户主档、账户主档和交易文件增加第三个输入流，分别准备 3、2、1 条记录。为三个文件各自设置 `FILE STATUS`、EOF 标志和计数，以轮询方式读取，直到三个流都结束。夹具要覆盖“空文件”，并说明任一输入 OPEN 失败或 READ 出错时，程序如何关闭已打开的文件并返回非零码。

提交源码、编译运行命令、各夹具的实际输出与退出码，并说明你如何确认三个流的 EOF 互不影响。本题不提供答案，不做跨文件匹配或金额计算。
