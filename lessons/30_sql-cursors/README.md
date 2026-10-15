# 第 30 课：Cursor——用游标逐行读取数据库结果集

第 29 课的 `SELECT ... INTO` 一次只取一行账户；真实对账要按账户号顺序扫过整张快照表。本课声明一个游标 `ACCOUNT-CURSOR`，按 `DECLARE → OPEN → FETCH → CLOSE` 的生命周期逐行读出账户，把每行写进 COBOL 宿主变量，并按 `SQLCODE` 区分“取到一行”“结果集结束”和“SQL 出错”。

## 为什么现在学

第 29 课你已经能用 GixSQL 预编译 `EXEC SQL`、连上本机 SQLite，并用宿主变量做一次主键查询。但 `SELECT ... INTO` 的设计就是“一次一行”：命中就填一个值，多行无法逐个取出，取回后也没有“还有没有下一行”的状态。银行对账要处理的是**整张**账户快照，必须能“一次打开、逐行取到末尾为止”。

所以本课补三个缺口：怎样让数据库保留一个正在读取的结果集（游标）、怎样在循环里一行一行地取（`FETCH`）、怎样区分 `SQLCODE` 的 `0`（取到一行）、`100`（到末尾）和其他值（真出错）。第 31 课要拿这份数据库遍历结果与文件侧记录按键对比，本课的出口就是那个可逐行读取的数据库结果集。

## 本课完成后的能力与边界

学完本课后，你可以：

- 用 `EXEC SQL DECLARE ... CURSOR FOR SELECT ... END-EXEC` 声明游标，并说明声明时**不执行**查询。
- 用 `OPEN` 真正发起查询、用 `FETCH ... INTO` 把每行各列写进 COBOL 宿主变量、用 `CLOSE` 释放游标。
- 用 `EVALUATE SQLCODE` 区分 `0`、`100`（结果集结束，正常）和错误值，并让错误以非零退出码结束进程。
- 分别运行两行夹具与空表夹具，核对“多行 + EOF”与“空结果集”两种形态，说明空结果集本身不是 SQL 故障。
- 指出两处容量边界：显示用余额字段只有 5 位整数，行计数只有 3 位（超过 999 行会回卷）。

边界：本课只读结果集，不做 `UPDATE/DELETE ... WHERE CURRENT OF`，不使用 `FOR UPDATE`，不涉及事务、并发与提交/回滚；游标每个进程只打开一次。示例数据库是本机 SQLite 文件（真实 SQL 引擎、真实文件），**不代表** Oracle/PostgreSQL/DB2 的游标行为——“空、单行、多行与 EOF”一节记录的“空表返回一条空白记录”只在本工作区的工具链上复现过。工具链只在本工作区的 x86-64 Linux + GixSQL v1.0.20b 上验证过。

## 运行环境

- GnuCOBOL 3.2.x（`cobc`）、`sqlite3` 命令行程序、`gcc`；源文件为固定格式，不加 `-std=cobol85`。
- **预编译器与运行库**：复用[第 29 课](../29_embedded-sql/README.md)安装的 GixSQL `v1.0.20b` 与 `SQLCA.cpy`，本课不重新安装。
- `build.sh` 默认从 `../29_embedded-sql/build/toolchain/usr` 读取工具链，因此**先要完成第 29 课的 `./install-toolchain.sh`**。工具链装在别处时用 `GIXSQL_ROOT` 覆盖：

  ```sh
  GIXSQL_ROOT=/opt/gixsql/usr ./build.sh run
  ```

- 构建目录是课内 `build/`（`BUILD_DIR` 可覆盖），已被仓库忽略。`build.sh clean` 只删除本课的 `build/` 与预编译器日志 `gixsql.log`，**不会删除第 29 课工具链**；也请勿对第 29 课执行 `clean`。

## 工具链：为什么游标也要预编译

GnuCOBOL 本身不解析 `EXEC SQL`。本课链路与第 29 课相同：

```text
lesson.cob --(gixpp -e)--> 预处理 COBOL --(cobc -fstatic-call -lgixsql)--> 可执行文件
                                              ↑
                                    运行期由 LD_LIBRARY_PATH 找到 libgixsql 与 SQLite 驱动
```

`build.sh check` 只跑到预编译 + `cobc -fsyntax-only`（不产出可执行文件）；`build.sh build` 才链接出可执行文件；`build.sh run` / `run-empty` 会先重建数据库再运行。**没有工具链时不要用模拟 SQL 顶替**——那会把“没有验证过”写成“已经实现”。

