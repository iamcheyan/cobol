# 第 30 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三题答案。

## 1. 反转结果顺序

将游标声明中的排序改为：

```sql
ORDER BY ACCOUNT_NO DESC
```

预期先读到 `A000000002`（余额 `00875.00`），再读到 `A000000001`（余额 `01250.75`）。之后仍出现 `FETCH=EOF SQLCODE=100`，并输出 `ROWS=002`。

## 2. 限定到一个账户

在 `FROM ACCOUNT_SNAPSHOT` 后加入：

```sql
WHERE ACCOUNT_NO = 'A000000002'
```

输出一行：

```text
ROW=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
```

下一次 FETCH 返回 SQLCODE 100，程序输出 `ROWS=001`，然后关闭游标并断开连接。
