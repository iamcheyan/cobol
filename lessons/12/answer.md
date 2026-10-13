# 第 12 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三练习答案。

## 修改第二个余额

将装入语句改为：

```cobol
           MOVE 275.25 TO WS-ACCOUNT-BALANCE(2)
```

索引遍历的顺序与处理数不变，第二项显示为：

```text
ACCOUNT=0007654321 BALANCE=0000275.25
PROCESSED=004
```

## 扩展到第五项

声明第五个出现项、更新已装入项数，并在 `1000-LOAD-ACCOUNTS` 中追加装入：

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
       01 WS-LAST-ACCOUNT PIC 9 VALUE 5.
```

```cobol
           MOVE "0005550001" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

索引循环会继续到第五项，然后输出处理数 `005`：

```text
ACCOUNT=0005550001 BALANCE=0000075.00
PROCESSED=005
```

容量、已装入条目数和循环终点都扩为 5；循环仍从第 1 项开始，并在索引越过最后一项前结束。
