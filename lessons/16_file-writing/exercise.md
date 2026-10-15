# 第 16 课练习：写入分类结果——路由、覆盖与重跑

本节只使用第 16 课与先修课讲过的内容：`SELECT`/`FD`/`FILE STATUS`/`OPEN OUTPUT`/`WRITE ... FROM`/`CLOSE`（本课）、`OCCURS` 表格（第 [11](../11_occurs-tables/README.md) 课）、`EVALUATE`（第 [05](../05_evaluate/README.md) 课）、段落与 `PERFORM`（第 [07](../07_paragraphs/README.md) 课）、`DISPLAY`、`MOVE` 与 `STOP RUN`。

> **运行位置：** 程序把 `accepted.txt`/`rejected.txt` 写在**运行时的当前目录**，而课内同名文件不受 `.gitignore` 保护。所有练习都用课内 `build/` 当工作目录：可执行文件和两个输出文件都落在 `build/`，`build/` 已被仓库忽略，最后 `rm -rf build` 一次清干净。

## 修改练习（会在 `answer.md` 提供参考答案）

### 一、把第四项改成接受结果

#### 基线

从本课原始 [`lesson.cob`](./lesson.cob)（工作区中未改动的版本）开始。建议先复制一份再改，例如 `cp lesson.cob /tmp/lesson_16_ex1.cob`，这样基线仍可重跑。

#### 改动位置与约束

只改 `1000-LOAD-RESULTS` 中的这两条语句：

```cobol
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4)
```

把目的地标记改成 `"A"`，并把记录文本的最后一个字符也改成 `A`。

约束：

- 不要改动其它三条记录的目的地标记和文本内容。
- 不要改动 `PIC`、`FD` 记录宽度、`OCCURS 4 TIMES` 上界，也不要改动循环上界 `UNTIL WS-RESULT-NUMBER > 4`。
- 不要改动任何 `DISPLAY` 文本，不要增加新的输出文件、输入文件、日志或数据库。

#### 命令

```sh
mkdir -p build                                          # 工作目录
cp lesson.cob build/                                    # 在 build/ 里改副本，别动课内文件
cobc -fsyntax-only build/lesson.cob                     # 语法检查
cobc -x -Wall -o build/lesson_16 build/lesson.cob       # 编译
(cd build && ./lesson_16)                               # 在 build/ 里运行，输出落在那里
echo $?                                                 # 退出码
wc -lc build/accepted.txt build/rejected.txt            # 行数与字节数
cat build/accepted.txt build/rejected.txt               # 两份文件的内容
```

#### 预期差异

标准输出仍是 9 行，其中**只有两行变化**：

| 行 | 原始值 | 改动后的值 |
|---|---|---|
| 6 | `書込=拒否 取引=000004` | `書込=受理 取引=000004` |
| 9 | `SUMMARY 受理=02 拒否=02` | `SUMMARY 受理=03 拒否=01` |

其余 7 行（前 5 行和 2 行 `クローズ=`）逐字节不变。完整改动后输出：

```text
オープン=受理 成功
オープン=拒否 成功
書込=受理 取引=000001
書込=受理 取引=000002
書込=拒否 取引=000003
書込=受理 取引=000004
クローズ=受理 成功
クローズ=拒否 成功
SUMMARY 受理=03 拒否=01
```

两个文件：

`accepted.txt`（3 行、108 字节）

```text
TXN-000001|0001234567|D|000125.50|A
TXN-000002|0007654321|T|000040.00|A
TXN-000004|0009999999|T|000020.00|A
```

`rejected.txt`（1 行、36 字节）

```text
TXN-000003|0002468101|X|000000.00|R
```

语法检查与编译返回码、退出码都是 `0`。独立核算：每行 35 个字符、末位非空格，所以每行 36 字节；`3 × 36 = 108`、`1 × 36 = 36`；两个文件合计 4 行，与表里的 4 条一致，`SUMMARY` 的 `03 + 01 = 04`。

#### 需要回答的问题

