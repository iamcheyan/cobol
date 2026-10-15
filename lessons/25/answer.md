# 第 25 课修改练习参考答案

本答案只覆盖 `exercise.md` 中的两项修改练习，不提供举一反三练习答案。每次都要把 `lesson_25.cob`、`add_one_25.cob` 和 `report_binary_25.cob` 一起重新编译。

## 1. 把子程序增量改为 2

将子程序改为：

```cobol
           ADD 2 TO AMOUNT-ARGUMENT
```

并在 `1100-TEST-REFERENCE` 中把期望值改成 12。调用结果：

```text
呼出側=呼出後 方式=BY REFERENCE 値=000000012 確認=合格
...
被呼出側=加算後 値=000000022
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
集計 合格=003 不合格=000
MODE REFERENCE=001 CONTENT=001 値=001
```

`ADD-ONE` 也会把 BY CONTENT 收到的临时副本从 20 改成 22，但调用方原字段仍是 20。

## 2. 将第二次调用改为 BY REFERENCE

在 `1200-TEST-CONTENT` 中把调用语句改成：

```cobol
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
```

同时把该段期望值改为 21，并把 `WS-MODE` 改为 `BY REFERENCE`。程序输出该字段从 20 变为 21；模式计数为：

```text
呼出側=呼出後 方式=BY REFERENCE 値=000000021 確認=合格
集計 合格=003 不合格=000
MODE REFERENCE=002 CONTENT=000 値=001
```

这项修改表明传递方式决定子程序对调用方存储的影响；只改变期望值而不更新模式标签，会让显示和分类计数误导读者。
