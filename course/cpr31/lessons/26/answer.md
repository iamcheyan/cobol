# 第 26 课修改练习参考答案

本答案只覆盖 `exercise.md` 的两项修改练习，不回答举一反三题。

## 1. 修正金额字段

把 `transactions.txt` 的第二行改为：

```text
A00002|00150
```

此行现在通过金额校验并进入 `accepted.txt`。预期标准输出：

```text
ACCEPTED ACCOUNT=A00001
ACCEPTED ACCOUNT=A00002
REJECTED ACCOUNT=A00003 REASON=ZERO_AMOUNT
ACCEPTED ACCOUNT=A00004
REJECTED ACCOUNT=A00005 REASON=BAD_WIDTH
SUMMARY INPUT=005 ACCEPTED=003 REJECTED=002
SYSTEM-ERROR=N
```

接受文件新增 `A00002|00150`；拒绝文件保留零金额和短记录。进程返回 0，因为所有文件操作成功，坏业务数据已按约定写入拒绝文件。

## 2. 让接受输出无法打开

在独立临时运行目录中复制 `transactions.txt`，再执行 `mkdir accepted.txt`。在本课验证的 GnuCOBOL 3.2.0/Linux 环境中，程序输出：

```text
ERROR=OPEN ACCEPTED STATUS=37
SUMMARY INPUT=000 ACCEPTED=000 REJECTED=000
SYSTEM-ERROR=Y
```

进程返回 1。输入已打开并由清理段落关闭；拒绝输出尚未打开，因此程序不会尝试关闭它。状态码 `37` 表示权限拒绝，包括当前目录项无法按输出文件打开的情况。
