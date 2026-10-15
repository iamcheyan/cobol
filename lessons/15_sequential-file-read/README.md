# 第 15 课：顺序读取每日交易文本

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 用 `SELECT`、`FD` 和记录描述关联 COBOL 文件与外部文本文件。
- 用 `ORGANIZATION IS LINE SEQUENTIAL` 描述按行结束的文本文件。
- 通过 `OPEN INPUT` 和 `READ` 按物理顺序逐条读入记录。
- 在 `AT END` 处理正常 EOF，区分成功记录与 EOF。
- 用文件状态识别打开失败，并安全结束程序。

## 二、输入文件与记录

[`transactions.txt`](./transactions.txt) 是四行每日交易样例，含存款和转账记录。每行包含日期、交易号、类型、账户号和金额等可见文本字段；记录长度不同。

[`lesson.cob`](./lesson.cob) 将文件声明为行顺序组织，FD 记录区长度为 100 个字符。GnuCOBOL 对较短的行在右侧补空格；`FUNCTION TRIM(... TRAILING)` 只用于显示时去掉这些填充。程序把整行当作文本读取，不在本课拆分字段。

## 三、逐记录读取流程

1. `SELECT` 用相对文件名 `transactions.txt` 绑定输入文件；运行程序时，当前目录必须是本课目录或包含该文件的目录。
2. `OPEN INPUT` 成功时文件状态为 `00`。文件不存在时，程序显示状态并以返回码 1 结束，不执行 `READ`。
3. 每次成功的 `READ` 将下一行读到 FD 记录区，程序增加记录数并显示该文本行。
4. 读完最后一行后，下一次 `READ` 执行 `AT END`，设置 EOF 标志；这次没有增加记录计数。
5. 循环结束后关闭文件。空文件同样会在第一次 `READ` 到达 EOF，记录数为零。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_15" lesson.cob
"$scratch_dir/lesson_15"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
オープン=OK
レコード=DAY-20261013|TXN-000001|D|0001234567|125.50
レコード=DAY-20261013|TXN-000002|T|0001234567|0007654321|40.00
レコード=DAY-20261013|TXN-000003|D|0002468101|75.00
レコード=DAY-20261013|TXN-000004|T|0007654321|0009999999|20.00
EOF=はい レコード数=04
クローズ=OK
```

当前环境语法检查、编译和上述运行均返回 0。编译运行时可能显示环境警告 `Warning: program compiled against libxml 212 using older 209`；它不属于程序标准输出。

缺失文件场景：在不含 `transactions.txt` 的目录运行编译好的程序，输出 `オープン=FAILED STATUS=35` 并返回 1。空文件场景输出 `オープン=OK`、`EOF=はい レコード数=00` 和 `クローズ=OK`。

## 五、修改练习（有答案）

1. 在 `transactions.txt` 末尾追加一条不超过 100 字符的文本记录 `DAY-20261013|TXN-000005|D|0001234567|10.00`，确认它作为第五条完整记录显示，计数变为 `05`。
2. 在临时运行目录创建空的 `transactions.txt`，使用原程序读取并确认首次读取即到 EOF，记录计数为 `00`。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习说明见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

创建一份包含三行、行长不同的客服事件文本。用相同方式逐行读取并计数。让其中一行超过 FD 声明的 100 字符，观察 GnuCOBOL 行顺序文件对过长记录的处理，并解释为什么正式接口必须明确记录长度边界。

本题不提供答案。不要解析字段或把文件内容改写为数据库记录。

## 七、企业实战补充

批处理入口首先要确认文件能打开、每条记录按输入顺序读到、EOF 被正常识别。真实交易导入还需定义字段长度、编码、校验、拒绝记录和运行审计；本课只读取并显示原始行，字段解析和输出分别在后续课程处理。

## 参考资料

- [GnuCOBOL Programmer’s Guide：SELECT 与 ASSIGN](https://superbol.eu/gnucobpg/chapter5.html#select)
- [GnuCOBOL Programmer’s Guide：LINE SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer’s Guide：FILE SECTION](https://superbol.eu/gnucobpg/chapter6.html#file-section)
- [GnuCOBOL Programmer’s Guide：Sequential READ 与 AT END](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
