# 第 15 课修改练习参考答案

本答案只回答 [`exercise.md`](./exercise.md) 的两项修改练习，不提供举一反三练习的答案。两项练习共用同一个临时运行目录，可反复复位：

```sh
cd lessons/15_sequential-file-read
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -x -Wall -o "$scratch_dir/lesson_15" lesson.cob
cp transactions.txt "$scratch_dir/"
```

## 1. 追加第 5 条记录

```sh
printf 'DAY-20261013|TXN-000005|D|0001234567|10.00\n' >> "$scratch_dir/transactions.txt"
wc -lc "$scratch_dir/transactions.txt"        # 5 行 238 字节 = 195 + 42 + 1
( cd "$scratch_dir" && ./lesson_15 ); echo $? # 退出码 0
```

预期标准输出（只有一处新增、一处计数变化）：

```text
オープン=OK
レコード=DAY-20261013|TXN-000001|D|0001234567|125.50
レコード=DAY-20261013|TXN-000002|T|0001234567|0007654321|40.00
レコード=DAY-20261013|TXN-000003|D|0002468101|75.00
レコード=DAY-20261013|TXN-000004|T|0007654321|0009999999|20.00
レコード=DAY-20261013|TXN-000005|D|0001234567|10.00
EOF=はい レコード数=05
クローズ=OK
```

计数从 `04` 变为 `05`：新增行是第 5 条成功读出的记录，下一次 `READ` 才到达 EOF。

复位：重新执行 `cp transactions.txt "$scratch_dir/"` 覆盖回原来的 4 行，或新建一个 `mktemp -d` 目录。该程序只读取文本，不会因为行里写了 `D` 或金额而改动余额或任何账户数据。

## 2. 读取空文件

```sh
: > "$scratch_dir/transactions.txt"
( cd "$scratch_dir" && ./lesson_15 ); echo $? # 退出码 0
```

预期标准输出：

```text
オープン=OK
EOF=はい レコード数=00
クローズ=OK
```

空文件能成功打开，所以没有 `オープン=FAILED`；第一次 `READ` 就进入 `AT END`，因此没有任何 `レコード=` 行、计数为 `00`，关闭仍然成功。若要再观察另一种结局，可额外删除夹具（`rm -f "$scratch_dir/transactions.txt"`），程序会输出 `オープン=FAILED STATUS=35` 并以退出码 `1` 结束——该场景在本课 README 的“运行与观察”中给出，不属于本练习的答案要求。
