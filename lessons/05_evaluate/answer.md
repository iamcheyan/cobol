# 第 05 课修改练习参考答案

只回答 `exercise.md` 里的修改练习，不含举一反三（支付方式分类）的答案。基线是本课原始 `lesson.cob`。

## 改动

在 `EVALUATE WS-TRANSACTION-CODE` 中，`WHEN "T"` 分支的 `DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"` 之后、`WHEN OTHER` 之前插入：

```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
```

并把数据项初值改为 `F`：

```cobol
       01 WS-TRANSACTION-CODE PIC X VALUE "F".
```

其余分支、`WHEN OTHER` 的输出与固定格式均不变。改动后的 `EVALUATE` 段落应为：

```cobol
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
```

## 运行

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

## 预期输出

```text
取引参照番号=TXN-00000001
取引コード=F
分類=FEE
処理=CHARGE_FEE
```

`cobc -fsyntax-only` 与编译退出码为 `0` 且无诊断，进程退出码为 `0`。第 1 行参考号不变，因为该字段没有被修改。

## 边界核对（确认未改动 `WHEN OTHER`）

保留新增的 `WHEN "F"` 分支，把初值改回 `X` 并重新编译运行：

```text
取引参照番号=TXN-00000001
取引コード=X
分類=UNKNOWN
処理=REJECT_FOR_REVIEW
```

`X` 不等于 `D`/`W`/`T`/`F` 中任何一个值，因此仍由 `WHEN OTHER` 兜底，说明新增分支只影响 `F`，没有改变未知码路径。`REJECT_FOR_REVIEW` 只是程序输出的处理标签，本课没有实现真实拒绝流程。
