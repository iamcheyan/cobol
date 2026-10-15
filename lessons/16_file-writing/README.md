# 第 16 课：写出接受与拒绝结果文件——用 OPEN OUTPUT 与 WRITE 落盘

夜间批次跑完校验，只把汇总打在终端上不算交付：接受明细要交给下一个系统继续过账，拒绝明细要进人工复核队列。本课给这两条结果链路各声明一个顺序输出文件，用 `OPEN OUTPUT` 清空重建、用 `WRITE ... FROM` 逐条写出，并让每条结果按自己携带的 `A`/`R` 目的地标记决定落进 `accepted.txt` 还是 `rejected.txt`。

## 业务现场

凌晨 1 点，日终批次在机房跑完。校验程序把当天交易过了一遍，分成两拨：能继续处理的写进 `accepted.txt`，需要人来判断的写进 `rejected.txt`。

早上 7:50，复核岗的人上班，第一件事就是打开那份拒绝清单，一条条看过去——账号对不上、交易码不认识、金额为负，每种都有对应的处理办法。8:10，下游的过账程序按计划来取走接受文件，接着往下跑。看清楚这两份文件的身份：**一份要被下一个程序继续处理，一份要被一个人继续处理。** 它们不是留个痕迹就完事的日志。

也正因为要被人和机器接着用，事故里最贵的一类不是"算错了一个数"，而是"程序报成功，文件其实是空的，或者只写了一半"。算错还好，对账的时候能对出来；文件该有内容却没有，下游当天就是拿着一份空壳在跑，往往到第二天才发现。

这一课就把两个问题讲透：这个程序第二天再跑一遍，是把昨天的结果盖掉，还是叠在后面？写不进去的时候——文件打不开、权限不对、路径被占成了目录——程序是靠什么发现的，又有哪些它其实发现不了？

（场景是教学演示，机构、时间、笔数是把问题说清楚用的，不代表某家真实机构的真实数据。）

## 为什么现在学

第 15 课你已经能打开文件、一行行读进来，还能把"读完了"和"文件根本打不开"分成两种结果报出来。但那节课的结果只出现在屏幕上，进程一退出就没了，交接不下去。

你可能会想：把屏幕输出重定向到一个文件不就行了？卡在"重定向"这三个字上——它把整个标准输出不加区分地倒进同一个文件，接受和拒绝混在一起；而且你手上没有任何东西能回答"这次写入到底成没成"。真实批次里，结果不是一段文字，是**要交出去的交付物**：谁收、收到什么、收不到的时候谁负责，都得说清楚。

所以这一课补的是输出侧的另一半。写一个有结果的文件，至少得先定下几件事：文件怎么声明、重复运行是覆盖还是追加、写不进去时怎么报、失败之前已经写出去的那几行算不算数。这些坑不只 COBOL 有，任何会写文件的批处理程序都躲不开；只是 COBOL 把每一件都摆到台面上，逼你明确回答。

本课用内存里四条已经分好 `A`/`R` 的结果把这些问题一次讲清。输入的解析（定长、CSV）留给第 [17](../17_fixed-length-files/README.md)、[18](../18_csv-processing/README.md) 课——到那时你才会真正去"读懂"外面进来的记录。

## 这个知识点是什么，它解决什么问题

**这个知识点是什么。** 一套"把结果写出去"的写法：`SELECT` 把程序里的文件接到磁盘上的真实路径，`FD` 声明每条记录多宽，`FILE STATUS` 把每次 I/O 的结果回传给你，`OPEN OUTPUT` 决定"新建还是盖掉旧的"，`WRITE ... FROM` 把结果区的文本落成一行。说白了，就是给你的结果找一条能交出去的出路。

**它在业务里解决什么问题。** 让"处理结果"从屏幕上的文字变成别人能接着用的文件。接受文件交给下游程序继续跑，拒绝文件交给人工复核；两份文件各有各的消费者，所以不能混在一个文件里。同时，`FILE STATUS` 让你有机会在"没写成"的时候把程序判失败，而不是让一个空文件冒充成功结果流到下游。

