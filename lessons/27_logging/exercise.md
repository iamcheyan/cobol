# 第 27 课练习：构建可定位的批次日志

本节只使用第 15–27 课讲过的内容：顺序文件读写、`FILE STATUS`、`STRING`、`EVALUATE`/`IF`、段落与 `PERFORM`。

## 修改练习（会在 `answer.md` 提供参考答案）

两项都在 `build/` 工作目录里做，不要改动仓库内的夹具。先准备：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

1. 把 `build/transactions.txt` 中的 `A00002|00X50` 改为 `A00002|00150`。运行 `(cd build && ./lesson_27)`，比较改动前后该记录对应的日志事件与 `BATCH_END` 计数，并说明为什么业务拒绝减少不代表系统错误。
2. 删掉 `build/transactions.txt` 后运行 `(cd build && ./lesson_27)`。记录退出码、标准输出的错误行，以及 `build/batch.log` 中批次开始、系统错误、批次结束三个事件的顺序。

约束：不改 `lesson.cob`；不修改课内夹具。两题都要用计数不变量自查：`BATCH_END` 里 `INPUT = ACCEPTED + REJECTED`，且 `ACCEPTED`/`REJECTED` 分别等于两个结果文件的行数。参考答案见 `answer.md`。

## 举一反三（不提供答案）

增加一条“重复账户号”业务拒绝规则，并在日志中同时写出首次与重复记录的记录号。再为两次连续运行设计不同的批次 ID，说明怎样只按日志判断某个批次是否完成，以及为什么 `BATCH_END` 存在不足以证明全部输出已原子交付。

提交源码、编译运行命令、两次运行的 `batch.log` 内容与退出码。不要在日志事件里写完整客户隐私资料，也不要省略失败批次的结束状态。本题不提供答案。
