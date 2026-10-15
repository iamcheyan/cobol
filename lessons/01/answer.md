# 第 01 课修改练习参考答案

只回答 `exercise.md` 中的修改练习，不包含举一反三练习答案。

将源码中的：

```cobol
           DISPLAY "こんにちは、COBOL！".
```

改为：

```cobol
           DISPLAY "こんにちは、バッチチーム！".
```

运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_01 lesson.cob
./build/lesson_01
```

预期输出：

```text
こんにちは、バッチチーム！
```