**什么时候不该用它、用错会怎样。** 把结果文件当日志用、或者只看屏幕输出对不对就判断成败，是最常见的误用：屏幕上一片正常，文件可能一个字节都没有。另一头是"覆盖还是追加"想当然——以为用了 `OPEN OUTPUT` 就"自动做到重跑幂等"，这是不成立的（往下看，它做的只是把文件截断重建）。真要"写完再原子替换""重跑不留半截"，本课一样都没实现。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `SELECT`+`ASSIGN`+`ORGANIZATION IS LINE SEQUENTIAL`+`FILE STATUS` 声明一个顺序输出文件，并指出 35 字节的记录宽度来自 `FD` 下的 `PIC X(35)`。
- 用 `OPEN OUTPUT` 创建或清空重建文件，并说明它为什么不是追加；用自己的旧文件观察旧内容被替换。
- 用 `WRITE ... FROM` 把 `WORKING-STORAGE` 里的记录写进 FD 记录区并落成一行，并用字节数核对"两条记录 = 72 字节"。
- 按 `A`/`R` 目的地标记把记录路由到两个文件，用 `SUMMARY 受理=02 拒否=02` 与自己数出的行数互相核对。
- 读懂 `FILE STATUS`：打开失败时显示状态码并返回 1；按代码说明写出/关闭失败时会停止后续记录、返回 1 且不回滚已写行。

边界：本课不读任何输入文件，样例是程序内固定数据，因此没有"空输入"分支，也不做字段解析和业务校验——`A`/`R` 是装进表里的现成结果，不是本课算出来的。程序不做追加、不用临时文件改名替换、不加锁、不检查编码，也不写日志或数据库。CSV/定长解析见第 17、18 课，业务拒绝与系统故障的分流见第 [26 课](../26_error-handling/README.md)，日志见第 [27 课](../27_logging/README.md)。

## 运行环境

- GnuCOBOL 3.2.0，默认方言（不加 `-std=cobol85`），源文件为固定格式：第 7 列指示符、Area A 从第 8 列、Area B 从第 12 列起。
- **第 72 列按字节算**：本机实测把一条 72 字符、172 字节的行（含日文字符串）放进 Area B，`cobc` 在第 72 字节处截断并报 `error: invalid literal`，可见列数是按字节而非字符计数的。本课 `lesson.cob` 共 129 行，最长一行 71 字节，程序文本与注释都没有越过第 72 列。
- Linux 终端，无需数据库、附加工具或第三方库。
- `ASSIGN TO "accepted.txt"` 是**相对文件名**，输出落在**运行时的当前目录**。课内 `accepted.txt`/`rejected.txt` 不受 `.gitignore` 保护，所以不能让程序直接在本课目录运行；下面的命令都在本课目录 `lessons/16_file-writing/` 下执行，先进入 `build/` 再运行，两个输出文件就落在 `build/` 里。
- 可执行文件与两个输出文件都落在 `build/`；`build/` 已被仓库忽略，最后 `rm -rf build` 一次清干净。

## 业务与知识点

### 结果为什么要落成文件

屏幕属于"过程"，文件属于"产品"。批处理把结果拆成两类文件是有业务含义的：接受文件交给后面的过账/入账程序继续处理，拒绝文件交给人工或复核程序。本课的结果在进入程序前就已经分好类（演示数据：两条接受、两条拒绝），所以本课的重点不是"怎么判断接受"，而是**判断结果怎样可靠地交出去**：写到哪个文件、重复运行会不会把昨天的结果搞乱、写不进去时作业状态是什么。

### 一行 35 字节的记录布局

两个输出文件用的是同一种记录：35 个字符、以竖线分隔五个字段，最后一个字段就是路由用的目的地标记。

