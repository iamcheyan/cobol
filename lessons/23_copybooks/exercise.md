# 第 23 课练习：共享记录声明与它的消费者

本课有两个程序共用 `copybooks/ACCOUNT-REC.CPY`：`lesson.cob`（`PROGRAM-ID. LESSON23`，交易过账）和 `account_report_23.cob`（`PROGRAM-ID. ACCOUNT-REPORT23`，账户报表）。所有改动都在本课目录的**副本**上做，不要改动仓库里的原始文件。

共同前提：

- 每条命令都在本课目录执行，Copybook 查找目录由 `-I copybooks` 提供；缺了它连语法检查都报 `ACCOUNT-REC.CPY: そのようなファイルやディレクトリはありません`。
- **不要在仓库文件上直接改**：先把两个 `.cob` 与两份 `.CPY` 复制到 `build/work` 下做成工作副本（见下面的命令），之后的命令都在副本目录执行，最后 `rm -rf build` 一次清理（`build/` 已被仓库忽略）。
- 改 Copybook 后**必须重新编译**再运行；直接运行旧可执行文件不会生效。

```sh
rm -rf build && mkdir -p build/work/copybooks
cp lesson.cob account_report_23.cob build/work/
cp copybooks/* build/work/copybooks/
cd build/work          # 后面的语法检查、编译、运行都在这里做
```

原始基线的标准输出（改动前先自己跑一遍确认）：

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A000000001 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

报表程序输出 `口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00`。

## 修改练习（答案见 [`answer.md`](./answer.md)）

### 1. 改共享声明的宽度

- 基线：原始 `copybooks/ACCOUNT-REC.CPY`、`lesson.cob`、`account_report_23.cob`（按上面命令做成 `build/work` 工作副本）。
- 改动位置与约束：只把 `build/work/copybooks/ACCOUNT-REC.CPY` 中 `05 WS-ACCOUNT-NUMBER PIC X(10).` 改为 `PIC X(8).`。**不要**改任何 `MOVE` 字面量，也不要碰 `TRANSACTION-REC.CPY`。
- 命令：对两个程序各做一次 `cobc -fsyntax-only -I copybooks`、一次 `cobc -x -Wall -I copybooks`，再运行两个可执行文件（照 [`README.md`](./README.md) 的命令）。
- 要求回答：
  1. 两次编译各输出什么？如果你的语法检查带了 `-Wall`，结论有区别吗？
  2. `lesson_23` 的七行输出是否发生变化？若有，变的是哪一行？余额与两个计数各是多少？
  3. 账户记录的实际字节数变成多少？这对第 17、20、22 课的定长接口意味着什么？
  4. 用 COBOL 的字母数字比较规则（长短操作数如何补齐）解释你观察到的交易结果。

### 2. 只改主程序的业务常量

- 基线：重新做一份干净的 `build/work` 工作副本（不要在第 1 题的改动上继续做）。
- 改动位置与约束：在 `lesson.cob` 的 `1500-POST-MISSING-ACCOUNT` 中，把 `MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT` 改成 `MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT`。不改 Copybook、不改其它段落。
- 命令：重新编译并运行需要重编译的消费者。
- 要求回答：第 5 笔去哪了？余额和两个计数各是多少？这次有哪些消费者必须重编译、哪些可以继续用旧的可执行文件，为什么？

## 举一反三（无答案）

为“月度对账单”再写第三个消费者程序（例如 `monthly_statement_23.cob`），复用同一份 `ACCOUNT-REC.CPY`，并把余额改成带符号 PIC 以表示借方余额：

- 自己决定用 `S9(7)V99` 还是 `S9(7)V99 SIGN LEADING SEPARATE`，并测出这个选择让共享记录变成多少字节（可以用 `FUNCTION LENGTH` 打印组项长度，或把记录写进定长文件再用 `wc -c`/`od -An -c` 查看字节）。
- 自己决定显示字段怎么声明才能把负号显示出来，并说明为什么原来的 `PIC 9(7).99` 不够。
- 让程序真的产生一笔借方余额（需要你改一条过账规则，指出改的是哪一条，并说明这算不算超出本课范围）。
- 交付：两个消费者（原程序与新程序）的完整编译命令、两个程序的完整标准输出、以及对“27 字节定长契约是否被破坏”的结论。

不要只重编译一个消费者，也不要把编译期的 `COPY` 说成运行时的 `CALL`。本题不提供答案。
