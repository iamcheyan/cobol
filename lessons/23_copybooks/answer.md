# 第 23 课修改练习参考答案

本答案只覆盖 [`exercise.md`](./exercise.md) 中的两项修改练习，不提供举一反三练习答案。两项都从干净的工作副本开始：按 [`exercise.md`](./exercise.md) 的命令把源码复制到 `build/work`，之后的语法检查、编译、运行都在该目录执行（`-I copybooks` 不可省），最后回到本课目录 `rm -rf build` 清理。

## 1. 把共享账户号改成 `PIC X(8)`

**改动**（只动 Copybook 一行）：

```cobol
          05 WS-ACCOUNT-NUMBER PIC X(8).
```

**重新编译与运行**（两个消费者都要重编译）：

```sh
cd build/work
cobc -fsyntax-only -I copybooks lesson.cob                 # 不带 -Wall：无输出，退出码 0
cobc -fsyntax-only -Wall -I copybooks lesson.cob           # 带 -Wall：出现下面的 -Wtruncate 警告
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob         # 退出码 0，仍是警告
cobc -x -Wall -I copybooks -o account_report_23 account_report_23.cob
./lesson_23
./account_report_23
```

**编译输出**：两个程序各出现一条 `-Wtruncate` 警告，并指回 Copybook 的被改行；退出码仍为 `0`（警告不是错误）：

```text
lesson.cob:31: warning: value size exceeds data size [-Wtruncate]
lesson.cob:31: note: value size is 10 [-Wtruncate]
copybooks/ACCOUNT-REC.CPY:5: note: 'WS-ACCOUNT-NUMBER' defined here as PIC X(8) [-Wtruncate]
account_report_23.cob:16: warning: value size exceeds data size [-Wtruncate]
```

注意：不带 `-Wall`/`-Wtruncate` 时，`cobc -fsyntax-only` 和 `cobc -x` **都看不到**这条警告（实测 `cobc -x` 同样沉默）——要看到它得显式打开警告开关。

**`lesson_23` 标准输出**（只有汇总行变了）：

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A0000000 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

**`account_report_23` 标准输出**：`口座レポート 口座番号=A0000000 顧客番号=C0001009 残高=0000020.00`。

**记录长度**：`WS-ACCOUNT-RECORD` 从 27 字节变成 `8 + 8 + 9 = 25` 字节（用 `FUNCTION LENGTH(WS-ACCOUNT-RECORD)` 实测为 25）。它已经不再是第 17、20、22 课那份 27 字节账户定长接口，那些程序按 27 字节切分这份记录会整体错位。

**为什么两笔交易照样过账**：`MOVE "A000000001" TO WS-ACCOUNT-NUMBER` 因目标只有 8 字节被右截断成 `A0000000`；随后 `MOVE WS-ACCOUNT-NUMBER TO WS-TRANSACTION-ACCOUNT` 把 `A0000000` 放进 10 字节的交易账户号，得到 `A0000000` 加两个空格。`IF WS-TRANSACTION-ACCOUNT NOT = WS-ACCOUNT-NUMBER` 比较的是 10 字节与 8 字节的字母数字项，COBOL 会把短的一方补空格到等长再比较，`A0000000  ` 与 `A0000000` 因此相等，过账路径照旧。第 5 笔的常量仍是 10 字符的 `A000000099`（它属于交易 Copybook，没被改窄），与 `A0000000  ` 不等，所以仍是 `NO_ACCOUNT`。余额与计数因此与改动前完全一致——这正是本课要看的结论：**宽度改动可以既不报错也不改变任何计数，只留下一条编译警告和被悄悄截断的内容。**

## 2. 把最后一笔改成已知账户

**基线**：重新做一份干净的 `build/work` 工作副本（不要沿用第 1 题的改动）。

**改动**（只动 `lesson.cob` 一处）：

```cobol
           MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT
```

**重新编译与运行**：只需重编译主程序（`account_report_23.cob` 的源码与它引入的 `ACCOUNT-REC.CPY` 都没变，旧可执行文件仍然有效）：

```sh
cd build/work
cobc -x -Wall -I copybooks -o lesson_23 lesson.cob
./lesson_23
```

**编译输出**：无警告、无错误，退出码 `0`。

**`lesson_23` 标准输出**：

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账成功 类型=D 金额=0000001.00
账户号码=A000000001 客户号码=C0001001 余额=0001101.25
成功笔数=003 拒绝笔数=002
```

第 5 笔的账户号与共享账户记录一致，因此跳过 `NO_ACCOUNT`，按类型 `D` 加 1.00：余额 `1100.25 + 1.00 = 1101.25`，成功后计数变为 3，拒绝只剩 `INSUFFICIENT` 与 `BAD_TYPE`，合计仍是 5 笔。`account_report_23` 的输出不变：`口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00`。

**与第 1 题的对照**：这次改的是**主程序的业务常量**，记录布局没有变化，所以只有 `lesson.cob` 需要重编译；第 1 题改的是**共享声明的宽度**，布局变了，两个消费者都必须重编译，而且外部定长接口跟着失效。