| 位置 | 宽度 | 字段 | 第一条样例 |
|---|---:|---|---|
| 1–10 | 10 | 交易号 `TXN-nnnnnn` | `TXN-000001` |
| 11 | 1 | 分隔符 `|` | `|` |
| 12–21 | 10 | 账户号 | `0001234567` |
| 22 | 1 | 分隔符 `|` | `|` |
| 23 | 1 | 交易类型 | `D` |
| 24 | 1 | 分隔符 `|` | `|` |
| 25–33 | 9 | 金额（两位小数的显示格式） | `000125.50` |
| 34 | 1 | 分隔符 `|` | `|` |
| 35 | 1 | 目的地标记 `A`/`R` | `A` |

这 35 个字符是**物理宽度**，不是"业务上有几个字段"。`WRITE ... FROM` 会先把来源文本移进 `FD` 记录区再写出，所以记录区有多宽，记录就有多宽（超过会被截断，见下节）；至于文件中每一行实际占几个字节，还得看下一节的行尾空格规则——两个数不一定相等。

### 覆盖还是追加：`OPEN OUTPUT` 的选择

先回答开头那个问题：第二天重跑，昨天的结果是盖掉还是叠上去？

同一个 `ASSIGN` 名字下，`OPEN OUTPUT` 的语义是"创建或清空重建"：文件不存在就新建，存在就把长度截成 0 再写。第二次、第三次运行不会把结果追加到旧内容后面，也不会留下上次运行的残行。这对批处理是常见选择——同一天重跑得到同一份结果——但它**不是**幂等保证：如果这次比上次少写几条，旧文件里多出来的行不会自己消失（本课正是"重建"，所以不会出现这种残留；追加模式完全是另一种打开方式，不在本课范围）。

### 记录区里的 35 个字符，在文件里不一定占 35 字节

核对文件大小时，最容易脱口而出的一句是"35 字节乘 4 条等于 140 字节"。别急，这里有个常被忽略的坑。

`LINE SEQUENTIAL` 在本工具链默认是**变长行**：写出时去掉记录尾部的空格。课内四条样例的最后一位是 `A`/`R`，所以"35 字符的记录"正好等于"35 字节 + 1 个换行符"。本机对照实验确认了这个边界：把一条 35 字节、末位为空格的记录写出去，文件里那一行只有 34 字节（`od -c` 显示 `...| \n`，整个文件 35 字节）。所以核对文件大小时不能默认"记录宽度 × 条数"。

### `FILE STATUS` 的三种用途

"写不进去的时候，程序怎么知道"——答案就靠每次 I/O 之后立刻查一次状态。两个文件各有一个 `PIC XX` 的状态字段，在三类语句后各查一次：

- `OPEN OUTPUT` 之后：不是 `00` 就显示状态码、设 `RETURN-CODE` 为 1、马上结束，不执行任何 `WRITE`。本机实测"目标是目录""目标是只读文件""目录不可写"三种情况都返回状态码 `37`。
- `WRITE` 之后：只有 `00` 才累加计数并打印 `書込=...` 行；否则打印失败状态、把 `WS-WRITE-ERROR` 置为 `Y`，循环条件随即让后续记录不再写出。
- `CLOSE` 之后：仍是 `00` 才打印 `クローズ=... 成功`；失败同样置错误标志，最后的 `IF` 把 `RETURN-CODE` 设为 1。

这三个检查合起来说明本课的错误政策：**打开失败立刻退出；写出/关闭失败停止后续记录但会先关闭已打开的文件，然后返回非零码**。已经写进文件的行是本课明确不清理的（见"证据来源与验证范围"）。

### 目的地标记只来自表，`WHEN OTHER` 在样例里不可达

