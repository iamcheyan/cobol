# 第 27 课修改练习参考答案

本答案只回答 `exercise.md` 中的修改练习，不提供举一反三练习答案。两项都在 `build/` 工作目录里做：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

## 1. 将第二笔金额修正为有效值

把 `build/transactions.txt` 第二行改为：

```text
A00002|00150
```

运行 `(cd build && ./lesson_27)`。该记录的业务事件由拒绝变为接受：

```text
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=RECORD_ACCEPTED NO=002 ACCOUNT=A00002
```

原来的 `EVENT=BUSINESS_REJECT ... REASON=BAD_AMOUNT` 不再出现；`BATCH_END` 变为：

```text
EVENT=BATCH_END INPUT=005 ACCEPTED=003 REJECTED=002 SYSTEM_ERROR=N
```

标准输出的 `集計 入力=005 受理=003 拒否=002` 与 `システムエラー=N` 同步变化，退出码仍为 `0`。`accepted.txt` 变为 3 行（新增 `A00002|00150`），`rejected.txt` 变为 2 行。

不变量自查：`5 = 3 + 2`；`ACCEPTED=003` 等于 `accepted.txt` 的 3 行，`REJECTED=002` 等于 `rejected.txt` 的 2 行。

业务拒绝本来就是“处理完成”的结果，减少一条拒绝只是多接受了一条记录；输入、输出和日志文件的操作都没有出错，所以 `SYSTEM_ERROR=N`、退出码 `0`。

## 2. 缺失输入文件

删掉 `build/transactions.txt`（并删掉上一题留下的结果文件）后运行 `(cd build && ./lesson_27)`。标准输出为：

```text
エラー=OPEN_INPUT STATUS=35
集計 入力=000 受理=000 拒否=000
システムエラー=Y
```

退出码为 `1`。`build/batch.log` 的完整内容为：

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=SYSTEM_ERROR OP=OPEN_INPUT STATUS=35
EVENT=BATCH_END INPUT=000 ACCEPTED=000 REJECTED=000 SYSTEM_ERROR=Y
```

顺序说明：`BATCH_START` 在日志打开成功后、业务输入打开前写入；输入打开失败（状态 `35`）后写 `SYSTEM_ERROR`；最后写 `BATCH_END`，其 `SYSTEM_ERROR=Y` 明确标出这次运行不完整——避免把“没有业务记录”误读成成功的空批次。输入文件一次也没有打开成功，所以 `INPUT=000`。
