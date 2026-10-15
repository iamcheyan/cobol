# 第 17 课：定长账户主档与余额文件

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 区分没有行结束符的 `ORGANIZATION SEQUENTIAL` 记录与行顺序文本记录。
- 用 `RECORD CONTAINS` 和 FD 字段定义固定记录长度。
- 根据字段长度计算字节偏移，并验证记录布局。
- 逐条读取账户主档，并写出字段顺序不同但长度相同的余额记录。
- 用实际文件字节数验证输出记录数量与记录宽度。

## 二、文件布局

[`accounts.dat`](./accounts.dat) 是三个连续的 27 字节账户记录，共 81 字节。记录之间没有换行符或其他分隔符。每条输入记录布局：

| 字节位置 | 长度 | 字段 | 示例第一条 |
|---:|---:|---|---|
| 1–10 | 10 | 账户号 `PIC X(10)` | `0001234567` |
| 11–18 | 8 | 客户号 `PIC X(8)` | `C0001042` |
| 19–27 | 9 | 余额 `PIC 9(7)V99` | `000100000` |

`V` 是隐含小数点，不占物理字节。九个余额数字 `000100000` 表示 `1000.00`。

[`lesson.cob`](./lesson.cob) 使用 `ORGANIZATION IS SEQUENTIAL`。GnuCOBOL 按 FD 记录长度计算每条记录的偏移；该组织格式没有行结束符，不能用普通文本编辑器另存，因为文本编辑器会插入换行字节。

程序把字段重新排列并写到 `balances.dat`，每条输出也为 27 字节：

| 字节位置 | 长度 | 字段 | 第一条输出 |
|---:|---:|---|---|
| 1–8 | 8 | 客户号 | `C0001042` |
| 9–18 | 10 | 账户号 | `0001234567` |
| 19–27 | 9 | 余额 | `000100000` |

## 三、读取与写出步骤

1. 主段落打开输入账户文件和输出余额文件，并检查文件状态。
2. 每次成功的 `READ` 把下一段 27 字节装入 FD 字段。`AT END` 终止读取，不会产生空输出记录。
3. 写出段落按名称把客户号、账户号和余额移入输出 FD 的不同位置，再执行 `WRITE`。
4. 每次成功写入增加记录数。关闭两个文件后，程序报告写出条数。
5. 由于输出是三个 27 字节记录，`balances.dat` 总长度应为 `3 × 27 = 81` 字节。

## 四、编译、运行和预期结果

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_17" lesson.cob
cp accounts.dat "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_17)
wc -c "$scratch_dir/balances.dat"
```

程序标准输出：

```text
ファイルを開きました
出力 口座番号=0001234567 顧客番号=C0001042 残高=0001000.00
出力 口座番号=0002468101 顧客番号=C0002042 残高=0000020.00
出力 口座番号=0007654321 顧客番号=C0003042 残高=0000250.75
クローズ完了 件数=03
```

`wc -c` 输出 `81`。输出文件按记录展示如下；这些行只是查看时的分组，实际文件内没有换行字节：

```text
C00010420001234567000100000
C00020420002468101000002000
C00030420007654321000025075
```

当前环境语法检查、编译、读取、写出和输出长度均已验证。编译运行时可能显示环境警告 `Warning: program compiled against libxml 212 using older 209`；它不属于程序标准输出。

## 五、修改练习（有答案）

1. 向 `accounts.dat` 末尾追加一个完整的 27 字节记录：账户 `0009990001`、客户 `C0004042`、余额数字 `000000500`。不要插入换行符。确认输出为四条记录、长度 `108` 字节。
2. 改变输出 FD 的字段声明顺序，让账户号位于字节 1–10、客户号位于 11–18、余额仍位于 19–27。确认前三条输出与输入记录的 27 字节布局相同。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；练习说明见 [`exercise.md`](./exercise.md)。

## 六、举一反三（无答案）

设计一个 32 字节定长客户记录，包含 8 字节客户号、20 字节名称和 4 字节状态。创建两个连续记录，逐条读取并输出客户号及状态；提交字段偏移表、原始文件长度和预期记录数。说明为什么行顺序文本不能直接当作这种原始记录文件。

本题不提供答案。不使用 `LINE SEQUENTIAL`，也不加入数据库。

## 七、企业实战补充

定长文件接口依赖双方对记录长度、字段偏移、字符编码、数字存储和记录数量的共同约定。字段长度改变会移动后续字段偏移；未经版本管理的布局变更会让接收程序误读数据。生产交换必须保留布局规范和可复核的样例字节。

## 参考资料

- [GnuCOBOL Programmer’s Guide：ORGANIZATION SEQUENTIAL](https://superbol.eu/gnucobpg/chapter5.html#organization-sequential)
- [GnuCOBOL Programmer’s Guide：FD 与 RECORD 子句](https://superbol.eu/gnucobpg/chapter6.html#fileasort-description)
- [GnuCOBOL Programmer’s Guide：Sequential READ](https://superbol.eu/gnucobpg/chapter7.html#sequential-read)
- [GnuCOBOL Programmer’s Guide：WRITE](https://superbol.eu/gnucobpg/chapter7.html#write)
