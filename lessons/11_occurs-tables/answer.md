# 第 11 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三练习答案。

## 修改第四项金额

把 `1000-LOAD-TABLE` 中对应 MOVE 改为：

```cobol
           MOVE 35.00 TO WS-TXN-AMOUNT(4)
```

第四项显示金额更新，其他项和处理数不变；余额增加 `15.00`：

```text
ENTRY=04 CODE=C AMOUNT=00035.00
PROCESSED=004
FINAL-BALANCE=0001120.40
```

## 添加第五项

扩大固定表格和处理上界：

```cobol
          05 WS-TRANSACTION-ENTRY OCCURS 5 TIMES.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
```

在第四项装载语句后继续装入第五项：

```cobol
           MOVE "C" TO WS-TXN-CODE(5)
           MOVE 10.00 TO WS-TXN-AMOUNT(5).
```

第五项成为最后一次循环处理；它把余额从 `1105.40` 增加到 `1115.40`：

```text
ENTRY=05 CODE=C AMOUNT=00010.00
ACTION=CREDIT
PROCESSED=005
FINAL-BALANCE=0001115.40
```

声明容量、装入下标和循环上界都扩展到 5，因此程序没有访问未分配的表项。
