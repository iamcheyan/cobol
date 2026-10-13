# 第 15 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三练习答案。

## 追加第五条文本记录

在 `transactions.txt` 最后一行之后追加：

```text
DAY-20261013|TXN-000005|D|0001234567|10.00
```

从本课目录运行程序时，新增行应完整显示，文件尾计数变为：

```text
RECORD=DAY-20261013|TXN-000005|D|0001234567|10.00
EOF=YES RECORDS=05
CLOSE=OK
```

该程序只读取文本，不会因为行中写了 `D` 或金额就更新账户余额。

## 读取空文件

在临时目录中创建空的 `transactions.txt`，从该目录运行已编译的程序：

```text
OPEN=OK
EOF=YES RECORDS=00
CLOSE=OK
```

空文件能成功打开；第一个 `READ` 即触发 `AT END`，不增加成功读取记录数。
