# 第 25 课：USING——调用参数与接口契约


## 一、课程目标

学完本课后，你可以：

- 按位置顺序匹配调用方 `CALL ... USING` 与子程序 `PROCEDURE DIVISION USING` 的参数。
- 区分 `BY REFERENCE`、`BY CONTENT` 和 `BY VALUE` 对调用方存储的影响。
- 在子程序 `LINKAGE SECTION` 中声明与接口 Copybook 一致的参数类型。
- 解释为什么本课的 `BY VALUE` 参数使用 `USAGE BINARY-LONG`。
- 用调用后的值检查接口是否符合预期，并在检查失败时返回非零状态。

## 二、接口定义

[`copybooks/AMOUNT-INTERFACE.CPY`](./copybooks/AMOUNT-INTERFACE.CPY) 声明一个 `AMOUNT-ARGUMENT USAGE BINARY-LONG`。调用方在 `WORKING-STORAGE SECTION` 引入它；两个子程序在 `LINKAGE SECTION` 引入同一声明。这样三份源文件共享同一个参数名称、符号属性和存储类型。

主程序 [`lesson.cob`](./lesson.cob) 依次调用 [`add_one_25.cob`](./add_one_25.cob) 和 [`report_binary_25.cob`](./report_binary_25.cob)：

| 调用方式 | 调用方写法 | 子程序中的可见内容 | 被调用后调用方字段 |
|---|---|---|---|
| `BY REFERENCE` | 传字段的存储地址 | 可读写调用方原字段 | 子程序加一后变为 11 |
| `BY CONTENT` | 传一份临时内容 | 子程序可改临时字段 | 保留调用前的 20 |
| `BY VALUE` | 传完整字长数值 | 接收数值参数 | 保留调用前的 30 |

`ADD-ONE` 的 `PROCEDURE DIVISION USING AMOUNT-ARGUMENT` 默认以 `BY REFERENCE` 接收地址。因此 `BY CONTENT` 调用把临时字段地址交给该子程序；它在临时字段上加一，但调用方原字段不变。`REPORT-BINARY` 的 `PROCEDURE DIVISION USING BY VALUE AMOUNT-ARGUMENT` 与调用方 `BY VALUE` 匹配，只显示收到的数值。

## 三、数据类型与实现边界

GnuCOBOL Programmer’s Guide 说明，`BY VALUE` 面向完整字长的二进制数值参数；本课用 `USAGE BINARY-LONG` 表达该接口。Copybook 不加 `PIC` 子句，直接采用该 GnuCOBOL 用法。

当前 GnuCOBOL 3.2.0 对 `BY VALUE` 编译会输出警告：`handling of parameters passed BY VALUE is unfinished; implementation is likely to be changed`。该警告来自编译器，本课保留这个方式用于演示并在运行时核对结果。生产接口应针对选定的 GnuCOBOL 版本和 ABI 验证 BY VALUE；编译警告表示它不适合作为未经验证的稳定互操作契约。

## 四、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only -I copybooks lesson.cob add_one_25.cob report_binary_25.cob
cobc -x -Wall -I copybooks -o "$scratch_dir/lesson_25" \
  lesson.cob add_one_25.cob report_binary_25.cob
"$scratch_dir/lesson_25"
```

语法检查和编译会显示上述 `BY VALUE` 警告；成功条件是编译命令返回 0，示例运行返回 0 且所有调用后检查通过。

标准输出：

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
MODE REFERENCE=001 CONTENT=001 値=001
```

三份程序的组合语法检查、`-Wall` 编译链接和运行已实际验证。运行时本机可能在标准错误中显示 `Warning: program compiled against libxml 212 using older 209`；它与 `BY VALUE` 编译器警告属于不同信息，都不是标准输出。

## 五、逐步读代码

1. `AMOUNT-INTERFACE.CPY` 定义一个完整字长二进制参数；调用方和子程序都 COPY 它。
2. `1100-TEST-REFERENCE` 先把 10 和期望值 11 放入调用方字段，再显式使用 `BY REFERENCE`。
3. `ADD-ONE` 通过 LINKAGE 收到字段地址并加一；调用方返回后读到 11。
4. `1200-TEST-CONTENT` 以 `BY CONTENT` 调用相同子程序。子程序显示临时副本已变成 21，调用方仍为 20。
5. `1300-TEST-VALUE` 把 30 作为二进制值传给只读的 `REPORT-BINARY` 子程序；调用方字段仍为 30。
6. `8100-CHECK-ACTUAL` 比较调用后的调用方存储与每种模式的预期，并统计通过/失败。
7. `RETURN-CODE` 在任何检查失败时设为 1，便于脚本或批次构建发现接口行为不符合预期。

## 六、修改练习（有答案）

1. 在 `add_one_25.cob` 中把 `ADD 1` 改成 `ADD 2`。在主程序的 `1100-TEST-REFERENCE` 中把期望值从 11 改为 12。重新编译三个源文件，核对 BY REFERENCE 与 BY CONTENT 的调用后结果。
2. 将主程序 `1200-TEST-CONTENT` 的 `BY CONTENT` 改为 `BY REFERENCE`，并将该段期望值从 20 改为 21。重新编译运行，观察该调用现已修改调用方字段。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

把接口扩展为金额与结果状态两个字段。让子程序只通过 `BY REFERENCE` 输出字段返回 `VALID` 或 `REJECTED`；再比较将结果字段改为 `BY CONTENT` 后调用方是否还能接收到结果。记录参数顺序、PIC/USAGE 定义，以及调用前后的每个字段。

本题不提供答案。不用 `BY VALUE` 传递 COBOL group item，也不假设三个传递方式具有相同的存储布局。

## 八、企业实战补充

USING 是主程序和子程序之间的二进制接口：字段次序、存储类型、数据方向和传递方式都必须一致。`BY REFERENCE` 适合需要由子程序更新调用方存储的接口；`BY CONTENT` 让子程序处理一份输入副本；`BY VALUE` 适合明确的标量 ABI，并受编译器与平台约束。大型项目通常还用接口 Copybook 固定参数布局，并通过构建依赖保证所有消费者同步编译。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide：CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide：USAGE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#USAGE)
