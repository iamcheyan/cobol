# 第 07 课练习：Paragraph

本节只使用第 07 课讲过的内容：`PROCEDURE DIVISION` 中的命名段落、`PERFORM 段落名`、`MOVE`、`COMPUTE`、`DISPLAY` 和 `STOP RUN`。所有输入都是程序内固定数据。

## 修改练习（会在 `answer.md` 提供参考答案）

两项修改各自从本课原始 `lesson.cob` 开始，不要叠加。

1. 金额修改：把 `WS-OPENING-BALANCE` 的初值改为 `2000.00`，把 `WS-DEPOSIT` 改为 `250.00`，`WS-WITHDRAWAL` 保持 `40.10`。重新编译运行，核对新的期末余额与最终余额。
2. 调用顺序修改：在 `0000-MAIN` 中，把 `PERFORM 2000-PROCESS` 移到 `PERFORM 1000-INITIALIZE` 之前，其余语句不动。记录阶段标记与最终余额，并解释处理段落写入的值为什么会被后续的初始化覆盖。

每项修改后运行：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

参考答案见 `answer.md`，只覆盖以上两项修改练习。

## 举一反三（不提供答案）

设计四个命名段落：读取样例、校验交易码、计算余额、输出汇总，并在主段落中安排调用顺序。只用固定 `VALUE` 数据，不使用文件、表格、循环或 `CALL`。

然后调换其中两个有数据依赖的段落（例如先校验后读取，或先汇总后计算），记录输出差异，并说明这段依赖关系在什么条件下会出错。提交完整固定格式源码、编译命令、调换前后的实际输出与退出码。本题不提供答案。