`EVALUATE` 只认 `A` 和 `R` 两个目的地标记，`WHEN OTHER` 打印 `書込=FAILED REASON=UNKNOWN_DESTINATION` 并置错误标志。这在本课样例里是**不可达分支**：标记全部由 `1000-LOAD-RESULTS` 用字面量装进去，没有任何外部输入能改变它。它是给改动源码的人看的兜底——如果装载段落被改成第三种标记，程序不会把它静默当成接受或拒绝，而是按系统失败上报并返回 1；那条记录两份文件都不进，于是两个写入计数之和会小于表里的条数（练习一会让你实际观察这一幕）。

## 输入与规则

**输入：** 无外部输入。四条样例记录是 `1000-LOAD-RESULTS` 里的字面量（演示数据，不代表真实业务政策），程序不读终端、文件或数据库，所以每次运行结果完全一样。

**输出契约：**

| 项目 | 约定 |
|---|---|
| 文件名 | `accepted.txt`（目的地 `A`）、`rejected.txt`（目的地 `R`） |
| 位置 | 运行时的当前目录（相对路径） |
| 组织 | `ORGANIZATION IS LINE SEQUENTIAL` |
| 记录区 | `PIC X(35)` |
| 行结束符 | Linux 上为单个 `\n`；行尾空格不写入文件 |
| 覆盖语义 | `OPEN OUTPUT` 清空重建，不追加 |
| 本课正常产物 | 两个文件各 2 行、各 72 字节 |
| 正常退出码 | `0`；打开失败时 `1`（实测）；写出/关闭失败时 `1`（按代码，写入状态未注入，见"证据来源与验证范围"） |

**规则、前提与校验责任人：**

| 规则 / 前提 | 由谁保证 | 本课是否校验 |
|---|---|---|
| 每条记录恰好 35 字节、内容是五个竖线分隔字段 | `1000-LOAD-RESULTS` 的字面量 | **否**——`PIC X(35)` 只定长；更长的值在编译期给 `-Wtruncate` 警告并被截到 35 |
| 目的地标记只有 `A`/`R` | 同一装载段落 | 部分——`WHEN OTHER` 是兜底，样例中不可达 |
| 记录进入哪个文件的判断 | `EVALUATE` 按目的地标记路由 | 是 |
| 记录末尾标记与所在文件一致 | 无（两个标记由人保持同步） | **否**——只改路由标记时，接受文件里会出现以 `|R` 结尾的行 |
| 输出文件可创建、可写 | 运行时的文件系统权限与文件类型 | 是，状态非 `00` 即返回 1 |
| 计数只统计真实写出的记录 | `FILE STATUS = "00"` 之后才 `ADD 1` | 是 |
| 数据已落到磁盘 | 操作系统与运行时缓冲 | **否**——见"证据来源与验证范围"的 `FILE STATUS=00` 边界 |

## 完整示例源码

完整源码见 [`lesson.cob`](./lesson.cob)，按固定格式编写。

```cobol
      * 输出用相对文件名：写在运行时的当前目录。
      * OPEN OUTPUT 覆盖同名旧文件，本课不追加。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 受理-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-受理-STATUS.
           SELECT 拒否-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-拒否-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 受理-FILE.
       01 FD-受理-RECORD PIC X(35).
       FD 拒否-FILE.
       01 FD-拒否-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
      * 样例是程序内演示数据，不是读入的真实交易。
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-受理-STATUS PIC XX VALUE SPACES.
       01 WS-拒否-STATUS PIC XX VALUE SPACES.
       01 WS-受理-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒否-COUNT PIC 9(2) VALUE ZERO.
      * 写/关闭失败即停止并返回 1；已写行不回滚。
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT 受理-FILE
           IF WS-受理-STATUS NOT = "00"
               DISPLAY "オープン=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=受理 成功"
           OPEN OUTPUT 拒否-FILE
           IF WS-拒否-STATUS NOT = "00"
               DISPLAY "オープン=拒否 失敗 状態="
                   WS-拒否-STATUS
               CLOSE 受理-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=拒否 成功"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-受理-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-受理-STATUS = "00"
                       ADD 1 TO WS-受理-COUNT
                       DISPLAY "書込=受理"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=受理 失敗 状態="
                           WS-受理-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-拒否-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-拒否-STATUS = "00"
                       ADD 1 TO WS-拒否-COUNT
                       DISPLAY "書込=拒否"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=拒否 失敗 状態="
                           WS-拒否-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
      * 目的地标记只有 A/R；非 A/R 按系统失败处理。
               WHEN OTHER
                   DISPLAY "書込=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
       9000-CLOSE-OUTPUTS.
           CLOSE 受理-FILE
           IF WS-受理-STATUS = "00"
               DISPLAY "クローズ=受理 成功"
           ELSE
               DISPLAY "クローズ=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE 拒否-FILE
           IF WS-拒否-STATUS = "00"
               DISPLAY "クローズ=拒否 成功"
           ELSE
               DISPLAY "クローズ=拒否 失敗 状態="
                   WS-拒否-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY 受理=" WS-受理-COUNT
               " 拒否=" WS-拒否-COUNT.
```

