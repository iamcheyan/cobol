# 第 28 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三题答案。两项都要执行 `./build.sh run`，让子程序目标文件重新编译并与主程序重新链接，否则改的是源码、跑的还是旧可执行文件。

```sh
./build.sh check
./build.sh run
echo $?
./build.sh clean
```

## 1. 将超额取款改为 1000.00

把 `1300-POST-OVERDRAFT` 改为：

```cobol
           MOVE 1000.00 TO WS-TRANSACTION-AMOUNT
```

此时余额为 `1000.00 + 125.50 − 25.25 = 1100.25`，`1000.00 ≤ 1100.25`，所以这笔取款成功，余额变为 `100.25`。账户报告与计数变为：

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0000100.25
集計 記帳=003 拒否=002
```

`build/batch.log` 的第三条交易事件由 `STATUS=INSUFFICIENT` 变为：

```text
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
```

不变量自查：`3 + 2 = 5`。控制流：`CALL "POST-TRANSACTION28"` 在 `2000-CALL-POSTER` 中发出，`GOBACK` 把控制返回该段；过账模块更新余额并写状态，`記帳` 计数由主程序的 `2100-REPORT-RESULT` 增加。

## 2. 将未知交易类型改为存款

恢复原始源码后，把 `1400-POST-UNKNOWN-TYPE` 改为：

```cobol
           MOVE "D" TO WS-TRANSACTION-TYPE
```

金额仍为 `1.00`。这笔存款成功，余额由 `1100.25` 变为 `1101.25`：

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0001101.25
集計 記帳=003 拒否=002
```

`build/batch.log` 保留序号 `004`，类型与状态变为：

```text
EVENT=TRANSACTION NO=004 ACCOUNT=A000000001 TYPE=D STATUS=POSTED
```

不变量自查：`3 + 2 = 5`。两题都说明同一点：模块接口（Copybook 顺序与状态取值）不变时，改的只是**业务输入**，所以计数与日志结构都不需要调整；反过来，若改了 Copybook 的字段宽度或顺序，就必须重新编译所有模块并重跑。
