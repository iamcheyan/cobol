# 第 06 课：PERFORM 重复处理

> 状态：课程草稿。目录已确认；源码共 100 行固定格式，已用 GnuCOBOL 3.2.0 编译运行。

## 一、课程目标

学完本课后，你可以：

- 使用 `PERFORM VARYING ... FROM ... BY ... UNTIL` 重复执行一段处理。
- 解释初始值、步长、退出条件如何决定迭代次数。
- 说明本例的 `UNTIL index > last` 为什么会包含等于 `last` 的那次迭代。
- 验证零次、一次、三次和超过样例数的边界行为。
- 用 `END-PERFORM` 标出循环范围，并统计实际执行次数。

## 二、PERFORM VARYING 工作方式

本课使用的语句形状：

```cobol
PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
    UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
    ...loop body...
END-PERFORM
```

- `FROM 1` 将循环索引初始设为 1。
- `BY 1` 指定每轮完成后索引递增 1。
- `UNTIL index > last` 是退出条件。默认先检查条件再执行循环体；条件为真时不再进入循环体。
- 由于使用严格大于，索引等于 `last` 时条件仍为假，该轮会执行；下次递增后才退出。
- `END-PERFORM` 结束循环作用域。循环体里的句点可能提前关闭更大的句子作用域，所以本例把句点放在循环和输出都结束后的 `STOP RUN.`。

GnuCOBOL Programmer’s Guide 的 `PERFORM VARYING` 示例也使用 `FROM 1 BY 1 UNTIL i > n`。本例进一步实测 `last=0` 时循环体执行 0 次、`last=1` 时执行 1 次。

## 三、固定样例程序

[`lesson.cob`](./lesson.cob) 共 100 行。课程尚未讲解 `OCCURS` 表格，所以示例暂时用 `EVALUATE` 按索引选择三笔固定样例：存款、取款和转账。每轮显示一笔样例，然后用 `COMPUTE` 将已处理次数加一。

| 字段 | PIC / 初值 | 用途 |
|---|---|---|
| `WS-LAST-SAMPLE` | `9` / `3` | 最后一个要处理的样例序号，包含此序号 |
| `WS-SAMPLE-INDEX` | `9` / `0` | `PERFORM VARYING` 控制字段；执行时从 1 起步 |
| `WS-PROCESSED-COUNT` | `9(3)` / `0` | 每轮执行后递增，最后用于报告实际次数 |

固定样例与索引的对应关系：1 是 `D` / `125.50`；2 是 `W` / `040.10`；3 是 `T` / `075.00`。若把最后序号改成 4，循环仍会执行第四轮，`EVALUATE` 的 `WHEN OTHER` 会显示 `例=UNMAPPED`。这说明循环边界由 `WS-LAST-SAMPLE` 控制，并不会自动检查样例是否存在。

## 四、程序逐步解析

1. `WORKING-STORAGE SECTION` 初始化最后序号和处理计数。索引的实际起始值由 `FROM 1` 设置。
2. 第一条 `DISPLAY` 显示配置的最后序号。
3. `PERFORM VARYING` 在执行循环体之前设置索引并检查 `UNTIL` 条件。
4. 循环中的 `EVALUATE WS-SAMPLE-INDEX` 根据当前索引显示第 1、2、3 笔固定记录；其他索引显示 `UNMAPPED`。
5. 每轮完成样例选择后，`COMPUTE` 将 `WS-PROCESSED-COUNT` 加 1。
6. 循环结束后显示处理次数。若 `last=0`，第一次检查即满足 `1 > 0`，循环体不执行，计数保持 `000`。
7. `STOP RUN.` 正常结束程序。

## 五、编译、运行和默认输出

程序不读取键盘、文件或数据库。临时目录存放可执行文件：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_06" lesson.cob
"$scratch_dir/lesson_06"
```

默认 `WS-LAST-SAMPLE` 为 3，实际标准输出：

```text
最終サンプル番号=3
例=001 符号=D 額=125.50
例=002 符号=W 額=040.10
例=003 符号=T 額=075.00
処理件数=003
```

本工作区语法检查、编译和运行返回码均为 0，标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`，不是 COBOL 程序输出，触发组件尚未定位。

## 六、修改练习（有答案）

修改 `WS-LAST-SAMPLE` 的 `VALUE`，每次从原始源码开始，分别设置为 `0`、`1`、`3`、`4`。重新编译并运行，记录显示了几笔样例、`SAMPLES-PROCESSED` 是多少、最后一个索引是否有固定样例。答案见 [`answer.md`](./answer.md)。

## 七、举一反三练习（无答案）

把固定样例改为四笔支付记录，并使用 `PERFORM VARYING` 顺序处理。为每轮输出序号、代码和金额，累计处理数量；当最后序号为 0 时不得处理记录。暂时仍可用 `EVALUATE` 映射各固定序号，不要引入尚未学习的表格或文件。

提交源码、编译命令和 `last=0` 与 `last=4` 两种实际输出。本练习不提供答案。

## 八、企业实战补充

批量程序用循环处理输入记录时，需要确保每轮都读取或推进输入，并让退出条件能够到达。必须验证空批次、单记录、最后记录和超过预期范围等边界。本例把上限直接设为 4 时会进入 `UNMAPPED` 分支；生产程序应在继续处理前按接口契约拒绝或记录这种不一致。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PERFORM)
- [GnuCOBOL Programmer’s Guide：Inline PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Inline-PERFORM)
- [GnuCOBOL Manual：PERFORM loop example](https://gnucobol.sourceforge.io/doc/gnucobol.html)
