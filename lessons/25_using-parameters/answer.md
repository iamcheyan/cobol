# 第 25 课修改练习参考答案

本答案只覆盖 [`exercise.md`](./exercise.md) 中的两项修改练习，不提供举一反三练习的答案。两项都从当前源码开始，每次都用同一命令重新编译三个源文件：

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

下面的标准输出是实际运行结果（每段都从原始源码重新开始，两项互不依赖）。`BY VALUE` 的 `-Wunfinished` 编译警告在两种答案里都照旧出现，与业务行为无关。

## 1. 把子程序增量改为 2

改动：

- `add_one_25.cob`：`ADD 1 TO AMOUNT-ARGUMENT` → `ADD 2 TO AMOUNT-ARGUMENT`
- `lesson.cob` 的 `1100-TEST-REFERENCE`：`MOVE 11 TO WS-EXPECTED` → `MOVE 12 TO WS-EXPECTED`

标准输出（11 行，退出码 `0`）：

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000012
呼出側=呼出後 方式=BY REFERENCE 値=000000012 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000022
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=001 BY CONTENT=001 値=001
```

与原始输出的差异只有三处：`被呼出側=加算後` 在两段里从 `011`/`021` 变成 `012`/`022`，以及 `BY REFERENCE` 段的调用后值从 `011` 变成 `012`。原因：`ADD-ONE` 收到的仍然是同一个参数的存储地址（`BY REFERENCE`）或同一份临时副本（`BY CONTENT`），增加量从 1 变 2 后，子程序内部看到的值都要加 2；但只有 `BY REFERENCE` 段改到的是调用方自己的存储，所以调用方字段从 10 变 12，而 `BY CONTENT` 段的调用方字段仍是 20。`BY VALUE` 段调用的是另一个子程序，不受影响。

## 2. 将第二次调用改为 BY REFERENCE

改动（全在 `lesson.cob` 的 `1200-TEST-CONTENT`）：

- `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` → `CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT`
- `MOVE 20 TO WS-EXPECTED` → `MOVE 21 TO WS-EXPECTED`
- `MOVE "BY CONTENT" TO WS-MODE` → `MOVE "BY REFERENCE" TO WS-MODE`

标准输出（11 行，退出码 `0`）：

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY REFERENCE 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY REFERENCE 値=000000021 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=002 BY CONTENT=000 値=001
```

差异：第 4 行的方式标签变成 `BY REFERENCE`；第 6 行的调用后值由 `000000020` 变成 `000000021`（调用方现在会被子程序改写）；汇总行变成 `方式 BY REFERENCE=002 BY CONTENT=000 値=001`。原因：传递方式改成 `BY REFERENCE` 后，子程序加的就是调用方存储本身，调用方从 20 变 21，因此预期值也必须同步改成 21 才能通过自检；而 `WS-MODE` 决定这一次成功计入哪个方式计数，所以三项要一起改。

**只改调用方式不改预期值和标签会怎样（实测）：** 若只把 `CALL` 改成 `BY REFERENCE`，`WS-EXPECTED` 仍留 `20`、`WS-MODE` 仍留 `"BY CONTENT"`，程序会输出 `呼出側=呼出後 方式=BY CONTENT 値=000000021 確認=失敗`，汇总为 `集計 合格=002 不合格=001`、`方式 BY REFERENCE=001 BY CONTENT=000 値=001`，退出码 `1`。失败的那一次不计入任何方式计数，所以 `BY CONTENT=000` 并不代表"这次没调用过 `BY CONTENT`"，只代表"没有一次以 `BY CONTENT` 标签通过自检"。

## 结论

传递方式决定子程序对调用方存储的影响，也决定调用方在 `CALL` 之后应该看到什么值。修改任一项时，调用方式、预期值和方式标签必须一起调整，否则自检失败、退出码变 `1`，显示与分类计数会误导读者。调用方自检只观察调用方自己的存储，因此它验证不了子程序那边是否收到了正确的参数（参见 README 的"主题边界"实测）。
