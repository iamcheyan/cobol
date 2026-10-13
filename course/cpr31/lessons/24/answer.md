# 第 24 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。每次修改后都将主程序和子程序一起编译。

## 1. 把校验上限提高到 1500.00

在 `amount_check_24.cob` 中将条件改为：

```cobol
               WHEN LK-AMOUNT > 1500.00
```

金额 `1000.01` 从 `LIMIT-EXCEEDED` 变成 `VALID`；`9999999.99` 仍超过新业务上限。结果为：

```text
CALL=BEGIN AMOUNT=0001000.01
CALL=RETURN STATUS=VALID
...
CALL=BEGIN AMOUNT=9999999.99
CALL=RETURN STATUS=LIMIT-EXCEEDED
CALLER=RESUMED
SUMMARY CHECKED=008 VALID=006 REJECTED=002
REJECT ZERO=001 OVER_LIMIT=001
```

要让主程序使用新规则，必须重新编译并链接两个源文件。

## 2. 把零金额案例改为一分钱

在 `1200-CHECK-ZERO-AMOUNT` 中使用：

```cobol
           MOVE 0.01 TO WS-AMOUNT
```

正一分钱满足 `> ZERO` 且不超过 1000.00，因此返回 `VALID`。最终计数为：

```text
CALLER=RESUMED
SUMMARY CHECKED=008 VALID=006 REJECTED=002
REJECT ZERO=000 OVER_LIMIT=002
```

其他输入结果保持不变；主程序仍通过 `CALL` 交给 `CHECK-AMOUNT` 判断。
