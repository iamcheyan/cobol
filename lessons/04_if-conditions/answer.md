# 第 04 课修改练习参考答案

本答案只回答 [`exercise.md`](./exercise.md) 中的修改练习，不提供举一反三练习的答案。

## 改动方式

每个场景都从原始 `lesson.cob` 重新开始，只改下面两个 `VALUE` 子句的初值，其余源码（`PIC`、`SIGN IS LEADING SEPARATE CHARACTER`、上限初值、关系运算符、嵌套顺序、`DISPLAY` 文本）保持不变：

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

命令：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_04 lesson.cob
./build/lesson_04
echo $?
```

七个场景的 `cobc` 返回码与运行退出码都是 `0`；拒绝是业务判定，不影响退出码。

## 场景 1：金额 `0.00`、状态 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

原因：最外层 `IF WS-TRANSACTION-AMOUNT <= ZERO` 为真（`0.00` 不大于零），直接输出拒绝，`ELSE` 内的两处检查都不执行。

## 场景 2：金额 `-0.01`、状态 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=-0000000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

原因：与场景 1 同一个比较。`S9(7)V99` 配合 `SIGN IS LEADING SEPARATE CHARACTER` 能保存负值，`DISPLAY` 时前导 `-` 可见；数值比较按实际代数值进行，因此 `-0.01 <= ZERO` 为真。

## 场景 3：金额 `0.01`、状态 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.01
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

原因：`0.01 <= ZERO` 为假，下界通过；`0.01 > 1000.00` 为假，上限通过；状态为 `"A"`。三条规则全部通过，因此原因是 `WITHIN_RULES`。这一行与场景 1 只差 `0.01`，分叉点就是 `<=` 这个运算符。

## 场景 4：金额 `1000.00`、状态 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.00
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

原因：上限规则用的是严格大于 `>`，`1000.00 > 1000.00` 为假，所以端点被包含，继续进入状态检查并接受。原因是 `WITHIN_RULES`，与场景 3 相同。

## 场景 5：金额 `1000.01`、状态 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_OVER_LIMIT
```

原因：正数检查通过，`1000.01 > 1000.00` 为真，在第二层被拒绝，第三层的状态检查不执行。这一行与场景 4 只差 `0.01`，分叉点是 `>`。

## 场景 6：金额保持 `125.50`、状态改为 `"I"`

这个场景只改一处，用来和原始初值对照——金额完全相同，只有状态不同：

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
```

金额子句保持原始初值：

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=+0000125.50
上限金額=0001000.00
判定=REJECTED
理由=ACCOUNT_INACTIVE
```

原因：金额两项检查都通过（和原始初值一样），进入最内层 `IF WS-ACCOUNT-STATUS = "A"`；字符 `"I"` 不等于 `"A"`，走最内层 `ELSE`。原因文本是固定的 `ACCOUNT_INACTIVE`，程序不区分具体是哪种非 `A` 状态。

## 场景 7：金额 `-5.00`、状态 `"I"`

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -5.00.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=-0000005.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

原因：两个条件都不合规，但三层判定是嵌套的，最外层 `<= ZERO` 为真就立即输出原因，第三层的状态比较没有执行，所以只输出 `AMOUNT_NOT_POSITIVE`。这一条验证了“只报首个失败规则、优先级由嵌套顺序决定”的契约。

## 逐题回答

1. `IF WS-TRANSACTION-AMOUNT <= ZERO`。`0.00` 和 `-0.01` 满足该条件，`0.01` 不满足；`0.01` 的差距与 `<=` 一起构成下界分叉。
2. 原因相同，都是 `WITHIN_RULES`。因为上限用的是严格大于，`1000.00 > 1000.00` 为假，端点被包含。
3. `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT`。`1000.01 > 1000.00` 为真，在第二层被拒绝。
4. 金额两项检查都通过，进入第三层 `IF WS-ACCOUNT-STATUS = "A"`；`"I"` 与 `"A"` 不相等，走最内层 `ELSE`，理由 `ACCOUNT_INACTIVE`。
5. 因为三层是嵌套而非平级：外层条件为真时直接输出原因，不再进入 `ELSE`；状态比较（第三层）根本没有执行，所以只输出一条理由。
