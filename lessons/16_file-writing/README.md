# 第 16 课：写出接受与拒绝结果文件

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 用 `SELECT`、`FD` 和 `FILE STATUS` 声明顺序输出文件。
- 用 `OPEN OUTPUT` 创建文件，并理解它会替换已有内容。
- 用 `WRITE ... FROM` 逐条写出完整记录。
- 将接受和拒绝结果路由到不同输出文件。
- 在写入和关闭后检查文件状态与输出计数。

## 二、样例结果

[`lesson.cob`](./lesson.cob) 从内存表格装入四条已经分类的结果：两条接受、两条拒绝。`A` 记录进入 `accepted.txt`，`R` 记录进入 `rejected.txt`。每条输出记录恰好 35 个字符，以竖线分隔字段；本课聚焦文件写入，不重新计算业务分类。

两个输出都使用 `ORGANIZATION IS LINE SEQUENTIAL`。每条成功的 `WRITE` 写一行，Linux 上以换行符结束。`WRITE ... FROM` 会先把来源文本移动到 FD 记录，再写出该记录。

## 三、运行步骤

1. 程序以 `OPEN OUTPUT` 分别打开接受和拒绝文件，并检查各自的状态码。若某个打开失败，程序显示状态并以返回码 1 结束。
2. `PERFORM VARYING` 按内存表顺序处理四条结果。标记 `A` 写入接受文件，标记 `R` 写入拒绝文件。
3. 每次写入后检查对应文件状态；只有成功写入才增加相应计数。
4. 循环结束后关闭两个文件，并报告写入计数。
5. `OPEN OUTPUT` 会完全替换同名旧文件内容；它不会追加。运行程序时用临时目录作为当前目录，输出文件便留在临时目录。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_16" lesson.cob
(cd "$scratch_dir" && ./lesson_16)
cat "$scratch_dir/accepted.txt"
cat "$scratch_dir/rejected.txt"
```

程序标准输出：

```text
オープン=受理 成功
オープン=拒否 成功
書込=受理 取引=000001
書込=受理 取引=000002
書込=拒否 取引=000003
書込=拒否 取引=000004
クローズ=受理 成功
クローズ=拒否 成功
SUMMARY 受理=02 拒否=02
```

`accepted.txt`：

```text
TXN-000001|0001234567|D|000125.50|A
TXN-000002|0007654321|T|000040.00|A
```

`rejected.txt`：

```text
TXN-000003|0002468101|X|000000.00|R
TXN-000004|0009999999|T|000020.00|R
```

当前环境语法检查、编译、运行和两份文件内容均已验证。编译运行时可能显示环境警告 `Warning: program compiled against libxml 212 using older 209`；它不是程序输出。

## 五、修改练习（有答案）

1. 把第四项的目标标记从 `R` 改为 `A`，并把记录末尾的分类标记也改为 `A`。确认该行转入接受文件，拒绝文件只剩第三项，汇总为接受 `03`、拒绝 `01`。
2. 在临时运行目录预先写入旧内容 `OLD` 到两个输出文件，再运行原程序。确认旧内容被替换，文件中只有本课样例结果。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习说明见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

把样例表扩成五条记录，分别将三个接受项写到接受文件、两个拒绝项写到拒绝文件。更新表格上界、装载数据和处理范围；验证两份文件的记录顺序、行数与汇总一致。

本题不提供答案。不增加输入文件或数据库。

## 七、企业实战补充

批处理常把结果拆成可继续处理的接受文件和供人工或后续程序处理的拒绝文件。生产作业还需约定输出命名、覆盖或追加策略、失败退出码、部分输出清理与重跑规则。本课明确采用覆盖策略，并在写入或关闭失败时返回非零状态。

## 参考资料

- [GnuCOBOL Programmer’s Guide：OPEN](https://superbol.eu/gnucobpg/chapter7.html#open)
- [GnuCOBOL Programmer’s Guide：WRITE](https://superbol.eu/gnucobpg/chapter7.html#write)
- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