上面就是全部 129 行源码（含注释），与 [`lesson.cob`](./lesson.cob) 逐行一致。注释只保留三处业务约束——输出是相对文件名且 `OPEN OUTPUT` 是覆盖语义、样例数据固定在程序内、写或关闭失败后的停止与返回码——外加 `WHEN OTHER` 前的兜底说明；逐句翻译和重复说明已删除。

## 源码阅读路径

1. `SELECT 受理-FILE` / `SELECT 拒否-FILE`（第 8–15 行）：两处 `ASSIGN` 决定外部文件名（相对当前目录），`ORGANIZATION IS LINE SEQUENTIAL` 决定"一行一条记录"，`FILE STATUS IS` 把状态交给各自的 `PIC XX` 字段。
2. `FD 受理-FILE.` 下的 `01 FD-受理-RECORD PIC X(35).`（第 18–21 行）：记录区宽度就是每条记录的物理宽度（行尾空格不写入文件，见"知识点"一节）。
3. `WS-RESULT-TABLE`（第 24–27 行）：四条结果各自带一个目的地标记和一个 35 字节文本。**这份表是程序里唯一的结果来源**，没有任何语句根据别的字段重新判断接受还是拒绝。
4. `0000-MAIN` 的前半段（第 37–53 行）：先开接受文件、查状态；再开拒绝文件、查状态，失败时先把已经打开的接受文件关掉再返回 1。
5. `PERFORM VARYING ... UNTIL WS-RESULT-NUMBER > 4 OR WS-WRITE-ERROR = "Y"`（第 55–59 行）：上界 `4` 是表容量，第二个条件才是"写失败就停"——想通这两条同时成立时循环在哪里退出，就能回答"失败后还剩几条没写"。
6. `2000-WRITE-ONE-RESULT`（第 78–110 行）：`EVALUATE` 按标记选文件，`WRITE ... FROM` 写出，紧接的状态检查决定"计数 + 打印 `書込=...`"还是"打印失败状态 + 置错误标志"。`書込=受理 取引=000001` 里的编号不是单独字段，而是对记录文本做引用修改 `WS-RESULT-TEXT(n)(5:6)` 取出的第 5–10 个字符。
7. `9000-CLOSE-OUTPUTS`（第 111–129 行）：两个文件各自关闭并查状态，最后 `SUMMARY` 打印两个计数（`PIC 9(2)`，所以显示为 `02`）。

## 运行与观察

在 `build/` 工作目录里编译和运行，输出文件留在那里，不会污染课程目录：

```sh
mkdir -p build                                  # 输出文件写在这里
cobc -fsyntax-only lesson.cob                             # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_16 lesson.cob      # 编译并生成可执行文件
(cd build && ./lesson_16)                        # 在 build/ 里运行，输出落在该目录
echo $?                                                   # 查看退出码
wc -lc build/accepted.txt build/rejected.txt   # 行数与字节数
cat build/accepted.txt build/rejected.txt      # 两份文件的内容
rm -rf build                                     # 清理可执行文件与两个输出文件
```

