# 第 31 课修改练习参考答案

本答案只覆盖 `exercise.md` 的两项修改练习，不提供举一反三题答案。

## 1. 让第二条账户匹配

把 `snapshot.txt` 第二行最后 9 位改为：

```text
000087500
```

数据库余额为 875.00，对应的 `CHANGED` 行变为：

```text
MATCH ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
```

摘要变为 `SUMMARY ROWS=003 MATCH=002 CHANGED=000 FILE_ONLY=001`；`differences.txt` 只保留 `A000000003` 的 `FILE_ONLY` 行。

## 2. 在数据库中补齐第三个账户

在 `schema.sql` 的 `ACCOUNT_SNAPSHOT` 插入语句中增加：

```sql
('A000000003', 'C0001003', 25.00)
```

第三个文件键变为 `MATCH`，摘要变为 `SUMMARY ROWS=003 MATCH=002 CHANGED=001 FILE_ONLY=000`；差异文件只保留 `A000000002` 的 `CHANGED` 行。
