# 第 30 课练习：游标与结果集边界

## 修改练习（答案见 `answer.md`）

每次修改后重新运行 `./build.sh run`。脚本先删除本课自己的数据库，再从 `schema.sql` 重建两行夹具。

1. 把 `ACCOUNT-CURSOR` 的排序改为 `ORDER BY ACCOUNT_NO DESC`。比较输出顺序、行数和 EOF 处理。
2. 在游标查询中添加 `WHERE ACCOUNT_NO = 'A000000002'`。确认只返回一行，再由下一次 FETCH 处理 EOF。

## 举一反三（无答案）

将 `ACCOUNT_STATUS` 加入表结构及夹具，并仅提取活动账户。使用 `./build.sh run-empty` 验证空结果集，再设计单行和多行检查；讨论 FETCH 错误时怎样确保游标关闭。

本题不提供答案。
