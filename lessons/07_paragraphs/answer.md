# 第 07 课修改练习参考答案

本答案只回答 `exercise.md` 的两个修改练习，不提供举一反三练习答案。两项修改各自从原始 `lesson.cob` 开始，编译运行命令为：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

## 修改金额

将字段初值改为：

```cobol
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 2000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.00.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
```

处理段落计算 `2000.00 + 250.00 - 40.10 = 2209.90`。关键输出为：

```text
期末残高=0002209.90
最終残高=0002209.90
```

阶段顺序仍为初始化、处理、结束汇总。

## 调换初始化和处理顺序

在主段落中先执行 `PERFORM 2000-PROCESS`，再执行 `PERFORM 1000-INITIALIZE`，最后执行 `PERFORM 9000-FINALIZE`。输出关键顺序变成：

```text
段階=PROCESS
期末残高=0001085.40
段階=INITIALIZE
段階=FINALIZE
最終残高=0000000.00
バッチ=COMPLETE
```

`WORKING-STORAGE` 字段由这些段落共享。处理段落先写出 `1085.40`，之后初始化段落将同一字段清零，因此汇总读到 `0000000.00`。这个结果展示了段落职责之间的调用顺序依赖。
