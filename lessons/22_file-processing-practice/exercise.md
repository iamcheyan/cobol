# 第 22 课练习：综合批次输入变化

本节只使用第 15–22 课讲过的内容：顺序文件读写、定长记录、`SORT`/`RELEASE`/`RETURN`、顺序键匹配、`EVALUATE`/`IF`、`FILE STATUS` 与 `RETURN-CODE`。

## 修改练习（会在 `answer.md` 提供参考答案）

两项都在**夹具副本**上做，不要改动仓库内的夹具；每次运行都从副本重新开始，因为程序用 `OPEN OUTPUT` 覆盖结果文件。先准备 `build/` 工作目录：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_22 lesson.cob
cp accounts.txt transactions-unsorted.txt build/
cp build/transactions-unsorted.txt build/orig-transactions.txt   # 留一份原始交易副本便于复位
```

1. 在 `build/transactions-unsorted.txt` 里把账户号 `A000000004` 的交易记录替换为账户号 `A000000009`，其余十字符字段不动。运行 `(cd build && ./lesson_22)`，检查接受、拒绝与仅主档计数，并逐行核对两个结果文件的内容。
2. 用 `build/orig-transactions.txt` 复位交易夹具，再把 `A000000007` 记录的金额字段改成九位数字 `000000001`。运行后确认原来的金额拒绝变为接受，检查计数与两个结果文件。

约束：不改 `lesson.cob`；每条记录必须保持其输入宽度（交易 20 字符、主档 27 字符）。

每次运行保存完整标准输出与两个结果文件，并说明：为什么 `SORT` 让输入文件的行顺序不影响匹配结果；`RELEASE` 与 `RETURN` 分别在哪个过程执行。用计数不变量自查两题的结果。参考答案见 `answer.md`。

## 举一反三（不提供答案）

给夹具增加同一主档账户的第二笔交易，设计新的匹配规则让一条主档记录能匹配同一账户的多笔交易；定义两笔交易的输出顺序、余额更新与错误处理，并用连续重复交易、缺少账户、主档 EOF 和错误金额验证。

提交源码、编译运行命令、实际标准输出与两个结果文件内容，并说明程序中主档读取位置相比本课发生了哪些变化。本题不提供答案：不把全部记录读入 `OCCURS` 表，也不省略接受/拒绝文件内容。
