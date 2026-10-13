# 第 02 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的三项修改，不提供举一反三练习答案。

将三条数据声明改为：

```cobol
       01 WS-BRANCH-CODE PIC 9(4) VALUE 3107.
       01 WS-CURRENCY-CODE PIC X(3) VALUE "EUR".
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0000000042".
```

语法检查、编译和运行命令与 README 相同。输出中对应结果为：

```text
BRANCH-CODE=3107
CURRENCY-CODE=EUR
CUSTOMER-NUMBER=0000000042
```

客户号保留 `PIC X(10)`，因为它是标识符；开头的零属于键值本身，不能因把字段当作数值而丢失。