## 构建和运行

```sh
./build.sh check       # 预编译 + 语法检查
./build.sh build       # 预编译 + 编译 + 链接
./build.sh run         # 重建 build/cursor.db（两行）并运行
./build.sh run-empty   # 重建 build/cursor.db（空表）并运行
echo $?                # 查看退出码
./build.sh clean       # 删除 build/ 与预编译器日志 gixsql.log
```

`run` 用 [`schema.sql`](./schema.sql) 新建 `build/cursor.db`：表 `ACCOUNT_SNAPSHOT` 有 2 行，`A000000001` 余额 `1250.75`、`A000000002` 余额 `875.00`。`run-empty` 用 [`schema-empty.sql`](./schema-empty.sql) 建同样的表但**不插行**。两者每次都先删库再重建，所以可重复。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `./build.sh check` 退出码 | `0` |
| `./build.sh build` 退出码 | `0` |
| `./build.sh run` 退出码 | `0` |
| `./build.sh run-empty` 退出码 | `0` |
| `run` 标准输出 | 8 行，与 [`expected-output.txt`](./expected-output.txt) 逐行一致 |
| `run-empty` 标准输出 | 8 行，与 [`expected-empty-output.txt`](./expected-empty-output.txt) 逐行一致 |
| 生成物 | `build/cursor.db`、`build/lesson_30.cbsql`、`build/lesson_30`，以及预编译器日志 `gixsql.log`（写在 `lesson.cob` 旁边，已被仓库忽略） |

`run`（两行）的标准输出：

```text
接続=成功
オープン=成功
行=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
行=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
取得=EOF SQLCODE=100
クローズ=成功
行数=002
切断=成功
```

`run-empty`（空表）的标准输出：

```text
接続=成功
オープン=成功
行=           CUSTOMER=         BALANCE=00000.00
取得=EOF SQLCODE=100
クローズ=成功
行数=001
切断=成功
```

**输出对照（实际标签 → 含义）：** `接続=成功` 连接成功；`オープン=成功` 游标打开成功；`行=` 一条记录，后接账户号、`CUSTOMER=` 客户号、`BALANCE=` 余额；`取得=EOF SQLCODE=100` 游标已到结果集末尾；`クローズ=成功` 游标关闭成功；`行数=` 本进程取到的记录计数；`切断=成功` 断开成功。仓库约定程序运行输出沿用日文，本表给出中文含义。

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不在标准输出里，也不影响退出码；触发组件尚未定位。

## 游标生命周期与源码阅读路径

源码见 [`lesson.cob`](./lesson.cob)。关键段落按数据与状态变化顺序排列：

### 1. `DECLARE` 只登记查询，不执行

```cobol
           DECLARE ACCOUNT-CURSOR CURSOR FOR
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 FROM ACCOUNT_SNAPSHOT
                ORDER BY ACCOUNT_NO
```

这条 `DECLARE` 只把查询文本登记给游标；此刻数据库**没有**开始取数，一行也不会读。`ORDER BY ACCOUNT_NO` 让输出顺序稳定；删掉它之后关系数据库不保证行的顺序，即使某次运行看起来相同。

### 2. `OPEN` 才发起查询

`2000-OPEN-CURSOR` 执行 `OPEN ACCOUNT-CURSOR`。只有 `SQLCODE = 0` 时才把 `WS-CURSOR-OPEN` 置为 `"Y"`（源码注释说明了为什么要这样守卫：只有打开成功的游标才允许 `CLOSE`）。`OPEN` 失败会输出 `オープン=エラー SQLSTATE=` 并置失败标志。

### 3. `FETCH` 循环与 `SQLCODE` 的三种结果

`3000-FETCH-ROWS` 用 `PERFORM UNTIL WS-DONE = "Y"` 循环，每轮执行一次 `FETCH ... INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE`，再按 `SQLCODE` 分流：

| `SQLCODE` | 含义 | 本课行为 | 退出码影响 |
|---:|---|---|---|
| `0` | 取到一行 | 计数 +1，显示 `行=...`，继续循环 | 无 |
| `100` | 结果集结束（正常） | 显示 `取得=EOF SQLCODE=100`，置 `WS-DONE` 结束循环 | 无 |
| 其他 | SQL 错误 | 显示 `取得=エラー SQLSTATE=`，同时置 `WS-FAILED` 与 `WS-DONE` | `1` |

