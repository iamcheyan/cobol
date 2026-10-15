# 第 13 课修改练习参考答案

本答案只回答 `exercise.md` 的两项修改练习，不提供举一反三练习答案。两项修改各自从原始 `lesson.cob` 开始，编译运行命令为：

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_13 lesson.cob
./build/lesson_13
```

## 修改已存在账户的余额

在 `1000-LOAD-ACCOUNTS` 中改为：

```cobol
           MOVE 600.00 TO WS-ACCOUNT-BALANCE(3)
```

两种查找均匹配同一账户，返回更新后的余额：

```text
逐次検索=検出 口座=0002468101  残高=0000600.00
二分検索=検出 口座=0002468101  残高=0000600.00
```

## 追加最大账户号

将 OCCURS 上界从 4 改为 5：

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
```

在第四项之后追加唯一且大于现有键值的记录：

```cobol
           MOVE "0009999999" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

把第二个搜索目标更新为 `0009999999`。新增第五项仍满足升序和唯一键要求，两种搜索都应输出：

```text
逐次検索=検出 口座=0009999999  残高=0000075.00
二分検索=検出 口座=0009999999  残高=0000075.00
```

如果只改变 `ASCENDING KEY` 声明而没有让实际数据顺序一致，`SEARCH ALL` 的结果不可靠；声明本身不会重排表格。