上面各条命令各自证明什么：`-fsyntax-only` 只证明源码能通过语法解析；`-x -Wall -o` 才生成可执行文件，返回码 `0` 且无诊断才算编译通过；在 `build/` 里运行可执行文件才能看到写出结果；`wc`/`cat` 用来核对文件的行数、字节数与内容；`rm -rf build` 一次清掉可执行文件与两个输出文件（本课没有需要保留的中间文件）。

**预期标准输出（9 行）：**

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

**中文对照：** `オープン=` = 打开；`受理` = 接受（文件）；`拒否` = 拒绝（文件）；`書込=` = 写入；`取引=` = 交易号；`クローズ=` = 关闭；`失敗 状態=` = 失败与状态码；`SUMMARY 受理=02 拒否=02` = 汇总：接受 2 条、拒绝 2 条（业务输出沿用仓库的日文约定，判断程序行为以实际输出与本节换算为准）。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `cobc -fsyntax-only` 返回码 | `0` |
| `cobc -x -Wall` 返回码 | `0`，无编译诊断 |
| 标准输出 | 上面 9 行 |
| 进程退出码 | `0` |
| `accepted.txt` | 2 行、72 字节 |
| `rejected.txt` | 2 行、72 字节 |

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

**独立核算：** 4 条结果里 2 条标记是 `A`、2 条是 `R`，所以两个文件各 2 行；每行 35 个字符，末位不是空格，因此每行是 `35 + 1 = 36` 字节；`2 × 36 = 72` 字节。两个文件的合计 4 行等于表里的 4 条，`SUMMARY` 的 `02 + 02 = 04` 也等于 4，没有记录被写两次或漏写。`書込=` 行里的交易号可以逐条与文件里的第 5–10 个字符对照。

**实际观察到的环境细节：** 运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境链接库版本差异产生的警告，不是本程序的业务输出，触发组件尚未定位；`cobc -x -Wall` 本身没有任何诊断。

### 证据来源与验证范围

本课结论都在本工作区用 GnuCOBOL 3.2.0 实际执行过（可执行文件与两个输出文件都放在 `build/` 工作目录，课程目录只保留四个源文件）：

| 场景 | 从何种干净输入开始 | 预期与实际 |
|---|---|---|
| 正常路径 | 干净的 `build/` 工作目录（无同名旧文件） | 语法检查/编译返回码 `0`、无编译诊断；标准输出 9 行；退出码 `0`；两个文件各 2 行、各 72 字节；`od -c` 显示每行以 `\n` 结束。吻合。 |
| 重复运行（覆盖） | 先在 `build/` 里写入 4 字节的 `OLD` 到两个文件 | 运行后两个文件都变成 72 字节、内容只有样例四行，`OLD` 不再存在；连续运行两次后文件仍是 72 字节、标准输出逐字节相同（不追加）。吻合。 |
| 打开失败 1 | `build/` 里把 `accepted.txt` 建成目录 | 输出 `オープン=受理 失敗 状態=37`，退出码 `1`，没有创建任何输出文件。吻合。 |
| 打开失败 2 | `build/` 里把 `rejected.txt` 建成目录 | 输出 `オープン=受理 成功` 后接 `オープン=拒否 失敗 状態=37`，退出码 `1`；**接受文件已被创建为空文件（0 字节）**——这是本课明确不清理的残留产物。吻合。 |
| 打开失败 3 | 工作目录不可写（`chmod -w` 后的目录）或 `accepted.txt` 是只读文件（0444） | 均输出 `オープン=受理 失敗 状態=37`、退出码 `1`。吻合。 |

**未验证与已知边界（如实说明，不作为结论）：**

