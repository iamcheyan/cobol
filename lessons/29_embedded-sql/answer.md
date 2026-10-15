# 第 29 课修改练习参考答案

本文件只回答 `exercise.md` 的两项修改练习，不提供举一反三题答案。两项都从原始 `lesson.cob` 开始，每次运行：

```sh
./build.sh run
echo $?
```

## 1. 查询第二个账户

把 `MAIN-PROCEDURE` 里第一次赋值改为：

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

第一行输出变为：

```text
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
```

`SELECT ... INTO` 把 `ACCOUNT_NO`、`CUSTOMER_ID`、`BALANCE` 三列分别写进 `WS-ACCOUNT`、`WS-CUSTOMER`、`WS-BALANCE`；`BALANCE` 是 `PIC 9(7)V99`，`875.00` 补零显示为 `00875.00`。第二行查询 `A99999999X` 仍为 `NOT_FOUND`，`接続=成功`/`切断=成功` 不变，退出码 `0`。

## 2. 将第二次查询改为已有账户

从原始源码开始，把第二次赋值改为：

```cobol
               MOVE "A000000002" TO WS-LOOKUP-ACCOUNT
```

两次查询都命中同一行，标准输出为：

```text
接続=成功
検索=A000000001 状態=FOUND 顧客=C0001001 BALANCE=01250.75
検索=A000000002 状態=FOUND 顧客=C0001002 BALANCE=00875.00
切断=成功
```

第二次查询的 `SQLCODE` 由 `100`（无匹配行）变为 `0`（成功），`WHEN 100` 分支不再执行；退出码仍为 `0`。

两题都说明同一件事：`SQLCODE = 100` 是**业务结果**，只要 SQL 本身没问题，批次就该照常收尾并返回 `0`；只有 `0`、`100` 之外的值才走 `WHEN OTHER`，显示 `状態=エラー SQLSTATE=` 并以退出码 `1` 结束。
