# 第 09 课练习：Group Item

## 修改练习（答案见 `answer.md`）

从原始 `lesson.cob` 开始，把 `WS-ACCOUNT-NUMBER` 的初值由 `0001234567` 改为 `0007654321`：

```cobol
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0007654321".
```

约束：只改这一处 `VALUE`，不动 `PIC`、层级号与声明顺序。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

预期差异：标准输出只有下列 3 行变化（第 3 行及两处整组内容的第 21–30 字节），其余 7 行和退出码 0 不变。

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

## 举一反三（不提供答案）

为付款指令设计 `01` 记录，含付款人、收款人、付款信息三个 `05` 子组：各组若干带 `VALUE` 的 `10` 基本项，至少两个子组用相同的字段名并以 `OF` 分别引用；再声明等宽的 `PIC X(n)` 接收项，整组 `MOVE` 后显示。自己算出记录字节数与字段位置并用输出核对。

限制：只用本课层级数据项与固定 `VALUE`，不加 `REDEFINES`、`OCCURS`、文件输入或数据库。
