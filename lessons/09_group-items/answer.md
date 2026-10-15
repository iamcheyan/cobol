# 第 09 课修改练习参考答案

把 `WS-ACCOUNT-NUMBER` 的初值改为 `VALUE "0007654321".`，重新编译运行：

```sh
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

标准输出只有 3 行变化，退出码 0：

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

原因：账户号固定在 58 字节记录的第 21–30 字节（前有 `8+12` 字节），只替换这 10 个字符，宽度与声明顺序不变，故两处整组输出同步变化，总长仍为 58 字节。
