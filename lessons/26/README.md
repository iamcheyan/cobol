# 第 26 课：错误处理——业务拒绝与系统故障

> 状态：课程草稿。目录已确认；主程序 198 行固定格式。面向 GnuCOBOL 3.2.0 和 Linux。

## 一、课程目标

学完本课后，你可以：

- 用 `FILE STATUS` 检查文件打开、读取、写入和关闭结果。
- 区分 EOF（状态 `10`）、坏业务记录和文件 I/O 故障。
- 把坏记录写入拒绝文件并继续处理后续记录。
- 在文件系统错误时停止处理，关闭已成功打开的文件，并返回非零状态。
- 解释为什么 `AT END` 不能替代 READ 后的文件状态检查。

## 二、输入与输出

[`lesson.cob`](./lesson.cob) 从 [`transactions.txt`](./transactions.txt) 读取逐行记录。记录格式为六字符账户号、竖线分隔符、五位金额分；例如 `A00001|00125` 表示 125 个金额单位。金额必须为数字且不能为零，记录总宽度必须为 12。

成功记录写到 `accepted.txt`；宽度、分隔符或金额错误写到 `rejected.txt`。这两个输出都以 `OPEN OUTPUT` 打开，每次运行会覆盖已有内容。请在临时目录运行。

夹具含两条有效记录和三条业务拒绝：非数字金额、零金额和短记录。坏记录不会令整个批次失败；程序继续处理剩余输入。

## 三、业务拒绝与系统故障

| 情况 | 示例 | 程序行为 | 进程返回码 |
|---|---|---|---:|
| 业务拒绝 | 金额非数字、金额为零、记录宽度错误 | 写入拒绝文件，继续读取 | 0，前提是 I/O 成功 |
| 系统故障 | 输入缺失、输出无法打开、READ/WRITE/CLOSE 状态不是成功或 EOF | 报告文件操作和状态，停止后续处理，关闭已打开文件 | 1 |
| 正常 EOF | READ 状态 `10` | 结束输入循环，正常关闭文件 | 0 |

GnuCOBOL Programmer’s Guide 指出，`AT END` 只处理文件状态 `10`，不会捕获其他非零 READ 状态。因此程序在 READ 后额外接受状态 `00`（成功）和 `10`（EOF）；其他状态设置系统错误。每个 OPEN、WRITE 和 CLOSE 也各自检查对应 `FILE STATUS`。只有成功写入的记录才增加接受/拒绝计数。

状态码由 GnuCOBOL 与操作系统报告。当前 Linux 环境中，缺失输入返回 `35`（文件不存在），输出路径无法打开返回 `37`（权限拒绝）。业务规则不借用这些状态码：它们通过 `REASON=` 和拒绝计数表达。

## 四、编译、运行和预期结果

在本目录运行：

```sh
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o "$scratch_dir/lesson_26" lesson.cob
cp transactions.txt "$scratch_dir/"
(cd "$scratch_dir" && ./lesson_26)
```

标准输出：

```text
受理口座=A00001
拒否口座=A00002 REASON=BAD_AMOUNT
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=002 拒否=003
システムエラー=N
```

`accepted.txt`：

```text
A00001|00125
A00004|00999
```

`rejected.txt`：

```text
A00002|BAD_AMOUNT
A00003|ZERO_AMOUNT
A00005|BAD_WIDTH
```

缺失输入验证：在空临时目录运行程序，GnuCOBOL 3.2.0 输出 `エラー=入力オープン 状態=35`，摘要显示 `システムエラー=Y`，进程返回 1。输出打开验证：先复制输入，再创建目录 `accepted.txt`；运行输出 `エラー=受理出力オープン 状態=37` 并返回 1。拒绝文件无法打开时也返回 1，并关闭已打开的输入和接受文件。

## 五、逐步读代码

1. `FILE-CONTROL` 为输入、接受输出和拒绝输出分别绑定一个两字符状态字段。
2. `1000-OPEN-FILES` 先打开必需输入；只有成功后才创建两个输出。每个成功的 OPEN 都记录在相应标志中。
3. `2100-READ-ONE-RECORD` 在 `AT END` 中标记正常 EOF，并在 READ 后将非 `00`、非 `10` 状态归为系统故障。
4. `3000-VALIDATE-RECORD` 检查实际行宽、分隔符、金额字符和零金额。规则错误写入 `WS-REJECT-REASON`，然后写拒绝记录，不设置系统错误标志。
5. `4000-WRITE-ACCEPTED` 和 `5000-WRITE-REJECTED` 在 WRITE 后检查各自状态；失败时停止后续输入，不把失败写入计数为成功。
6. `8000-CLOSE-FILES` 只关闭已成功打开的文件，并检查每个 CLOSE 的状态。关闭失败也会令最终返回码非零。
7. 主程序在 I/O 均正常时让 `RETURN-CODE` 保持零；任何系统 I/O 错误都设为 1。

## 六、写失败验证边界

程序包含 WRITE 与 CLOSE 状态检查，但当前 GnuCOBOL 3.2.0/Linux 运行环境无法用 `/dev/full` 重现可见的行顺序写错误：即使把接受输出直接指定为 `/dev/full`，运行库在 WRITE 和 CLOSE 后仍报告状态 `00`。因此本课不把该设备描述成成功的写失败测试；课程实际验证了输入缺失和两个输出文件的打开失败。部署环境应使用其文件系统/运行库提供的故障注入手段验证真实写入失败，并确认运行库能把失败反映到文件状态。

## 七、修改练习（有答案）

1. 在输入夹具中将 `A00002|00X50` 改为 `A00002|00150`。重新运行，确认这条记录进入接受文件；业务拒绝数量减一，批次返回码仍为零。
2. 在单独的临时运行目录中创建目录 `accepted.txt`，同时放入原始 `transactions.txt`。运行程序，核对输出打开错误、文件状态、清理流程和进程返回码。

答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；具体步骤见 [`exercise.md`](./exercise.md)。

## 八、举一反三（无答案）

为输入记录添加交易类型字段，并将未知类型视为业务拒绝；再为输出文件设置一个不存在的父目录，比较业务规则错误和文件系统错误在摘要及返回码中的区别。说明若拒绝文件本身写入失败，为什么不能继续把后续记录算作已成功处理。

本题不提供答案。不要将格式错误伪装成 EOF，也不要在输出失败后返回成功状态。

## 九、企业实战补充

批处理必须让调度器区分“输入已读完但含拒绝记录”和“文件 I/O 未完成”。前者可能需要业务复核，后者要求重跑或介入；两者的返回码与审计信息不能混为一谈。本例未实现原子文件交付、重跑幂等性或磁盘故障注入，这些策略应由生产批次契约另行定义。

## 参考资料

- [GnuCOBOL Programmer’s Guide：FILE STATUS 与状态码](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#SELECT)
- [GnuCOBOL Programmer’s Guide：AT END](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#AT-END-_002b-NOT-AT-END)
- [GnuCOBOL Programmer’s Guide：RETURN-CODE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Special-Registers)
- [GnuCOBOL Programmer’s Guide：OPEN、READ、WRITE、CLOSE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#OPEN)
