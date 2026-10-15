# 第 17 课修改练习参考答案

本答案只回答 [`exercise.md`](./exercise.md) 中的修改练习，不提供举一反三练习的答案。

## 输出 FD 改为账户号在前

改动位置：`lesson.cob` 中 `FD BALANCE-FILE` 下的 `01 FD-BALANCE-RECORD`。

改前：

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

改后：

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

命令行：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_17 lesson.cob
cp accounts.dat build/
(cd build && ./lesson_17)
wc -c build/balances.dat
cmp accounts.dat build/balances.dat
rm -rf build
```

**标准输出：** 与基线完全相同，仍是 5 行。三条 `MOVE` 语句按字段名赋值，字段名没有改变，所以每条记录打印的账户号、客户号、余额数值都不变：

```text
ファイルを開きました
出力 口座番号=0001234567 顧客番号=C0001042 残高=0001000.00
出力 口座番号=0002468101 顧客番号=C0002042 残高=0000020.00
出力 口座番号=0007654321 顧客番号=C0003042 残高=0000250.75
クローズ完了 件数=03
```

**输出文件：** `wc -c build/balances.dat` 输出 `81`，即 `3 × 27`；`cmp accounts.dat build/balances.dat` 无输出且退出码为 0，说明输出与输入逐字节相同（文件内仍没有换行字节，下面分行只是查看效果）：

```text
0001234567C00010420001000000
0002468101C0002042000002000
0007654321C0003042000025075
```

对照字节位置，第 1 条的 `0001234567` 占输出字节 1–10、`C0001042` 占 11–18、`000100000` 占 19–27，与输入记录的偏移一致。

**与基线的完整差异：**

| 记录 | 基线 `balances.dat` | 改序后 `balances.dat` |
|---:|---|---|
| 1 | `C00010420001234567000100000` | `0001234567C00010420001000000` |
| 2 | `C00020420002468101000002000` | `0002468101C0002042000002000` |
| 3 | `C00030420007654321000025075` | `0007654321C0003042000025075` |
| 文件总字节数 | 81 | 81 |

**原因：** `MOVE` 按数据名赋值，与声明顺序无关；`WRITE` 按 `01` 记录内部各字段的声明顺序依次写出该记录的字节。因此改变 `05` 声明的顺序就改变了各字段在输出记录中的偏移，而每条记录的宽度仍由 `PIC` 决定为 `10 + 8 + 9 = 27` 字节，记录数和文件总字节数（`3 × 27 = 81`）都不变。
