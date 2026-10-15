# 第 12 课修改练习参考答案

只回答 `exercise.md` 的修改练习两项步骤，不包含举一反三练习答案。第 1 步从本课原始 `lesson.cob` 开始；第 2 步在第 1 步结果上继续。

## 第 1 步：把账户表扩到第五项

容量与已装入项数同步改为 5：

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
```

```cobol
       01 WS-LAST-ACCOUNT PIC 9 VALUE 5.
```

在 `1000-LOAD-ACCOUNTS` 第四笔之后追加第五笔；注意把第四行末尾的句号改为无句号，只在第五笔末尾保留句号：

```cobol
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4)
           MOVE "0005550001" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

装载仍用数字下标、遍历仍用索引，循环结构不动。重新编译运行后，标准输出为：

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
口座=0005550001 BALANCE=0000075.00
処理件数=005
```

差异只在末尾：新增第 5 行，处理件数由 `004` 变为 `005`；前四行逐字节不变，因为前四笔装载语句和它们的下标都没有改动。原因：容量、已装入项数与循环终点同步由 4 改为 5，索引从 1 逐项前进到 5；处理完第 5 项后索引为 6，`UNTIL 索引 > WS-LAST-ACCOUNT` 成立而结束。`cobc -fsyntax-only` 与 `cobc -x -Wall` 均无诊断并返回 0，运行退出码为 0。

## 第 2 步：越界边界

只把 `WS-LAST-ACCOUNT` 改为 `6`（`OCCURS` 仍为 5）时，编译器不会报错：循环终点是运行期比较，`WS-ACCOUNT-IDX` 在编译期不是已知越界的常量（这与写死的越界字面量下标不同）。

`cobc -x -Wall` 返回 0，没有诊断；运行退出码仍为 0，标准输出在第 5 行之后多出一行表外数据，处理件数显示为 `006`：

```text
口座=0001234567 BALANCE=0001000.00
口座=0007654321 BALANCE=0000250.75
口座=0000000042 BALANCE=0000000.00
口座=0002468101 BALANCE=0000520.00
口座=0005550001 BALANCE=0000075.00
口座=<表外无意义字节> BALANCE=<表外无意义字节>
処理件数=006
```

第 6 行（上表用 `<表外无意义字节>` 表示）读的是账户表之外的存储区，不属于本表，也不是有效账户数据：实测打印出无意义字节（其中含 NUL，终端可能显示为空或乱码），因此它不可作为业务结果。这正是“退出码 0 不等于结果正确”的例子。

开启运行期下标检查后结果不同：

```sh
cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT -o build/lesson_12_checked lesson.cob
./build/lesson_12_checked
```

标准输出只到第 5 行为止，标准错误出现 libcob 越界错误（行号与文件路径以本机输出为准）：

```text
libcob: lesson.cob:36: error: subscript of 'WS-ACCOUNT-BALANCE' out of bounds: 6
note: maximum subscript for 'WS-ACCOUNT-BALANCE': 5
```

程序在访问第六项时终止，退出码为 1。结论：默认编译不保护索引越界；真正的保证是“循环终点不超过表容量”这一约定。需要运行期兜底时，用上面的检查选项编译，越界会立即变成可见的失败。
