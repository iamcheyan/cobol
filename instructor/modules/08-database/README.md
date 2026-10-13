# 讲师包：模块08 参考实现与根因

本目录只供讲师/自学者对照，**不进入学员发放包**。参考实现覆盖 08.1–08.4：

| 源文件 | 覆盖 | 要点 |
|---|---|---|
| `ESQL-PROBE.COB` | 08.1 / 08.2 | Host/Indicator、NULL vs 空串、`02000` vs 真实错误、游标、重开游标、`23505` |
| `SNAPSHOT.COB` | 08.2 / 08.3 | 游标抽取 27B 快照、元数据、27B 上游有界双指针突合 |
| `APPLY.COB` | 08.4 | 幂等记账、SAVEPOINT 处理 `23505`、`batch_commit`、COMMIT/ROLLBACK |

学员起始代码：[starter/DBBATCH.COB](../../../curriculum/modules/08-database/starter/DBBATCH.COB)
（可构建、返回 RC12、不发布）。

## 构建/运行

```bash
lab=$(cd curriculum/modules/08-database && pwd)
bash "$lab/scripts/build.sh" /tmp/probe "$(pwd)/instructor/modules/08-database/ESQL-PROBE.COB"
bash "$lab/scripts/check.sh"
```

## 根因与提示阶梯

1. **指示器**：GixSQL 固定 commit 需要 `PIC S9(4) COMP` 指示器，且必须应用 P1 的
   `gixsql-cursor-null.patch`，否则 NULL 指示器错误地返回 0。提示：先打印指示器值。
2. **区分无数据与错误**：`FETCH`/`SELECT INTO` 耗尽为 `02000`；不要用 `SQLCODE=100`
   之外的哨兵。提示：把 `02000` 与其它 SQLSTATE 分别打印。
3. **72 列**：多列 `INSERT` 排到第 73 列会被截断，标识符受损 → `42601`。提示：`awk
   'length($0)>72'`。
4. **PostgreSQL 事务中止**：`23505` 之后同一事务内任何语句得 `25P02`。必须用
   `SAVEPOINT`/`ROLLBACK TO SAVEPOINT` 局部恢复。提示：先看第二个错误的 SQLSTATE。
5. **重复分类**：本运行内重复（`applied_run_id == run_id`）应 RC8 回滚；历史重试应 SKIP。
6. **提交后重跑**：最终以独立 psql 连接的余额/账本/提交行数为准，不信 COBOL DISPLAY。
7. **gixsql 收尾段**：游标初始化段生成在最后一个用户段落之后，最后一个用户段落必须是
   无人 `PERFORM` 的 `9100-FAIL`，否则 `PERFORM` 收尾段行为异常。

## 评分点（对应制作标准第 8 节硬门禁）

- 08.1：NULL/指示器/`02000`/`23514`/`23505` 各有实测输出。
- 08.2：游标抽取行数、NULL/空串计数正确，且重开游标回归通过。
- 08.3：快照 27B 与独立 oracle 一致；差异类型/字段/偏移正确；RC4/RC0 正确。
- 08.4：首次余额/账本/提交正确；重试不重复；运行内重复 RC8 回滚；连接失败 RC12。
- 失败不发布：学员未完成源 RC12 时不得出现输出目录。