`SQLCODE = 100` 是正常业务结果；把它当故障会让“表里没有账户”这种日常情况中止批次。反过来，把 SQL 错误当成“取完了”会掩盖真正的数据库问题——所以本课用 `EVALUATE SQLCODE` 把两者分开。`GIXSQL_NOREC_CODE=100` 在 `build.sh` 的 `run`/`run-empty` 中固定，保证“无数据”判定为 100。

**失败路径（已实测）：** 本课的错误分支不是纸面设计：

| 注入方式 | 实际输出 | 退出码 |
|---|---|---|
| `DATASRC` 指向不存在的目录 | `接続=エラー SQLSTATE=08001`、`行数=000`（连接未建立，故**没有**断开行） | `1` |
| 库里没有 `ACCOUNT_SNAPSHOT` 表 | `接続=成功`、`オープン=エラー SQLSTATE=HY000`、`行数=000`、`切断=成功` | `1` |

第二种情况里，`OPEN` 失败使 `WS-CURSOR-OPEN` 保持 `"N"`，程序跳过 `FETCH`/`CLOSE`（不能关闭未打开的游标），但仍会断开连接；最后 `WS-FAILED` 让进程以 `1` 结束。

### 4. `CLOSE` 与断开

`4000-CLOSE-CURSOR` 在正常 EOF 或 `FETCH` 出错后关闭**已打开**的游标；`9000-DISCONNECT-DATABASE` 执行 `CONNECT RESET`。连接、打开、读取、关闭、断开任一环节失败，都会让进程以状态 `1` 结束（`STOP RUN RETURNING 1`），便于 shell 作业发现。

### 5. 与第 29 课单行 `SELECT ... INTO` 的差别

| 维度 | 第 29 课 `SELECT ... INTO` | 本课游标 |
|---|---|---|
| 取几行 | 一次一行，多行结果会报错 | 打开后逐行取到 100 为止 |
| 发起时机 | 执行 SQL 语句即查询 | `DECLARE` 只登记，`OPEN` 才查询 |
| 结束状态 | `SQLCODE = 100` 表示“无匹配行” | `SQLCODE = 100` 表示“结果集结束” |
| 资源释放 | 无可见游标 | 必须 `CLOSE`，且只关闭成功打开过的游标 |

## 空、单行、多行与 EOF

本课主题是结果集形态与状态分叉，因此对四种形态都做了实际运行。下表是最新一次运行的关键观察（`行=` 行数即取到的记录数）：

