# 第 21 课：用 SORT 整理账户主档

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 声明 `SD` 排序工作文件和升序排序键。
- 在 `INPUT PROCEDURE` 中打开输入、读取记录并用 `RELEASE` 送入排序。
- 在 `OUTPUT PROCEDURE` 中用 `RETURN` 逐条读取已排序记录。
- 使用 `SORT-RETURN` 区分排序工作操作的成功和失败。
- 验证输入顺序和排序输出顺序，并说明排序与第 20 课归并匹配的关系。

## 二、记录布局和数据流

[`accounts-unsorted.txt`](./accounts-unsorted.txt) 包含四条未排序的 27 字符主档记录。每行由 10 字符账户号、8 字符客户号和 9 位余额数字组成，与第 17 课字段布局相同；金额 `PIC 9(7)V99` 的小数点不占字符。

程序在 `SELECT SORT-WORK ASSIGN TO DISK` / `SD SORT-WORK` 中声明排序工作文件。SORT 工作文件由 GnuCOBOL 管理，程序不对它执行 `OPEN` 或 `CLOSE`。样例先把行顺序输入读到 FD，再把记录 `RELEASE` 到排序工作文件；排序完成后，输出过程通过 `RETURN` 获取升序记录并显示。

## 三、三个排序阶段

1. `SORT ... ON ASCENDING KEY SD-ACCOUNT-NUMBER` 声明排序键。
2. 输入过程逐条 `READ`。成功时把 27 字符记录移入 SD 记录，再 `RELEASE`；文件状态 10 表示正常 EOF。
3. GnuCOBOL 按排序键组织已释放记录。
4. 输出过程重复 `RETURN`。每次成功返回一条记录并显示，`AT END` 结束过程。
5. 输入和输出成功计数应相等；任何检测到的输入或 SORT 工作失败都会使程序返回非零状态。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_21" lesson.cob
cp accounts-unsorted.txt "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_21)
```

标准输出：

```text
ソート済み 口座番号=A000000001 顧客番号=C0001001 残高=0001000.00
ソート済み 口座番号=A000000002 顧客番号=C0001002 残高=0000002.00
ソート済み 口座番号=A000000004 顧客番号=C0001004 残高=0000025.00
ソート済み 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75
入力レコード数=004 出力レコード数=004
```

已验证语法检查、编译、原始夹具排序、空输入和缺失输入；也验证了已排序与逆序输入。编译运行时可能显示环境警告 `Warning: program compiled against libxml 212 using older 209`；它不是程序标准输出。

## 五、前提与边界

- 输入 FD 宽度是 27 字符，夹具每行必须满足该记录布局。
- 本课按账户号升序排序，输出过程显示所有字段。
- 示例使用唯一账户号，不依赖重复键的相对顺序。
- 输入文件由输入过程管理；输出通过终端显示，没有生成排序结果文件。
- 生产批次还需约定重复键政策、排序错误处置和排序后交付方式。

## 六、修改练习（有答案）

1. 交换夹具第一行和第二行。确认显示顺序仍按账户号升序，且输入/输出计数相同。
2. 在副本末尾追加一条 27 字符账户记录，账户号 `A000000006`、客户号 `C0001006`、余额数字 `000000001`。确认新账户出现在排序结果末尾，计数变为 005。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

将排序键扩展为先按账户号升序、再按余额降序。设计余额相同的记录并观察结果；明确程序是否依赖相同排序键记录的相对顺序。记录修改后的排序键声明和完整输出。

本题不提供答案。不把整份文件载入 OCCURS 表，不写生成的排序文件。

## 八、企业实战补充

大批量对账常在匹配前整理输入顺序。SORT 把“读记录、释放排序、按键返回”的数据流封装在程序中；排序输出可交给第 20 课的一次扫描匹配。生产任务还要验证键规则、重复键、空文件、源文件状态和排序失败后的批次退出策略。

## 参考资料

- [GnuCOBOL Programmer’s Guide：File-Based SORT](https://superbol.eu/gnucobpg/chapter7.html#file-based-sort)
- [GnuCOBOL Programmer’s Guide：RELEASE](https://superbol.eu/gnucobpg/chapter7.html#release)
- [GnuCOBOL Programmer’s Guide：RETURN](https://superbol.eu/gnucobpg/chapter7.html#return)
- [GnuCOBOL Programmer’s Guide：SD 文件说明](https://superbol.eu/gnucobpg/chapter6.html#fileasort-description)
