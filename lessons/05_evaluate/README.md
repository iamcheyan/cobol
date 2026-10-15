# 第 05 课：EVALUATE 多值分类

> 示例使用 GnuCOBOL 3.2.0 默认方言与固定格式。

## 一、课程目标

学完本课后，你可以：

- 用 `EVALUATE` 对一个业务字段的多个值进行分类。
- 用 `WHEN` 为存款、取款和转账指定清晰分支。
- 用 `WHEN OTHER` 显式处理未定义代码。
- 说明 `EVALUATE` 只选择匹配的分支，不会执行显示出来的业务动作。
- 为字符代码考虑大小写、空值、版本和接口所有权。

## 二、知识讲解

### EVALUATE 与 WHEN

本课采用简单形式：

```cobol
EVALUATE WS-TRANSACTION-CODE
    WHEN "D"
        DISPLAY "分類=DEPOSIT"
    WHEN "W"
        DISPLAY "分類=WITHDRAWAL"
    WHEN OTHER
        DISPLAY "分類=UNKNOWN"
END-EVALUATE
```

`EVALUATE` 的 subject 是 `WS-TRANSACTION-CODE`。每个 `WHEN` 给出一个可能值。程序选择匹配的分支执行，到 `END-EVALUATE` 结束这一段多路选择。`WHEN OTHER` 是没有任何显式 `WHEN` 匹配时执行的默认分支。

这与一串 `IF` / `ELSE` 判断实现同一类选择；把有限的代码映射集中写在 `EVALUATE` 中，交易分类通常更容易审阅。GnuCOBOL 也支持 `EVALUATE TRUE` 配合条件表达式；本课先学习一个 subject 对多个精确值的简单形式。

### 未知代码要有明确处理

本例的接口约定是大写 `D`、`W`、`T`。COBOL 字符值比较精确：小写 `d` 不匹配大写 `D`，空格和其他字符会进入 `WHEN OTHER`。如需大小写归一化或别名，必须由接口契约确定，不能默默增加代码含义。

未知代码被标为 `REJECT_FOR_REVIEW`，这是本例输出的处理建议。程序没有连接拒绝队列、写日志或改变账户；这些都要在后续课程中实现。

## 三、完整示例

[`lesson.cob`](./lesson.cob) 使用固定输入 `D` 展示存款分支。程序先显示交易参考号和代码，再输出一个分类与一个动作标签。

### 数据字段

| 字段 | PIC / 初值 | 含义 |
|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / `TXN-00000001` | 交易标识文本 |
| `WS-TRANSACTION-CODE` | `X(1)` / `D` | 按本课接口约定映射交易类别 |

### 程序逐步解析

1. `IDENTIFICATION DIVISION` 和 `PROGRAM-ID` 命名程序；`WORKING-STORAGE SECTION` 声明固定的交易号与代码。
2. 两条 `DISPLAY` 先输出输入值。交易号和类别码是文本标识，不参与算术。
3. `EVALUATE WS-TRANSACTION-CODE` 将单字符代码作为 subject。
4. `WHEN "D"` 输出 `DEPOSIT` 与 `ADD_TO_ACCOUNT`；`WHEN "W"` 输出 `WITHDRAWAL` 与 `SUBTRACT_FROM_ACCOUNT`；`WHEN "T"` 输出 `TRANSFER` 与 `PROCESS_BOTH_ACCOUNTS`。
5. `WHEN OTHER` 输出 `UNKNOWN` 与 `REJECT_FOR_REVIEW`，覆盖未列出的代码。
6. `END-EVALUATE` 显式关闭选择范围；`STOP RUN.` 结束程序句子。

类别和动作是静态显示标签，程序并不执行存款、取款或转账。

## 四、编译、运行和输出

程序不读取键盘、文件或数据库。`VALUE "D"` 初始化样例代码。运行命令：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_05" lesson.cob
"$scratch_dir/lesson_05"
```

GnuCOBOL 3.2.0 实际标准输出：

```text
取引参照番号=TXN-00000001
取引コード=D
分類=DEPOSIT
処理=ADD_TO_ACCOUNT
```

本工作区语法检查、编译和运行返回码均为 0，输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`，不是 COBOL 程序输出，触发组件尚未定位。

把 `WS-TRANSACTION-CODE` 的初值依次改为 `W`、`T`、`X` 或小写 `d` 后重新编译，可以分别核对三个业务类别与未知代码路径。

## 五、修改练习（有答案）

依次修改 `WS-TRANSACTION-CODE` 的 `VALUE`，编译运行并记录输出：

1. `W`：取款。
2. `T`：转账。
3. `X`：接口未定义的代码。
4. `d`：大小写不同于约定代码的值。

解释为什么 `X` 和 `d` 都进入 `WHEN OTHER`，以及未知代码输出的标签为什么不代表真实系统已完成拒绝。参考输出见 [`answer.md`](./answer.md)。

## 六、举一反三练习（无答案）

为一个批次记录分类支付方式：`C` 现金、`B` 银行转账、`K` 支票；未定义代码输出待人工核对。编写完整固定格式程序，用 `EVALUATE` 映射代码并输出类别和后续处理建议。测试三个已知值、另一个字符和空格，说明接口如何约束代码及大小写。

本练习不提供答案。提交源码、实际编译命令和所有测试输出。

## 七、企业实战补充

批处理的代码映射必须来自稳定、受版本控制的接口约定。上线前核对生产者与消费者对代码、大小写、空值、保留值和新增值的处理方式。为未知值记录批次号、交易号、原始代码和拒绝原因，并让批次结果可重放；本示例只展示分类控制流。

## 参考资料

- [GnuCOBOL Programmer’s Guide：EVALUATE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#EVALUATE)
- [GnuCOBOL Manual：EVALUATE TRUE 与 WHEN OTHER 示例](https://gnucobol.sourceforge.io/doc/gnucobol.html)
