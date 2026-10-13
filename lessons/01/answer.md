# 第 01 课修改练习参考答案

只回答 `exercise.md` 中的修改练习，不包含举一反三练习答案。

将源码中的：

```cobol
           DISPLAY "Hello, COBOL!".
```

改为：

```cobol
           DISPLAY "Hello, batch team!".
```

运行：

```sh
cobc -fsyntax-only lesson_01.cob
cobc -x -Wall -o build/lesson_01 lesson_01.cob
./build/lesson_01
```

预期输出：

```text
Hello, batch team!
```