1. 第四项的记录文本为什么必须和目的地标记一起改？如果只改目的地标记，`accepted.txt` 里会出现什么行？程序会报错吗？
2. 改动后 `accepted.txt` 里三行的先后顺序由什么决定？是文件系统、`EVALUATE` 还是别的？
3. 如果把第四项的目的地标记改成既不是 `A` 也不是 `R` 的 `X`，程序会走哪条路径？标准输出、两个文件的内容与字节数、`SUMMARY` 和退出码分别是什么？此时两个计数之和还等于表里的条数吗？

逐题记录实际输出与源码依据。参考答案见 [`answer.md`](./answer.md)。

### 二、核对覆盖与重跑

#### 基线

仍然使用**未修改**的原始 [`lesson.cob`](./lesson.cob)。先把编译好的程序放进 `build/`，并在该目录里预置两个旧文件：

```sh
mkdir -p build
cp lesson.cob build/
cobc -fsyntax-only build/lesson.cob
cobc -x -Wall -o build/lesson_16 build/lesson.cob
printf 'OLD\n' > build/accepted.txt
printf 'OLD\n' > build/rejected.txt
wc -c build/accepted.txt build/rejected.txt     # 运行前的字节数
(cd build && ./lesson_16)                                # 运行
echo $?
wc -lc build/accepted.txt build/rejected.txt    # 运行后的行数与字节数
cat build/accepted.txt build/rejected.txt       # 内容
```

#### 约束

不要删除或改写课内文件；不要在课内目录运行程序；不需要改源码。

#### 预期差异

| 观察项 | 运行前 | 运行后 |
|---|---|---|
| `accepted.txt` | 4 字节，内容 `OLD` | 72 字节，内容只有 2 条样例接受记录 |
| `rejected.txt` | 4 字节，内容 `OLD` | 72 字节，内容只有 2 条样例拒绝记录 |
| 标准输出 | — | 与正常路径完全相同的 9 行 |
| 退出码 | — | `0` |

#### 需要回答的问题

1. `OLD` 为什么不见了？是程序的哪一条语句造成的？
2. 如果把两次运行的结果"累加"预期成 144 字节，实际会是多少？为什么？
3. 如果运行前把 `accepted.txt` 建成**目录**（`mkdir accepted.txt`），程序输出什么、退出码是多少、有没有文件被创建？

逐题记录实际输出、退出码与字节数。参考答案见 [`answer.md`](./answer.md)。

## 举一反三（不提供答案）

为"需要人工复核"的结果加一条新链路：给结果表加入第三个目的地标记（例如 `H`），为它声明一个新的输出文件（例如 `review.txt`），让 `EVALUATE` 多一个 `WHEN` 分支、写入计数与 `SUMMARY` 各多一项。

要求：

- 自己决定新文件的**文件名与记录宽度**，并写清两条依据：相对文件名会落在哪个目录、记录宽度由哪个字段或 `PIC` 决定。
- 自己决定把哪几条样例改成 `H`，并让记录文本末尾的标记与新的路由标记保持一致。
- 说明你的核对方法：三份文件各自的行数与字节数、三个计数之和是否等于表里的条数、以及每份文件里每一行的末尾标记是否与所在文件名一一对应。
- 至少覆盖一个边界：让某一条记录的末尾标记与它的目的地标记**故意不一致**，运行后说明程序有没有发现这种矛盾，并解释这个后果由谁负责。
- 自己记录编译命令、实际输出、文件字节数和退出码，并给出核算过程。

限制：只使用本课与先修课已学的语法——`SELECT`/`ASSIGN`/`ORGANIZATION`/`FILE STATUS`、`FD`、`OPEN OUTPUT`/`WRITE ... FROM`/`CLOSE`、`EVALUATE`、`OCCURS` 表格、段落与 `PERFORM`、`MOVE`、`DISPLAY`。不要引入输入文件、追加模式、临时文件改名、数据库或子程序。

交付：源码、两份/三份输出文件的完整内容与字节数、命令、实际输出与退出码，以及"标记与目的地不一致时谁负责"的说明。本题不提供答案。
