# 第 04 课修改练习参考答案

本答案覆盖 `exercise.md` 的五个修改场景，不提供举一反三练习的答案。每次只改初值，其他源码保持不变。

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.00.
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
```

输出决定：

```text
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -0.01.
```

输出决定仍为 `REJECTED` / `AMOUNT_NOT_POSITIVE`。有符号 PIC 允许负数参与数值比较；`amount <= ZERO` 为真。

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.00.
```

输出决定为 `ACCEPTED` / `WITHIN_RULES`。金额大于零；金额严格大于上限的条件为假，因此等于上限可继续到状态检查。

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.01.
```

输出决定为 `REJECTED` / `AMOUNT_OVER_LIMIT`。金额正数检查通过，严格大于上限的条件为真。

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 50.00.
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
```

输出决定为 `REJECTED` / `ACCOUNT_INACTIVE`。金额检查均通过后，状态与字符 `A` 不相等，进入最内层 `ELSE`。
