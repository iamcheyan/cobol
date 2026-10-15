# 第 31 课练习：文件快照与数据库快照的差异

本节只使用第 31 课讲过的内容：GixSQL 预编译、宿主变量、`SQLCODE` 分支、`RECON_RESULT` 结果表，以及第 30 课为止的文件读写与游标。

## 修改练习（会在 `answer.md` 提供参考答案）

两项都从**原始夹具**开始（`snapshot.txt` 三行原样、`schema.sql` 原样、`lesson.cob` 不改）。先运行一次保存基准：

```sh
./build.sh run
echo $?
cat differences.txt
sqlite3 build/lesson31.db "SELECT ACCOUNT_NO, FILE_STATUS FROM RECON_RESULT;"
```

脚本每次都会重建 `build/lesson31.db` 并截断 `differences.txt`，所以不必手工清理；但**做完一题要先把夹具改回原样再做下一题**，两题不允许叠加。

1. **文件侧金额改动。** 把 `snapshot.txt` 第二行的金额从 `000010000` 改成 `000087500`（行仍是 27 字节、其余字段不动）。重新运行，核对：第二行的分类、标准输出的 `BALANCE=`、摘要里的三个计数、`differences.txt` 的行数与内容。
2. **数据库侧增行。** 在 `schema.sql` 的 `ACCOUNT_SNAPSHOT` 插入语句末尾增加两行：`('A000000003', 'C0001003', 25.00)` 与 `('A000000099', 'C0001099', 500.00)`（注意：增加的是插入列表的元素，前一行末尾要补逗号，最后一行用分号）。重新运行，核对：第三行的分类、摘要计数、`differences.txt` 是否为空，以及 `A000000099` 在标准输出、差异文件、`RECON_RESULT` 三处是否出现。

约束：不改 `lesson.cob`、不改 `build.sh`；`snapshot.txt` 每行保持 27 字节（金额 9 位、右对齐补零）；每题记录退出码，并用 `sqlite3` 读出修改后的 `RECON_RESULT` 行数。参考答案见 [`answer.md`](./answer.md)。

## 举一反三（不提供答案）

把核对改成**双向**：用第 30 课的游标反向扫描 `ACCOUNT_SNAPSHOT`，对只存在于数据库中的账户增加 `DB_ONLY` 分类与计数，并让结果表的行数关系（文件行数 = 结果表行数 = 三类之和）在双向版本里也能独立核对。同时给输入注入重复账户键，定义它属于业务拒绝还是系统故障、拒绝的记录如何不写入 `RECON_RESULT`，并给出"批次失败后如何重跑而不留脏数据"的清理方案与验证方法。

提交改动后的 `lesson.cob`、`schema.sql`、夹具、运行命令，以及正常路径、`DB_ONLY` 路径、重复键路径三种情况的实际输出、数据库前后状态与退出码。本题不提供答案。