- **写出失败的状态码路径没有被注入出来。** 想让 `WRITE` 返回非 `00` 需要让底层写操作失败；本环境尝试 `ulimit -f 0` 时进程在第一条 `WRITE` 之后被 `SIGXFSZ` 终止（退出码 `153`，两个文件都为 0 字节，最后几行 `クローズ=` 没有打印），这是信号导致的进程终止，不是程序自己报出的 `FILE STATUS`。因此"`WRITE` 失败 → 打印失败状态 → 停止后续记录 → 返回 1"这段行为目前只有源码依据，没有运行观察。
- **`FILE STATUS = "00"` 不等于数据已经落盘。** 把 `accepted.txt` 做成指向 `/dev/full` 的符号链接后运行：9 行标准输出、两次 `クローズ=... 成功`、退出码 `0` 都照常出现，但设备没有接受任何数据。可见本课的四条记录（合计 72 字节）填不满运行时的输出缓冲，刷写失败没有在 `WRITE` 或 `CLOSE` 上反映出来；这是缓冲与运行时实现的边界（推测与本工具链的缓冲和关闭处理有关，未进一步定位）。生产批次要真正保证落盘需另加手段，本课不提供。
- **没有输入文件，因此没有"空输入"场景。** 能失败的只有输出侧；输入为空、行过长、字段缺失等属于第 15、17、18 课。
- 记录区 35 字节的截断行为只做了编译期观察（把样例文本加长到 46 字符时 `-Wall` 报 `warning: value size exceeds data size [-Wtruncate]`，写出的是前 35 字节）；行尾去空格用一条 35 字节、末位为空格的记录单独验证。

## 走一遍真实流程

把本课这个程序放进一整条夜间链路里，它站在中间偏后的位置：

1. **凌晨 0:30 左右**，上游核心系统把当日交易导成文件，扔进共享目录。把它读进来是[第 15 课](../15_sequential-file-read/README.md)的事。
2. **凌晨 1 点**，校验程序跑完，得到一列已经分好类的"接受/拒绝"结果——判断用第 04 课起学的那套条件选择，分类用第 05 课的 `EVALUATE`，暂存用第 11 课的 `OCCURS` 表。本课拿到的就是这列结果（用的是四条程序内样例，代替真实数据）。
3. **本课这一步**，把结果分别写进 `accepted.txt` 和 `rejected.txt`。这是"处理结果"第一次变成离开进程还存在的文件。
4. **早上 7:50 起**，复核岗打开拒绝文件，逐条处理需要人工判断的记录。
5. **早上 8:10**，下游过账程序取走接受文件继续跑。第 [22 课](../22_file-processing-practice/README.md)起把"读入→校验→写出"串成完整批次，第 [32 课](../32_bank-reconciliation-project/README.md)是最终项目；中途怎么记日志、怎么区分业务拒绝和系统故障，分别是第 [27](../27_logging/README.md) 课和第 [26](../26_error-handling/README.md) 课。

一句话总结这条链上的位置：本课不是终点，而是**把结果交出去的那道闸门**。闸门这边是内存里的判断，闸门那边才是别人真正能用的东西——所以这道闸门漏没漏，比判断对不对更容易被忽略。

## 这份代码进了生产会怎样

