# 第 01 课修改练习参考答案

只回答 `exercise.md` 中的修改练习，不包含举一反三练习答案。

从原始 `lesson.cob` 开始，将源码中的：

```cobol
           DISPLAY "こんにちは、COBOL！".
```

改为：

```cobol
           DISPLAY "こんにちは、バッチチーム！".
```

只改这一处字符串字面量，其余程序结构与固定格式不变。运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_01 lesson.cob
./build/lesson_01
```

预期输出：

```text
こんにちは、バッチチーム！
```

进程退出码仍为 `0`；`cobc -fsyntax-only` 返回 `0` 且无诊断。
