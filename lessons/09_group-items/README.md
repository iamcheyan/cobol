# 第 09 课：Group Item 层级数据项

> 状态：课程草稿。目录已确认；示例源码 100 行固定格式，适用于 GnuCOBOL 默认方言。

## 一、课程目标

学完本课后，你可以：

- 区分由子项组成的 group item 与带 `PIC` 的 elementary item。
- 读懂 `01`、`05`、`10` 层级如何表示记录、子组和字段。
- 将客户、账户和交易字段组织在同一交易记录下。
- 用 `OF` 限定父组，引用名称重复的字段。
- 解释整组 `DISPLAY` 和金额字段单独 `DISPLAY` 的不同结果。

## 二、层级结构

程序把一笔交易记录组织成三个并列子组：

```text
01 WS-TRANSACTION-RECORD
   05 WS-CUSTOMER-INFO
      10 WS-CUSTOMER-ID
      10 WS-CUSTOMER-NAME
   05 WS-ACCOUNT-INFO
      10 WS-ACCOUNT-NUMBER
      10 WS-STATUS
   05 WS-TXN-INFO
      10 WS-TXN-ID
      10 WS-TXN-CODE
      10 WS-TXN-AMOUNT
      10 WS-STATUS
```

`01` 是记录层；每个 `05` 是它的子组；每个 `10` 是最近一个较低层级 `05` 的子项。这里同层兄弟使用相同层级号，子层级号必须大于父项。COBOL 用层级号建立父子关系，源码缩进只帮助人阅读。

组项由其他数据项组成；基本项（elementary item）不再包含子项，并为自身定义 `PIC`。组名表达字段的业务归属，例如 `WS-STATUS OF WS-ACCOUNT-INFO` 与 `WS-STATUS OF WS-TXN-INFO` 指向不同字段。`OF` 和 `IN` 都可用于限定名称，本例使用 `OF`。

## 三、完整示例说明

[`lesson.cob`](./lesson.cob) 用固定 `VALUE` 定义一笔客户交易记录，没有文件、终端输入、表格或重定义。客户号和账户号使用文本字段保存；金额使用 `PIC 9(5)V99`，单独引用时按数值格式显示为 `00125.50`。

代码按组分别显示客户、账户和交易字段。两项同名的 `WS-STATUS` 都通过各自父组限定。最后一行把整个 `WS-TRANSACTION-RECORD` 作为组项显示：子项按声明顺序连续出现，没有自动插入分隔符。该输出只是观察内存中组内容的演示，不是本课程定义的文件格式或跨平台接口。

金额字段单独显示为 `00125.50`；整组显示中的相应字符为 `0012550`。`V` 指定数值小数位，但不是组内的字符分隔符。使用组内容当外部记录前，必须另行定义并验证确切布局、编码、符号和平台约定。

## 四、编译、运行和预期输出

在本目录运行以下命令。编译产物写入临时目录并在退出时清理：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_09" lesson.cob
"$scratch_dir/lesson_09"
```

GnuCOBOL 3.2.0 的程序标准输出：

```text
顧客ID=C0001042
顧客名=ADA LOVELACE
口座番号=0001234567
口座状態=A
取引ID=TXN-00000001
取引コード=D
取引金額=00125.50
取引状態=PENDING
グループデータ=[C0001042ADA LOVELACE0001234567ATXN-00000001D0012550PENDING]
```

当前工作区语法检查、编译和运行均返回 0，标准输出与上面一致。运行时标准错误另有系统警告 `Warning: program compiled against libxml 212 using older 209`；它不是 COBOL 程序输出。

## 五、分步阅读

1. 从 `01 WS-TRANSACTION-RECORD.` 找到完整逻辑记录的根组。
2. 查看三个 `05` 项：客户、账户、交易字段分别归在不同子组。
3. 逐项读取 `10` 基本项及其 `PIC`。例如，账户号是十字符文本；金额是带两位隐含小数的数字。
4. 追踪两个 `10 WS-STATUS`：由于名称相同，显示时用 `OF WS-ACCOUNT-INFO` 或 `OF WS-TXN-INFO` 选定具体字段。
5. 比较独立金额输出与最后的组输出。组输出按存储顺序连接子项，不添加字段分隔符；数值字段中的 `V` 也不会变成一个字符。
6. 区分数据组织与业务校验：层级关系说明字段属于哪里，但不会自动验证账户状态、金额范围或交易代码。

## 六、修改练习（有答案）

1. 把 `WS-ACCOUNT-NUMBER` 的初值从 `0001234567` 改为 `0007654321`。重新编译运行，确认独立账户号和整组输出中的对应位置都变化。
2. 把交易子组中的 `WS-STATUS` 改名为 `WS-TXN-STATUS`，并更新显示语句。确认账户状态仍为 `A`、交易状态仍为 `PENDING`，整组字符内容不因数据名变化而改变。

参考答案只覆盖以上修改练习，见 [`answer.md`](./answer.md)；练习说明也在 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

为一条付款指令设计一个 `01` 记录，至少包含付款人子组、收款人子组和付款信息子组。每组设计若干基本项，至少在两个子组中使用相同的基本项名，并用 `OF` 分别显示。编译运行，比较单个字段和整组显示，解释组内字段顺序和填充如何影响结果。

本题不提供答案。只使用本课的层级数据项与固定 `VALUE`；不要添加 `REDEFINES`、`OCCURS`、文件输入或数据库。

## 八、企业实战补充

银行交易记录通常组合客户、账户、金额和状态等字段。明确的组层级可帮助团队审查数据归属、维护记录定义，并为后续 Copybook 和文件课程建立基础。组项本身不会验证内容；字段编码、宽度、顺序、填充、货币规则与外部接口契约都必须单独约定并测试。

## 参考资料

- [GnuCOBOL Programmer’s Guide：Structured Data](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Structured-Data)
- [GnuCOBOL Programmer’s Guide：Data Definition Principles](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Data-Definition-Principles)
