# 第 09 课修改练习参考答案

本答案只回答 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。

## 修改账户号

在 `WS-ACCOUNT-INFO` 中更新初值：

```cobol
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0007654321".
```

单独字段和组项的对应输出变为：

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

账户号是 `WS-TRANSACTION-RECORD` 中按声明顺序排列的一个基本项，所以修改它也会改变整组显示中的相应字符。

## 重命名交易状态字段

将交易子组中的字段定义改为：

```cobol
             10 WS-TXN-STATUS PIC X(7) VALUE "PENDING".
```

并将显示语句改为：

```cobol
           DISPLAY "取引状態=" WS-TXN-STATUS
```

输出仍为：

```text
口座状態=A
取引状態=PENDING
グループデータ=[C0001042ADA LOVELACE0001234567ATXN-00000001D0012550PENDING]
```

数据名的变化不会改变字段宽度、初值或声明位置，所以组项字符内容不变。`WS-TXN-STATUS` 现在名称唯一，可以直接引用；`WS-STATUS` 仍用于账户状态。
