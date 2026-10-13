# 第 31 课：文件与数据库快照同步

> 状态：课程草稿。主程序固定格式源码 214 行；使用第 29 课的真实 GixSQL/SQLite 工具链。

## 一、目标与同步边界

程序读取按账户号升序排列的 27 字符文件快照，逐行按账户主键查询 `ACCOUNT_SNAPSHOT`，比较客户号和金额，并把每个文件键的分类写入 SQLite `RECON_RESULT`：

- `MATCH`：数据库账户存在，客户号和金额都相同。
- `CHANGED`：账户存在，但客户号或金额至少一项不同。
- `FILE_ONLY`：数据库查询以 SQLCODE 100 返回无匹配账户。

所有分类写入结果表；`CHANGED` 和 `FILE_ONLY` 同时写入 `differences.txt`。本练习做单向核对，不修改账户主表，也不扫描数据库中没有出现在文件里的账户。输入排序方便顺序审阅；查找由数据库主键完成。

## 二、运行

需要 Lesson 29 安装的 GixSQL/SQLite 工具链，以及 `cobc`、`sqlite3` 和 `gcc`：

```sh
./build.sh check
./build.sh build
./build.sh run
```

默认工具链路径为 `../29/build/toolchain/usr/`；自定义安装时设置 `GIXSQL_ROOT=/path/to/usr`。`run` 每次创建新的 `build/lesson31.db`，装入 `schema.sql`，再从本课目录读取 `snapshot.txt`。程序覆盖生成的 `differences.txt`。`./build.sh clean` 删除本课构建目录和差异报告。

标准输出：

```text
CONNECT=OK
MATCH ACCOUNT=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
SUMMARY ROWS=003 MATCH=001 CHANGED=001 FILE_ONLY=001
DISCONNECT=OK
```

`differences.txt`：

```text
CHANGED ACCOUNT=A000000002 CUSTOMER=C0001002 BALANCE=00100.00
FILE_ONLY ACCOUNT=A000000003 CUSTOMER=C0001003 BALANCE=00025.00
```

## 三、输入契约

每行固定 27 个字符：10 字符账户号、8 字符客户号、9 位金额分。金额使用隐含小数点，`000001000` 表示 10.00。金额字段必须是数字；非数字值使批次以状态 1 失败。账户号在输入中应唯一，数据库以 `ACCOUNT_NO` 主键保证最多查到一行。

`schema.sql` 建立两个实际 SQLite 表。`ACCOUNT_SNAPSHOT` 是来源快照；`RECON_RESULT` 保存每个文件键的状态、文件客户号和文件金额。程序对每个输入键插入一条结果；演示数据库每次由 `run` 重建，因此结果表为空。输入键须唯一；重复键会触发主键错误并让批次失败。

## 四、程序流程

1. 打开输入快照和差异输出；记录每次 OPEN 的文件状态。
2. 从环境连接 SQLite；路径由运行脚本传入，不写死到 COBOL 源码。
3. 逐条读取固定宽度记录，拆出业务键和字段，并验证金额为数字。
4. 对每行执行 `SELECT ... INTO`。SQLCODE 0 表示找到账户；100 表示文件侧独有；其他 SQL 状态为系统错误。
5. 比较客户号和压缩十进制金额，归类后写 `RECON_RESULT`；非 `MATCH` 分类同时写入差异文件。
6. 关闭文件、显示处理计数，再断开成功建立的数据库连接。I/O 或 SQL 故障令程序返回状态 1。

## 五、失败与恢复

输入缺失、输出无法创建、坏金额、SQL 查询/写入错误、文件关闭错误和数据库断开错误都会返回非零。`run` 每次重建演示数据库，因此失败后的重试从干净夹具开始。真实批次若需原子性，应另行设计事务边界、提交策略和恢复标记；本练习不声称提供跨文件与数据库的原子提交。

## 六、修改练习（有答案）

1. 把 `snapshot.txt` 的第二行金额改为数据库当前值 `000087500`。该键应从 `CHANGED` 变为 `MATCH`，差异报告只剩文件独有键。
2. 在 `schema.sql` 中加入与 `A000000003` 完全相同的账户。该键应由 `FILE_ONLY` 变为 `MATCH`，差异报告只剩变更键。

参考答案只回答这两项修改练习，见 [`answer.md`](./answer.md)；操作过程见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

为输入加入重复账户键和非数字金额，分别定义业务拒绝与系统故障政策；让程序检测重复键，并确保拒绝数据不会写入 `RECON_RESULT`。再说明如何在有文件和数据库两个资源时设计可恢复的批次提交。

本题不提供答案。

## 参考资料

- [Lesson 20：有序文件归并](../20/README.md)
- [Lesson 26：文件状态与错误处理](../26/README.md)
- [Lesson 29：GixSQL Embedded SQL 和 SQLite 工具链](../29/README.md)
- [GixSQL README](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