- **谁调度它**：夜间批处理调度器，通常排在"校验程序跑完、结果就绪"之后。它只认可执行文件路径和退出码，不看你的屏幕。
- **谁看它的"输出"**：这份程序的输出不是屏幕，是那两份文件。接受文件由下游过账/入账程序取走接着跑；拒绝文件进人工复核队列。
- **出事谁被叫起来**：退出码非 `0` 时值班的人得起来，先看状态码（比如 `37`，权限/类型类错误），再看文件是不是被创建成了空壳。最麻烦的不是非零退出码，而是"退出码 0、文件却空着"（见"证据来源与验证范围"里 `/dev/full` 的边界）。
- **下一个系统怎么接**：接受文件的消费者是后续的过账程序；本仓库里第 [22](../22_file-processing-practice/README.md)、[26](../26_error-handling/README.md)、[27](../27_logging/README.md) 和 [32](../32_bank-reconciliation-project/README.md) 课都会用到 `accepted.txt`/`rejected.txt` 这条产物线，只是记录内容和宽度按各自的接口重新定义。第 [17 课](../17_fixed-length-files/README.md)会说明"没有换行符"的定长输出与 `LINE SEQUENTIAL` 的差别，第 [18 课](../18_csv-processing/README.md)才真正解析外部输入。
- **第一个月最容易出的事故**：把"重跑"想当然当成"幂等"。本课每次重跑写出同样四条，看起来很像幂等，其实只是"覆盖 + 固定条数"凑巧得到同一结果；哪天少写了一条，旧文件的残行不会自己消失。

真实生产作业还要另外约定：输出文件名带批次号/日期、追加还是覆盖、临时文件写完后原子改名、部分输出的清理与重跑规则、编码与校验位、以及失败时的告警。本课只实现了其中的"清空重建 + 非零退出码 + 不回滚"，其余一项都没有。

## 练习与参考

### 修改练习（有答案）

1. **改路由**：从本课原始 [`lesson.cob`](./lesson.cob) 开始，只改 `1000-LOAD-RESULTS` 里第四项的两行——把 `MOVE "R" TO WS-RESULT-DESTINATION(4)` 改成 `MOVE "A"`，并把 `TXN-000004` 那条记录文本的最后一个字符也改成 `A`。预期标准输出仍是 9 行，但第 6 行变成 `書込=受理 取引=000004`、第 9 行变成 `SUMMARY 受理=03 拒否=01`；`accepted.txt` 变 3 行 108 字节、`rejected.txt` 变 1 行 36 字节；退出码仍为 `0`。
2. **核对覆盖与重跑**：在临时运行目录先执行 `printf 'OLD\n' > accepted.txt` 和 `printf 'OLD\n' > rejected.txt`，再运行未修改的程序。预期标准输出与正常路径逐字节相同（9 行）、退出码 `0`；两个文件从 4 字节变成 72 字节，内容只有样例四行，`OLD` 消失。

完整题目（基线、改动约束、命令、逐行预期差异与需要回答的问题）见 [`exercise.md`](./exercise.md)，参考答案只覆盖这两项，见 [`answer.md`](./answer.md)。

### 举一反三练习（无答案）

为"需要人工复核"的结果加第三条链路：给结果表加入第三个目的地标记（例如 `H`），为它声明新的输出文件（例如 `review.txt`），让 `EVALUATE` 多一个 `WHEN` 分支、计数与 `SUMMARY` 各多一项。自己决定文件名、记录内容和宽度，并说明如何核对结果：每份文件的行数与字节数、三个计数之和是否等于表里的条数、以及记录末尾标记与所在文件名是否一一对应。题目见 [`exercise.md`](./exercise.md)，本题不提供答案。

## 参考资料

- [GnuCOBOL Programmer's Guide：ENVIRONMENT DIVISION / FILE-CONTROL（`SELECT`、`ORGANIZATION`、`FILE STATUS` 状态码清单）](https://superbol.eu/gnucobol/gnucobpg/chapter5.html#select)
- [GnuCOBOL Programmer's Guide：LINE SEQUENTIAL](https://superbol.eu/gnucobol/gnucobpg/chapter5.html#organization-line-sequential)
- [GnuCOBOL Programmer's Guide：OPEN](https://superbol.eu/gnucobol/gnucobpg/chapter7.html#open)
- [GnuCOBOL Programmer's Guide：WRITE](https://superbol.eu/gnucobol/gnucobpg/chapter7.html#write)
- [课程总目录](../DIRECTORY.md)
- [仓库课程主页](../../README.md)
