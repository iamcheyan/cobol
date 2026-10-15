# 第 12 课练习：INDEXED BY

本节只使用第 11–12 课讲过的内容：固定格式声明、`OCCURS` 表格、普通数字下标、`INDEXED BY` 索引与 `SET`/`PERFORM UNTIL`。不要使用 `SEARCH`、`SORT`、文件或数据库。

## 修改练习（参考答案见 `answer.md`）

基线为本课原始 [`lesson.cob`](./lesson.cob)。第 2 步在第 1 步的源码上继续；两步都只做题目指定的改动。

### 第 1 步：把账户表扩到第五项

把 `WS-ACCOUNT-ENTRY OCCURS 4 TIMES` 与 `WS-LAST-ACCOUNT` 的初值一起扩到 5，并在 `1000-LOAD-ACCOUNTS` 末尾追加第五笔：账号 `0005550001`、余额 `75.00`。

约束：

- 只改这三处（容量、已装入项数、追加一笔装载），前四笔账户不动。
- 装载段落继续用普通数字下标，遍历段落继续用 `WS-ACCOUNT-IDX`，不改循环结构。

依次运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
```

写出完整的实际标准输出与退出码，并说明为什么前四行逐字节不变。

### 第 2 步：观察越界边界

在第 1 步的结果上，**只**把 `WS-LAST-ACCOUNT` 再改为 `6`（`OCCURS` 仍为 5，第五项仍是最后装入的一项）。

先写下你的预测（标准输出行数、最后一行内容、退出码），再用下面两条命令验证：

```sh
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT -o build/lesson_12_checked lesson.cob
./build/lesson_12_checked
```

`-fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT` 请求 GnuCOBOL 在运行期检查下标/索引边界；默认编译不做这项检查。

请给出：两次运行的完整标准输出、标准错误和退出码，并解释为什么未开启检查时程序“看起来成功”，以及这个选项为什么能在运行期发现问题。

## 举一反三（不提供答案）

为五笔账户建立 `OCCURS` 表格并声明一个 `INDEXED BY` 索引：

1. 用普通数字下标装入至少三笔账户（账号、余额自定）。
2. 用索引从第 1 项遍历到最后一个已装入项，输出账号、余额和处理件数。
3. 说明表格容量、已装入项数、索引当前项与循环终点之间的关系。
4. 说明你会用哪条命令验证“循环终点超过容量”时会被发现，并记录实际结果。

限制：只使用第 11–12 课的语法，不要使用 `SEARCH`、`SORT`、文件或数据库。自己记录编译命令、实际输出、退出码与验证方法。
