# 第 08 课：综合练习——迷你账户交易批次

> 状态：课程草稿。目录已确认；示例源码 154 行，采用 COBOL 固定格式，适用于 GnuCOBOL 默认方言。

## 一、课程目标

学完本课后，你可以：

- 将 `WORKING-STORAGE` 字段用于余额、交易和批次计数。
- 用 `PERFORM VARYING` 依序处理固定样例，并说明循环的起止边界。
- 用 `EVALUATE` 按交易码选择业务路径。
- 用嵌套 `IF` 验证正金额和可用余额。
- 将初始化、样例装载、交易处理和汇总组织成可调用段落。
- 追踪每笔交易对共享余额和批次计数的影响。

## 二、批次规则

程序从 `1000.00` 开始，按样例编号处理五笔固定交易：

| 编号 | 代码 | 金额 | 处理规则 | 余额变化 |
|---|---|---:|---|---:|
| 001 | `D` | 125.50 | 正数存款，接受 | 1000.00 → 1125.50 |
| 002 | `W` | 40.10 | 正数取款且余额足够，接受 | 1125.50 → 1085.40 |
| 003 | `W` | 1500.00 | 金额大于当前余额，拒绝 | 不变 |
| 004 | `D` | -5.00 | 存款金额不是正数，拒绝 | 不变 |
| 005 | `X` | 25.00 | 未知代码，拒绝 | 不变 |

这是用于学习控制流程的批次。样例数据直接写在 `2100-LOAD-SAMPLE` 中；程序不读终端、文件或数据库，也不实现生产账务所需的持久化、审计、并发或重启规则。

## 三、数据和过程结构

[`lesson.cob`](./lesson.cob) 用独立字段保存期初余额、当前余额、交易码、带独立符号的金额、样例序号以及三种计数。金额采用两个小数位；示例的存储和计算遵循 GnuCOBOL 当前平台行为。

| 段落 | 职责 | 关键语句 |
|---|---|---|
| `0000-MAIN` | 按顺序调用初始化、批次处理和汇总 | `PERFORM`、`STOP RUN` |
| `1000-INITIALIZE` | 设置当前余额并清零计数 | `MOVE` |
| `2000-PROCESS-BATCH` | 从 1 循环到最后一个样例，装载并处理每笔交易 | `PERFORM VARYING`、段落 `PERFORM` |
| `2100-LOAD-SAMPLE` | 将序号映射为交易码和金额 | `EVALUATE`、`MOVE` |
| `2200-CLASSIFY-AND-POST` | 按代码验证交易并更新余额或拒绝计数 | `EVALUATE`、嵌套 `IF`、`COMPUTE` |
| `9000-REPORT` | 输出处理数、结果数和最终余额 | `DISPLAY` |

段落仍共享同一组 `WORKING-STORAGE` 字段。处理每一笔交易时，外层循环先调用装载段落，再调用分类处理段落，最后增加已处理计数。被 `PERFORM` 调用的段落结束后，控制返回调用位置，因此循环会继续下一笔。

## 四、逐笔处理逻辑

1. 主段落先执行 `1000-INITIALIZE`：当前余额设为期初余额，所有计数设为零。
2. `PERFORM VARYING` 将序号从 1 递增到 5。上界比较是 `WS-SAMPLE-INDEX > WS-LAST-SAMPLE`，所以序号 5 也会处理。
3. `2100-LOAD-SAMPLE` 用 `EVALUATE` 装入该序号的代码和金额，并打印记录。`WHEN OTHER` 提供序号范围以外的默认值。
4. `2200-CLASSIFY-AND-POST` 先按代码选择存款、取款或未知代码路径。
5. 存款只有金额大于零才加到余额并增加接受数；其他金额增加拒绝数。
6. 取款先检查金额大于零，再检查金额小于或等于当前余额。两个条件都满足才扣款；金额恰好等于余额时允许取款，余额变为零。
7. 未知代码增加拒绝数。每笔完成后，外层循环恰好增加一次处理数。
8. 循环结束后，主段落调用汇总段落。五笔中两笔接受、三笔拒绝，最终余额为 `1085.40`。

交易处理次序是业务规则的一部分：每笔已接受的交易都会影响后续取款可用余额。拒绝路径不修改余额。

## 五、编译、运行和预期输出

在本目录运行以下命令。二进制写入临时目录，退出时自动清理：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_08" lesson.cob
"$scratch_dir/lesson_08"
```

程序的标准输出：

```text
バッチ=START
期首残高=0001000.00
レコード=001 符号=D 金額=+00125.50
結果=ACCEPTED 理由=DEPOSIT
レコード=002 符号=W 金額=+00040.10
結果=ACCEPTED 理由=WITHDRAWAL
レコード=003 符号=W 金額=+01500.00
結果=REJECTED 理由=INSUFFICIENT_FUNDS
レコード=004 符号=D 金額=-00005.00
結果=REJECTED 理由=AMOUNT_NOT_POSITIVE
レコード=005 符号=X 金額=+00025.00
結果=REJECTED 理由=UNKNOWN_TRANSACTION_CODE
処理件数=005
承認件数=002
拒否件数=003
最終残高=0001085.40
```

语法检查、编译和运行均已执行成功，标准输出与上面一致。当前环境运行时在标准错误中还会出现系统警告：`Warning: program compiled against libxml 212 using older 209`；该警告不是课程程序的标准输出。

金额的前导零和正负号来自字段 `PIC` 与 `SIGN IS LEADING SEPARATE CHARACTER` 的显示格式。`V` 表示隐含的小数点位置；字段的实际显示宽度和符号由定义共同决定。

## 六、修改练习（有答案）

1. 把 `WS-OPENING-BALANCE` 的初值从 `1000.00` 改成 `2000.00`。编译运行，确认接受数、拒绝数和新余额。
2. 将样例 003 的取款额从 `1500.00` 改为 `1085.40`。确认余额恰好足够时程序选择哪条路径，并检查最终余额和两个结果计数。

答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)。练习操作也列在 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

扩展批次，使它能处理第六笔固定交易。为第六笔选择交易码和金额，说明它应接受还是拒绝，并给出每笔处理后的余额、最终计数和余额。至少验证一次“金额恰好等于余额”的取款边界；确保 `PROCESSED` 只按实际处理的交易数增加。编译运行并提交修改后的完整固定格式源码及实际输出。

本题不提供答案。仍使用固定样例，不引入文件、表格或数据库。

## 八、企业实战补充

企业批处理常按序处理客户交易；先前已接受的交易会影响之后的可用余额。生产系统需要明确正数金额、账户状态、货币精度、限额、拒绝码、审计记录、重复输入处理、并发更新和失败重启策略。教学示例只展示内存中的顺序规则；不能把它当成已经验证的账务系统。

## 参考资料

- [GnuCOBOL Programmer’s Guide：PROCEDURE DIVISION Sections and Paragraphs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-Sections-and-Paragraphs)
- [GnuCOBOL Programmer’s Guide：Procedural PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Procedural-PERFORM)
- [GnuCOBOL Programmer’s Guide：EVALUATE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#EVALUATE)
