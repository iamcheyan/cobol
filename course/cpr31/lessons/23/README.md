# 第 23 课：COPYBOOK——共享记录定义

> 状态：课程草稿。目录已确认；主示例源码 102 行固定格式，适用于 GnuCOBOL 3.2.0 默认方言。

## 一、课程目标

学完本课后，你可以：

- 把账户和交易记录的字段声明分别保存在 `.CPY` Copybook 中。
- 在 `WORKING-STORAGE SECTION` 用 `COPY` 引入数据声明。
- 通过编译器的 Copybook 搜索路径找到子目录中的声明文件。
- 在两个独立 COBOL 程序中复用相同账户记录布局。
- 解释 Copybook 是编译期源码复用，不会产生运行时调用。
- 修改共享字段后重新编译所有使用它的程序，并检查记录布局是否仍符合业务契约。

## 二、课程文件

- [`lesson_23.cob`](./lesson_23.cob) 使用账户与交易 Copybook，依次演示入账、提款、余额不足、未知类型和账户不存在。
- [`account_report_23.cob`](./account_report_23.cob) 是第二个独立程序，也导入账户 Copybook，证明该定义可以被多个程序使用。
- [`copybooks/ACCOUNT-REC.CPY`](./copybooks/ACCOUNT-REC.CPY) 定义账户号、客户号和余额。
- [`copybooks/TRANSACTION-REC.CPY`](./copybooks/TRANSACTION-REC.CPY) 定义交易账户、类型和金额。

`COPY "ACCOUNT-REC.CPY".` 和 `COPY "TRANSACTION-REC.CPY".` 放在工作存储区中，因此 Copybook 内容也必须是能在该位置出现的 COBOL 数据声明。COPY 语句末尾的句点必需。字段声明由编译器插入当前程序；它不等同于 `CALL`，也不会在程序运行时读取 `.CPY` 文件。

编译器默认从当前目录及配置路径查找 Copybook。本课把文件放在 `copybooks/`，因此编译命令用 `-I copybooks` 指定目录。文件名区分大小写，源码中的名称必须与磁盘路径一致。

## 三、记录布局

| 记录 | 字段 | PIC | 总长度 |
|---|---|---|---:|
| 账户 | 账户号、客户号、余额 | `X(10)` + `X(8)` + `9(7)V99` | 27 字节 |
| 交易 | 账户号、类型、金额 | `X(10)` + `X` + `9(7)V99` | 20 字节 |

`V` 表示隐含小数点，不占存储字节。两份 Copybook 都声明 01 级组项和明确前缀的字段名，避免多个结构被复制进同一程序后产生名称冲突。账户与交易的键和金额仍需遵守第 20–22 课的同一数据契约。

## 四、程序处理步骤

1. 编译器在工作存储区展开两个 `COPY` 语句，建立 `WS-ACCOUNT-RECORD` 与 `WS-TRANSACTION-RECORD`。
2. 主程序先给共享账户记录赋值，再由各测试段落重复填入同一个交易记录。
3. `2000-POST-TRANSACTION` 先比较账户号。不同账户记为 `NO_ACCOUNT`。
4. `2100-VALIDATE-AND-POST` 根据交易类型选择入账、提款或 `BAD_TYPE`；提款转交给 `2200-CHECK-WITHDRAWAL`，余额不足时不改账户余额。
5. `2900-REPORT-TRANSACTION` 更新成功或拒绝计数。最后显示共享账户记录和计数。
6. `account_report_23.cob` 单独编译，重新导入同一个 `ACCOUNT-REC.CPY`，并输出另一条账户记录。

## 五、编译、运行和预期输出

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only -I copybooks lesson_23.cob
cobc -x -Wall -I copybooks -o "$scratch_dir/lesson_23" lesson_23.cob
cobc -fsyntax-only -I copybooks account_report_23.cob
cobc -x -Wall -I copybooks -o "$scratch_dir/account_report_23" account_report_23.cob
"$scratch_dir/lesson_23"
"$scratch_dir/account_report_23"
```

`lesson_23` 标准输出：

```text
RESULT=POSTED TYPE=D AMOUNT=0000125.50
RESULT=POSTED TYPE=C AMOUNT=0000025.25
RESULT=REJECTED STATUS=INSUFFICIENT
RESULT=REJECTED STATUS=BAD_TYPE
RESULT=REJECTED STATUS=NO_ACCOUNT
ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=0001100.25
SUMMARY POSTED=002 REJECTED=003
```

`account_report_23` 标准输出：

```text
ACCOUNT-REPORT NUMBER=A000000009 CUSTOMER=C0001009 BALANCE=0000020.00
```

两份程序都已用指定 `-I copybooks` 的语法检查、`-Wall` 编译并运行验证。编译时本机可能在标准错误输出 `Warning: program compiled against libxml 212 using older 209`；这不是程序标准输出。

## 六、修改练习（有答案）

1. 从原始源码出发，将 `1100-POST-DEPOSIT` 的交易类型从 `D` 改为 `C`。重新编译运行，检查余额、结果计数和后续提款是否正确。
2. 从原始源码出发，将 `1500-POST-MISSING-ACCOUNT` 中的账户号从 `A000000099` 改成 `A000000001`。重新编译运行，确认该交易能匹配账户并入账。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

把账户 Copybook 的余额字段从数字 PIC 改成显式符号的有符号 PIC，并设计一笔贷记和一笔借记。确认账户程序和报表程序都重新编译，记录变更前后的存储定义与显示结果。说明该改动是否会改变外部固定长文件格式。

本题不提供答案。不只修改一个程序，也不把 Copybook 当作运行时配置文件。

## 八、企业实战补充

账户和交易布局常被文件读写程序、校验程序和报表程序共同使用。把声明抽到 Copybook 可以减少重复定义，但它也形成编译依赖：布局变更后，所有消费者都应重编译，并核对文件长度、字段偏移和上下游版本。本课用两个小程序展示源码复用，不包含自动依赖追踪或版本协商；第 28 课再把 Copybook 纳入可重复构建工程。

## 参考资料

- [GnuCOBOL Programmer’s Guide：Copybooks](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Copybooks)
- [GnuCOBOL Programmer’s Guide：COPY 语法与替换规则](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COPY)
- [GnuCOBOL Manual：`-I` Copybook 搜索路径选项](https://gnucobol.sourceforge.io/doc/gnucobol.html)
