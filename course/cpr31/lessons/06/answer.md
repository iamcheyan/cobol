# 第 06 课修改练习参考答案

本答案只覆盖 `exercise.md` 中对 `WS-LAST-SAMPLE` 的修改，不提供举一反三练习答案。编译和运行命令使用 README 中的临时目录流程。

## 最后序号为 0

修改为 `01 WS-LAST-SAMPLE PIC 9 VALUE 0.`。初始索引为 1，`1 > 0` 在循环体执行前成立，因此没有样例行：

```text
LAST-SAMPLE=0
SAMPLES-PROCESSED=000
```

## 最后序号为 1

修改为 `01 WS-LAST-SAMPLE PIC 9 VALUE 1.`。只处理序号 1；递增为 2 后，`2 > 1`，循环结束：

```text
LAST-SAMPLE=1
SAMPLE=001 CODE=D AMOUNT=125.50
SAMPLES-PROCESSED=001
```

## 最后序号为 3

保留原始初值，三笔固定样例各处理一次：

```text
LAST-SAMPLE=3
SAMPLE=001 CODE=D AMOUNT=125.50
SAMPLE=002 CODE=W AMOUNT=040.10
SAMPLE=003 CODE=T AMOUNT=075.00
SAMPLES-PROCESSED=003
```

## 最后序号为 4

修改为 `01 WS-LAST-SAMPLE PIC 9 VALUE 4.`。索引 4 仍小于等于上限，所以循环体执行；但示例只定义了三个样例，第四轮由 `WHEN OTHER` 标记：

```text
LAST-SAMPLE=4
SAMPLE=001 CODE=D AMOUNT=125.50
SAMPLE=002 CODE=W AMOUNT=040.10
SAMPLE=003 CODE=T AMOUNT=075.00
SAMPLE=UNMAPPED
SAMPLES-PROCESSED=004
```

严格大于条件 `index > last` 只在索引超过上限后为真，所以最后序号本身会被处理。
