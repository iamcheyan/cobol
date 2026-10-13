# 第 27 课修改练习参考答案

本答案只回答 `exercise.md` 中的修改练习，不提供举一反三题答案。

## 1. 将第二笔金额修正为有效值

将夹具第二行改为：

```text
A00002|00150
```

该记录的业务事件改为：

```text
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=RECORD_ACCEPTED NO=002 ACCOUNT=A00002
```

删除原来的 `EVENT=BUSINESS_REJECT ... REASON=BAD_AMOUNT`。批次结束行改为：

```text
EVENT=BATCH_END INPUT=005 ACCEPTED=003 REJECTED=002 SYSTEM_ERROR=N
```

进程返回 0；输入文件和输出文件 I/O 均正常，只有业务拒绝数量减少。

## 2. 缺失输入文件

在不含 `transactions.txt` 的临时目录运行。GnuCOBOL 3.2.0/Linux 返回 1，控制台报告 `ERROR=OPEN_INPUT STATUS=35`。`batch.log` 的完整内容为：

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=SYSTEM_ERROR OP=OPEN_INPUT STATUS=35
EVENT=BATCH_END INPUT=000 ACCEPTED=000 REJECTED=000 SYSTEM_ERROR=Y
```

开始事件先写入；随后必需输入打开失败；批次结束事件明确标记系统错误，避免读者把“没有业务记录”误判成成功空批次。
