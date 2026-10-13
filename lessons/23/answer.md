# 第 23 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。每项都从原始源码副本开始，再分别编译两个 COPYBOOK 消费程序。

## 1. 把首笔入账改为提款

在 `1100-POST-DEPOSIT` 中将：

```cobol
           MOVE "D" TO WS-TRANSACTION-TYPE
```

改为：

```cobol
           MOVE "C" TO WS-TRANSACTION-TYPE
```

首笔交易提款 125.50，第二笔再提款 25.25；初始余额 1000.00 足够支付两笔。输出中的两笔有效结果都仍为 `POSTED`，余额与摘要为：

```text
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0000849.25
SUMMARY POSTED=002 REJECTED=003
```

拒绝的三笔仍分别是 `INSUFFICIENT`、`BAD_TYPE` 和 `NO_ACCOUNT`。

## 2. 将最后一笔改为已知账户

在 `1500-POST-MISSING-ACCOUNT` 中，将：

```cobol
           MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT
```

改为：

```cobol
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
```

最后一笔成为一笔有效的 1.00 存款。摘要变为：

```text
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0001101.25
SUMMARY POSTED=003 REJECTED=002
```

拒绝只剩 `INSUFFICIENT` 和 `BAD_TYPE`。`account_report_23.cob` 使用同一个 `ACCOUNT-REC.CPY`，其独立输出仍为：

```text
ACCOUNT-REPORT NUMBER=A000000009 CUSTOMER=C0001009 BALANCE=0000020.00
```
