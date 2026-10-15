# 第 17 课练习：定长记录、字段偏移与字节数核对

本课练习只使用第 09、15–17 课讲过的方式：`SELECT` 与 `FD` 记录声明、`FILE STATUS`、`READ ... AT END`、`MOVE`、`WRITE`，以及固定格式的列位置约定。

## 修改练习（答案见 `answer.md`）

从本课原始 `lesson.cob` 与 `accounts.dat` 开始，把输出 FD 的字段声明顺序改为：账户号在输出记录字节 1–10、客户号在 11–18、余额在 19–27，即让输出记录与输入记录布局相同。

约束：

- 只改 `FD BALANCE-FILE` 下 `01 FD-BALANCE-RECORD` 的三条 `05` 声明，顺序为 账户号 → 客户号 → 余额。
- 每条 `PIC` 宽度不变（`X(10)`、`X(8)`、`9(7)V99`）。
- 三条 `MOVE` 语句、输入 FD 和所有段落逻辑都不改。

改完重新编译并运行（工作目录必须能找到 `accounts.dat`，所以先复制夹具到运行目录）：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_17 lesson.cob
cp accounts.dat build/
(cd build && ./lesson_17)
wc -c build/balances.dat
cmp accounts.dat build/balances.dat
rm -rf build
```

需要提交：

- 修改后的 `01 FD-BALANCE-RECORD` 声明片段。
- 标准输出（应仍为 5 行）。
- `wc -c build/balances.dat` 的输出与 `cmp` 的退出码。
- 前两条输出记录各自的 27 个字节，写成三组（账户号 / 客户号 / 余额）。

独立核算依据：每条记录仍是 `10 + 8 + 9 = 27` 字节，3 条共 `81` 字节；字段名没有改变，所以逐条输出的账户号、客户号、余额数值应与基线一致，只有它们在记录内的字节位置变化。

## 举一反三（不提供答案）

为一份 32 字节客户定长记录设计接口：8 字节客户号、20 字节名称、4 字节状态。自己按字节拼接两条连续记录（不要插入换行符），沿用本课相同的打开、读取与写出方式，逐条读取并输出客户号与状态。

需要提交：字段偏移表、输入文件总字节数与实际 `wc -c` 输出、运行输出，以及“行结束符会怎样破坏定长边界”的说明。

不要改用 `LINE SEQUENTIAL`，不要引入数据库，也不要求未学过的语法。本题不提供答案。
