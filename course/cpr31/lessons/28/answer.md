# 第 28 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三题答案。每次都要执行 `build.sh run`，让子程序目标文件重新编译并与主程序链接。

## 1. 将超额取款改为 1000.00

修改 `1300-POST-OVERDRAFT`：

```cobol
           MOVE 1000.00 TO WS-TRANSACTION-AMOUNT
```

第 3 笔现在返回 `POSTED`，账户报告和批次计数变为：

```text
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0000100.25
SUMMARY POSTED=003 REJECTED=002
```

`batch.log` 的第 3 笔事件变为：

```text
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
```

## 2. 将未知交易类型改为存款

修改 `1400-POST-UNKNOWN-TYPE`：

```cobol
           MOVE "D" TO WS-TRANSACTION-TYPE
```

保留 1.00 金额。第 4 笔现在成功，最终报告为：

```text
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0001101.25
SUMMARY POSTED=003 REJECTED=002
```

`batch.log` 保留序号 `004`，交易类型改为 `D`，状态为 `POSTED`。主程序仍拥有计数，`POST-TRANSACTION28` 仍负责更新余额并返回状态。
