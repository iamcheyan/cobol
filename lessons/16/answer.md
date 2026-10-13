# 第 16 课修改练习参考答案

本答案只回答 `exercise.md` 中的两项修改练习，不包含举一反三练习答案。

## 把第四项改为接受结果

在 `1000-LOAD-RESULTS` 中同时修改路由标记和记录末尾标记：

```cobol
           MOVE "A" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|A"
               TO WS-RESULT-TEXT(4)
```

第四项现在进入接受文件。预期文件内容为：

`accepted.txt`

```text
TXN-000001|0001234567|D|000125.50|A
TXN-000002|0007654321|T|000040.00|A
TXN-000004|0009999999|T|000020.00|A
```

`rejected.txt`

```text
TXN-000003|0002468101|X|000000.00|R
```

汇总为 `SUMMARY ACCEPTED=03 REJECTED=01`。

## 检查 OPEN OUTPUT 的覆盖行为

在程序当前工作目录先创建两个旧文件：

```sh
printf 'OLD\n' > accepted.txt
printf 'OLD\n' > rejected.txt
```

运行程序后，两个文件只包含 README 列出的样例结果行，不再包含 `OLD`。`OPEN OUTPUT` 创建文件或替换已有内容，不执行追加。
