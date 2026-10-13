# 第 08 课修改练习参考答案

本答案只回答 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。

## 修改期初余额

将 `lesson_08.cob` 中的初值改为：

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
```

前两笔处理后余额为 `2085.40`，所以原先因余额不足而拒绝的第 003 笔取款现在会被接受。新余额为 `2000.00 + 125.50 - 40.10 - 1500.00 = 585.40`。只有负数存款和未知代码被拒绝：

```text
PROCESSED=005
ACCEPTED=003
REJECTED=002
FINAL-BALANCE=0000585.40
```

## 取款金额恰好等于可用余额

在 `2100-LOAD-SAMPLE` 的 `WHEN 3` 分支，将金额改为：

```cobol
                   MOVE 1085.40 TO WS-TRANSACTION-AMOUNT
```

前两笔处理后余额为 `1085.40`。取款条件使用 `<= WS-CURRENT-BALANCE`，因此相等边界会接受该笔，并把余额降为零。之后负数存款和未知代码仍然拒绝：

```text
RECORD=003 CODE=W AMOUNT=+01085.40
RESULT=ACCEPTED REASON=WITHDRAWAL
PROCESSED=005
ACCEPTED=003
REJECTED=002
FINAL-BALANCE=0000000.00
```

这两个练习分别验证期初状态对期末计算的影响，以及取款金额与当前余额相等时 `<=` 比较的边界行为。