| 形态 | 夹具 / 造法 | 关键实际输出 | 实际命令 | 退出码 |
|---|---|---|---|---|
| 多行（2 行） | `schema.sql` | 2 条 `行=`，`取得=EOF SQLCODE=100`，`行数=002` | `./build.sh run` | `0` |
| 空表 | `schema-empty.sql` | **1 条空白** `行=`，`取得=EOF SQLCODE=100`，`行数=001` | `./build.sh run-empty` | `0` |
| 单行 | 查询加 `WHERE ACCOUNT_NO = 'A000000002'` | 1 条 `行=`（`A000000002`），`行数=001` | 见[修改练习](#修改练习) 2 | `0` |
| 多行（3 行） | 临时夹具插 3 行 | 3 条 `行=`，`行数=003` | 手工建房后运行 | `0` |
| 多行（1005 行） | 临时夹具插 1005 行 | 1005 条 `行=`，但 `行数=005` | 手工建房后运行 | `0` |
| EOF | 任意夹具末尾 | `取得=EOF SQLCODE=100`（由 100 触发，不是错误） | 同上 | `0` |

**空表为什么会打印一条空白记录？** 这是本课所用**驱动**的行为，不是数据库里有数据：用 `sqlite3 build/cursor.db "SELECT COUNT(*) FROM ACCOUNT_SNAPSHOT;"` 查空库得到 `0`，所以表里确实没有行；但 GixSQL v1.0.20b 的 SQLite 驱动在 `OPEN` 后第一次 `FETCH` 会返回 `SQLCODE 0`，同时把账户号、客户号填成全空格、余额填成 `0`，要到**下一次** `FETCH` 才返回 `100`。这条空白记录会被当作一行显示并计入 `行数=`，所以 `行数=` 比表里的真实行数多 1（源码注释已标注这一点）。`expected-empty-output.txt` 因此记录的是本工具链下的**实际**输出，而不是 `行数=000`。

**这条边界是否只限于本工具链？** 目前只能确认“在本工作区的 GixSQL v1.0.20b + SQLite 上复现”。未在其他 GixSQL 版本、其他数据库（Oracle/PostgreSQL/DB2）或原生 SQLite C API 上验证，**不能据此推断**首次 `FETCH` 在别的驱动上也一定先给一条空白记录。把游标用于可能为空的生产查询前，必须针对目标驱动单独验证“首次 FETCH 的 SQLCODE”。

## 容量边界（已实测）

源码里有两个比数据范围窄的字段，越界时会静默损失，值得记住：

| 字段 | 声明 | 边界与实测行为 |
|---|---|---|
| `WS-EDITED-BALANCE` | `PIC 9(5).99` | 只有 5 位整数。插入余额 `1234567.89` 后，实际显示 `BALANCE=34567.89`（高位被丢）。`WS-BALANCE` 本身是 `PIC S9(7)V99`，数据能装下，**显示副本**装不下。 |
| `WS-ROW-COUNT` | `PIC 9(3)` | 只有 3 位。插入 1005 行后，仍逐行取完 1005 行，但末尾显示 `行数=005`（低三位）。 |

这两项是**已实现行为**的真实限制，不是错误处理：它们既不报错也不置失败标志。源码在字段声明处用注释标明了这两条约束。

## 修改练习

两项都从本课原始 [`lesson.cob`](./lesson.cob) 开始，各自独立，改完用 `./build.sh run` 重跑（脚本会重建数据库，避免上次结果污染）：

1. 把游标查询的排序改为 `ORDER BY ACCOUNT_NO DESC`。核对两行顺序反转、总行数与 EOF 状态不变。
2. 在 `FROM ACCOUNT_SNAPSHOT` 后增加 `WHERE ACCOUNT_NO = 'A000000002'`。核对只输出一个账户，随后仍由 `SQLCODE 100` 到达 EOF。

完整题目与预期差异见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。两处题目、改动位置与预期结果一致。

## 举一反三练习

为 `ACCOUNT_SNAPSHOT` 增加 `ACCOUNT_STATUS`，只让游标返回活动账户。分别验证零行、一行和多行结果；说明“查询错误”与 `SQLCODE 100` 的区别，并确认任何成功打开的游标都能关闭。本题不提供答案，独立完成范围与验证方法见 [`exercise.md`](./exercise.md)。

## 在企业中的位置

数据库批处理的游标契约不只是 SQL 写法：`DECLARE` 与 `OPEN` 的时机、`FETCH` 循环里 `0/100/错误` 的分叉、只关闭成功打开过的游标、以及驱动特例（如空表空白记录）都必须写进接口约定。第 31 课会用游标/查询遍历数据库一侧，与文件侧记录按键对比，从而做出差异清册；第 32 课的银行对账项目再把这些路径组合成完整批次。

本课只证明“本机 SQLite + GixSQL v1.0.20b 下这条游标链路可用”，并且只读取一次。可更新游标（`FOR UPDATE` / `WHERE CURRENT OF`）、跨数据库方言、事务边界与并发、SQL 失败后的部分写入与重跑策略都不在本课范围。

**证据来源：** 上文所有“实际输出/退出码”均来自本工作区对 `lesson.cob` 的 `./build.sh check`、`build`、`run`、`run-empty` 实测，以及手工构造的单行/3 行/1005 行/超大余额数据库；`SQLCODE 100`、错误分支的 `SQLSTATE`（连接失败 `08001`、表缺失 `HY000`）都是实测值。**未验证项：** `CLOSE` 失败分支（`クローズ=エラー`）与 `FETCH` 中途出错分支未能在本环境稳定注入，代码路径存在但未运行；“空白记录”是否出现在其他驱动上未验证。

## 参考资料

- [GixSQL README：游标、宿主变量与 SQLite 驱动](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GixSQL SQLite 游标样例 `TSQL037A-SQLITE.cbl`](https://github.com/mridoni/gixsql/blob/main/gixsql-tests-nunit/data/TSQL037A-SQLITE.cbl)（原 `examples/` 路径已失效；该样例使用 `FOR UPDATE` 可更新游标，本课刻意不用）
- [GixSQL SQLCA Copybook](https://github.com/mridoni/gixsql/blob/main/copy/SQLCA.cpy)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
- 上一课：[第 29 课 Embedded SQL](../29_embedded-sql/README.md)；下一课：[第 31 课 数据同步](../31_data-synchronization/README.md)
- 仓库课程主页：[README.md](../../README.md)
