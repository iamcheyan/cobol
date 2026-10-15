# 第 07 课：Paragraph 命名段落

> 状态：课程草稿。目录已确认；示例源码共 100 行固定格式，适用于 GnuCOBOL 3.2.0。

## 一、课程目标

学完本课后，你可以：

- 在 `PROCEDURE DIVISION` 中定义命名段落。
- 使用 `PERFORM paragraph-name` 执行段落，并在段落范围结束后返回调用处。
- 将批次主流程拆为初始化、处理和结束汇总阶段。
- 解释段落调用顺序如何影响共享的 `WORKING-STORAGE` 数据。
- 区分同一 COBOL 程序内的 `PERFORM` 与之后要学的 `CALL` 子程序。

## 二、段落和 PERFORM

段落名是过程名，写在 `PROCEDURE DIVISION` 中；仓库的固定格式要求段落名从 Area A 开始。`PERFORM 1000-INITIALIZE` 执行该段落中的语句，到下一个段落或过程范围末端后，控制返回 `PERFORM` 之后的语句。段落共享当前程序的 `WORKING-STORAGE`，不会因此创建独立程序或新的数据副本。

本例把 `0000-MAIN` 放在第一个位置。程序从主段落开始，依序 PERFORM 初始化、计算和汇总；`STOP RUN.` 在段落定义之前结束普通顺序执行，避免主流程落入后面的段落定义。三个被调用段落分别只负责一项工作。

段落名是团队可读性约定，不是业务逻辑。GnuCOBOL 手册允许由字母、数字、连字符和下划线组成的过程名，例如 `0100-Read-Transaction`；名字不能以连字符或下划线开头或结尾。

## 三、完整示例

[`lesson.cob`](./lesson.cob) 共 100 行。固定金额为期初 `1000.00`、存款 `125.50`、取款 `40.10`。程序在处理段落中计算期末余额 `1085.40`。

| 段落 | 职责 | 关键语句 |
|---|---|---|
| `0000-MAIN` | 按流程调用三个阶段；收到返回后报告批次完成 | `PERFORM ...`、`DISPLAY`、`STOP RUN` |
| `1000-INITIALIZE` | 清零期末余额字段 | `MOVE ZERO TO ...` |
| `2000-PROCESS` | 计算期末余额并显示 | `COMPUTE ...`、`DISPLAY` |
| `9000-FINALIZE` | 显示结束阶段与最终余额 | `DISPLAY` |

每个 `PERFORM` 使用的名字都对应一个段落定义。主流程先完成初始化，再计算，最后汇总；因此 `9000-FINALIZE` 能读到 `2000-PROCESS` 写入的共享余额字段。

## 四、执行顺序逐步解析

1. 程序到达第一个段落 `0000-MAIN`。
2. `PERFORM 1000-INITIALIZE` 输出 `段階=INITIALIZE`，并把期末余额置零；段落结束后返回主流程。
3. `PERFORM 2000-PROCESS` 输出 `段階=PROCESS`，计算 `1000.00 + 125.50 - 40.10`，输出 `0001085.40`；随后返回主流程。
4. `PERFORM 9000-FINALIZE` 输出 `段階=FINALIZE` 和共享字段 `最終残高=0001085.40`，再返回主流程。
5. 主流程输出 `バッチ=COMPLETE` 并执行 `STOP RUN.`。没有执行流落入后面的段落定义。

句点结束 COBOL 句子和尚未结束的语句作用域。本例在每个被调用段落的最后一条语句放句点；主段落的句点在 `STOP RUN` 后。

## 五、编译、运行和输出

程序使用固定 `VALUE` 样例，不读取终端、文件或数据库。编译产物写入临时目录：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_07" lesson.cob
"$scratch_dir/lesson_07"
```

GnuCOBOL 3.2.0 实际标准输出：

```text
段階=INITIALIZE
段階=PROCESS
期末残高=0001085.40
段階=FINALIZE
最終残高=0001085.40
バッチ=COMPLETE
```

本工作区语法检查、编译和运行返回码均为 0，输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；不是 COBOL 程序输出，触发组件尚未定位。

## 六、修改练习（有答案）

1. 修改期初余额为 `2000.00`、存款为 `250.00`、取款为 `40.10`，编译运行并核对新期末余额。
2. 将 `0000-MAIN` 中的 `PERFORM 2000-PROCESS` 移到 `PERFORM 1000-INITIALIZE` 之前。观察阶段输出顺序与最终余额，解释为什么初始化会覆盖处理段落写入的结果。

参考答案仅覆盖这两个修改练习，见 [`answer.md`](./answer.md)。

## 七、举一反三练习（无答案）

将小批次拆为四个命名段落：读取样例、校验交易码、计算余额、输出汇总。为主段落安排合理调用次序，并在每个阶段输出标记。重新排列其中两个 PERFORM，观察依赖顺序错误如何改变最终结果。仍使用固定值，不要引入文件、表格或 `CALL`。

本练习不提供答案。提交完整源码、编译命令和实际输出。

## 八、企业实战补充

批次程序常按初始化、输入、校验、业务处理、输出和结束清理划分过程。段落能让维护者快速定位职责，但所有段落仍共享程序数据；必须明确哪些段落读写哪些字段，并保持调用顺序与数据依赖一致。跨程序接口属于 `CALL` 的范围，不应把内部段落误当作独立子程序。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION Sections and Paragraphs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-Sections-and-Paragraphs)
- [GnuCOBOL Programmer’s Guide：Procedural PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Procedural-PERFORM)
