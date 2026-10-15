# 第 29 课修改练习参考答案

本文件只回答 `exercise.md` 的两项修改练习，不提供举一反三题答案。

## 1. 查询第二个账户

在 `MAIN-PROCEDURE` 中把第一次赋值改为：

```cobol
MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

预期查询行：

```text
LOOKUP=A000000002 STATUS=FOUND CUSTOMER=C0001002 BALANCE=00875.00
```

`SELECT ... INTO` 将 `ACCOUNT_NO`、`CUSTOMER_ID` 和 `BALANCE` 分别写入对应宿主变量。

## 2. 将第二次查询改为已有账户

把第二次赋值改为：

```cobol
MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

两次查询都会显示 `STATUS=FOUND`。第二次查询的 SQLCODE 从 100（无匹配行）变为 0（查询成功）。连接和断开输出保持成功状态。
