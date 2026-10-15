# 第 21 课练习：SORT 与输入过程

本节只使用第 15–21 课讲过的内容：顺序文件 `SELECT`/`OPEN`/`READ`/`CLOSE`、`FILE STATUS`、`AT END`、`SORT` 与 `RELEASE`/`RETURN`、`PERFORM` 和 `DISPLAY`。

## 修改练习（会在 `answer.md` 提供参考答案）

两项都只改**临时目录里的夹具副本**，不要改动仓库内的 `accounts-unsorted.txt`。先准备临时目录：

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts-unsorted.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_21 lesson.cob
```

1. 交换副本的前两行。运行 `./lesson_21`，确认输出仍按账户号升序排列，并比较输入记录数与输出记录数。
2. 从原始夹具出发，在副本末尾追加一条 27 字符记录：账户号 `A000000006`、客户号 `C0001006`、余额数字 `000000001`。运行后确认新记录排在最后一行，且输入与输出计数都变为 `005`。

约束：不改 `lesson.cob`；追加的行必须是 27 字符。

每次运行保存完整标准输出，并指出 `RELEASE` 与 `RETURN` 分别在哪个过程执行、各自的 `AT END` 出现在哪里。参考答案见 `answer.md`。

## 举一反三（不提供答案）

给排序键加第二个字段：按账户号升序、同账户余额降序。至少准备两条账户号相同、余额不同的记录，记录修改后的 `SORT ... ON ASCENDING KEY ...` 声明与完整输出，并说明：只声明一个排序键时，程序是否依赖相同键记录的相对次序，为什么不能靠观察几组数据得出结论。

提交源码、编译运行命令、实际输出与退出码。本题不提供答案：不通过 `OCCURS` 先装入全部记录，也不改用 `USING`/`GIVING` 绕开本课的两个过程。
