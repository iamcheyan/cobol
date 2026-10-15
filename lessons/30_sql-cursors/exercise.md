# 第 30 课练习：游标与结果集边界

先修：[第 29 课](../29_embedded-sql/README.md)的 GixSQL/SQLite 工具链已安装。本课源码见 [`lesson.cob`](./lesson.cob)，运行与观察见 [`README.md`](./README.md) 的“构建和运行”“空、单行、多行与 EOF”。

## 修改练习（答案见 [`answer.md`](./answer.md)）

两项都从**本课原始** `lesson.cob` 开始，各自独立完成，不要在前一题改过的源码上继续改。每次改完重新执行 `./build.sh run`；脚本会先删除本课自己的 `build/cursor.db`，再从 [`schema.sql`](./schema.sql) 重建两行夹具，所以结果可重复。

1. **反转结果顺序。** 把 `ACCOUNT-CURSOR` 声明里的排序改为 `ORDER BY ACCOUNT_NO DESC`。重新编译运行，比较输出顺序、`行数=` 与 EOF 处理。改动位置限于游标 `SELECT` 的 `ORDER BY` 子句，不要改 `FETCH` 循环或 `CLOSE`。

2. **限定到一个账户。** 从原始源码开始，在 `FROM ACCOUNT_SNAPSHOT` 之后增加一行 `WHERE ACCOUNT_NO = 'A000000002'`。确认只输出一个账户，并由下一次 `FETCH` 处理 EOF。改动位置限于游标 `SELECT` 的 `WHERE` 子句。

## 举一反三（无答案）

为 `ACCOUNT_SNAPSHOT` 增加 `ACCOUNT_STATUS`（例如 `ACTIVE` / `CLOSED`），只让游标返回活动账户。改造 [`schema.sql`](./schema.sql) 与 [`schema-empty.sql`](./schema-empty.sql) 使其仍可运行，然后：

- 用 `./build.sh run-empty` 观察**零行**结果，对照 [`expected-empty-output.txt`](./expected-empty-output.txt) 说明本工具链的空结果行为；
- 设计**一行**和**多行**两个夹具并分别运行，核对 `行数=` 与 EOF；
- 说明“`FETCH` 出错”与“`SQLCODE 100`”有什么区别，并确认任何成功打开的游标都会被 `CLOSE`。

本题不提供答案。请自己记录每条命令、实际输出、退出码，以及为什么你选的字段/规则能验证零行、一行、多行三种形态。
