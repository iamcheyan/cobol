# 第 19 课：同时读取主档与交易文件

> 状态：课程草稿。目录已确认；示例源码 187 行固定格式，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 在一个程序中声明并打开两个顺序输入文件。
- 为每个输入分别维护文件状态、EOF 标志和成功读取数。
- 在一个循环里交错读取多个流，并在单个文件到达 EOF 后继续处理其他文件。
- 区分正常 EOF、OPEN 失败、READ 错误和 CLOSE 错误。
- 说明为什么 EOF 状态不能在输入流之间共用。

## 二、输入文件

[`accounts.txt`](./accounts.txt) 是账户主档夹具，共三条记录；[`transactions.txt`](./transactions.txt) 是每日交易夹具，共四条记录。两者都是行顺序文本文件，每个物理行是一条记录。程序只读取并显示整行，不解析字段，也不按账户号匹配；顺序匹配留给第 20 课。

## 三、读取流程

1. 分别打开主档和交易文件，检查各自的 `FILE STATUS`。第二个文件打开失败时，关闭已打开的第一个文件并返回错误。
2. 进入循环时，若某个文件尚未到 EOF，就对它执行一次 `READ`。每个输入各有一个读取段落。
3. 成功读取时，仅增加对应文件的计数并显示该行。该文件状态为 `00`。
4. 到达 EOF 时，仅设置该文件的 EOF 标志。状态 `10` 是正常 EOF，不增加记录数。
5. 当任一 READ 返回其他状态时，报告具体文件和状态，停止读取，并关闭两个文件。
6. 只有两个 EOF 标志都设置后，正常读取循环才结束。

GnuCOBOL 手册说明 `AT END` 用于处理文件状态 `10`，不会捕获其他非零状态；其他 READ 错误需通过文件状态字段或 DECLARATIVES 处理。本例在各文件的 `READ` 后检查状态，因此不会把 I/O 错误当成 EOF。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_19" lesson.cob
cp accounts.txt transactions.txt "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_19)
```

标准输出：

```text
账户与交易文件已打开
账户主档：MASTER|0001234567|C0001042|0001000.00
交易：TXN-000001|D|0001234567|125.50
账户主档：MASTER|0002468101|C0002042|0000020.00
交易：TXN-000002|T|0001234567|0007654321|40.00
账户主档：MASTER|0007654321|C0003042|0000250.75
交易：TXN-000003|D|0002468101|75.00
交易：TXN-000004|T|0007654321|0009999999|20.00
关闭完成 账户记录数=003 交易记录数=004
```

主档有三条、交易有四条。主档先到 EOF 后，第四条交易仍被读取。已验证语法检查、编译和上述运行输出；还验证了交易流提前结束、空主档、缺失输入文件及第二个文件打开失败。

## 五、文件状态与限制

- 两个输入都是必需文件；SELECT 未声明为 `OPTIONAL`。
- 每个文件必须能打开。缺少文件时，GnuCOBOL 返回状态 `35`，程序返回码为 1。
- 单条 FD 记录区为 100 个字符；本课夹具均短于该上限。
- 发生 READ 错误时立即停止读取，并尝试关闭两个文件；本例不提供恢复或重试。
- 示例只读取原始行，不验证字段、不累计金额、不生成输出文件，也不声称完成了文件匹配。

## 六、修改练习（有答案）

1. 从临时副本中删除 `transactions.txt` 的后两行。确认主档仍读取三条、交易读取两条，交易 EOF 后主档仍可继续读完。
2. 将临时运行目录中的 `accounts.txt` 清空，保留四条交易。确认程序读完所有交易，主档计数为零。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

增加一份客户状态文件，与主档和交易文件一起读取。为三个输入各自维护 EOF 和计数；分别制作三条、两条、一条记录的夹具，确认任意一个流先结束时其他流仍继续。设计一个可区分文件名和状态码的读取错误输出格式。

本题不提供答案。不添加账户匹配、排序或数据库访问。

## 八、企业实战补充

日批处理经常需要把主档、控制文件和交易文件作为一个输入集合。每个文件都应有明确的必需/可选策略、文件状态处理和独立记录计数。生产对账还需校验业务日期、记录格式和跨文件一致性；本课只验证并行推进文件位置及独立 EOF 生命周期。

## 参考资料

- [GnuCOBOL Programmer’s Guide：SELECT 与 FILE STATUS](https://superbol.eu/gnucobpg/chapter5.html#select)
- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide：AT END 对 READ 的处理](https://superbol.eu/gnucobpg/chapter7.html#at-end-not-at-end)
- [GnuCOBOL Programmer’s Guide：Sequential READ](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
