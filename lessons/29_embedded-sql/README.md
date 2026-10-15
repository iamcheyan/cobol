# 第 29 课：Embedded SQL——连接数据库并读取账户

> 使用 GnuCOBOL 3.2.0、GixSQL 1.0.20b 和 SQLite 工具链。游标内容见第 30 课。

## 一、课程目标

学完本课后，你可以：

- 区分 GnuCOBOL 编译器与负责转换 `EXEC SQL` 的预编译器。
- 从环境变量读取 SQLite 连接字符串，再通过 `CONNECT` 建立数据库连接。
- 用 COBOL 字段作为 SQL 宿主变量，执行 `SELECT ... INTO`。
- 用 SQLCA 的 `SQLCODE` 区分查到一行（0）、没有匹配行（100）和 SQL 错误（其他状态）。
- 在成功连接后关闭连接，并让数据库错误通过非零进程状态传递给 shell。

本课读取关系数据库中的账户快照。示例数据库为本机 SQLite 文件；它是真实 SQL 引擎和真实文件数据库，不是模拟调用。第 30 课再将单行查询扩展为游标逐行读取。

## 二、工具链与平台

GnuCOBOL 本身不解析 `EXEC SQL`。本课使用 [GixSQL](https://github.com/mridoni/gixsql) 预处理 `EXEC SQL`，再让 `cobc` 编译生成的 COBOL，并链接 GixSQL 运行库。GixSQL 文档列出 SQLite 驱动，连接字符串形式为 `sqlite:///绝对路径`。

当前可复现的 x86-64 Linux 路径固定使用 GixSQL `v1.0.20b` Ubuntu 22.04 包和其 `libfmt8` 运行时。`install-toolchain.sh` 从官方 GixSQL Release 与 Ubuntu 镜像下载两份 `.deb`，校验固定 SHA-256 后解包到 `build/toolchain/`；它不修改系统软件包。这个旧版 GixSQL 包的 dpkg 元数据包含其他数据库驱动依赖，但本课实际使用的是随包提供的 SQLite 驱动。仓库不提交这些二进制包。

需要：

- GnuCOBOL 3.2.x（`cobc`）
- `sqlite3` 命令行程序
- `curl`、`dpkg-deb` 与 `sha256sum`

运行 `./install-toolchain.sh` 后，预编译器和运行库位于 `build/toolchain/usr/`。非 x86-64 Linux 用户需要自行安装兼容版本的 GixSQL，并在命令中设置 `GIXSQL_ROOT` 指向其 `usr` 目录。

## 三、构建和运行

```sh
./install-toolchain.sh
./build.sh check
./build.sh build
./build.sh run
```

`run` 会在 `build/accounts.db` 创建新的 SQLite 文件并加载 [`schema.sql`](./schema.sql)，然后编译并运行 [`lesson.cob`](./lesson.cob)。`build.sh clean` 会删除整个 `build/`，包括下载的工具链、预编译文件和数据库。

标准输出应为：

```text
CONNECT=OK
LOOKUP=A000000001 STATUS=FOUND CUSTOMER=C0001001 BALANCE=01250.75
LOOKUP=A99999999X STATUS=NOT_FOUND
DISCONNECT=OK
```

GnuCOBOL 运行时可能在标准错误输出 libxml 版本警告；它不属于程序标准输出。

## 四、SQL 与 COBOL 的接口

### 1. 宿主变量

`WS-DATASRC`、`WS-DBUSER` 和 `WS-DBPASS` 是 COBOL 字段。GixSQL 把 SQL 中以冒号开头的字段（例如 `:WS-LOOKUP-ACCOUNT`）转换为 SQLite 参数。连接信息从环境读取，因此源码和夹具不保存机器专属路径或口令。

账号字段在样例表与 COBOL 中都为 10 个字符，客户号都为 8 个字符。固定长度 `PIC X` 会保留字段宽度；宿主变量宽度应与数据库字段和实际值的约定相符。

### 2. 单行查询

```cobol
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
```

`SELECT ... INTO` 在本课用于最多一行的主键查询。语句返回后，程序检查 SQLCODE，再决定显示账户、报告无匹配行或设置错误标志。

### 3. SQL 状态

GixSQL 的 [`SQLCA.cpy`](https://github.com/mridoni/gixsql/blob/main/copy/SQLCA.cpy) 提供 `SQLCODE`、`SQLSTATE` 和错误文本字段。本课将 `SQLCODE = 0` 视为成功、`SQLCODE = 100` 视为无数据，其他值按 SQL 错误处理。错误分支会让进程以状态 1 结束，便于 shell 作业发现失败。

## 五、按程序流程阅读源码

1. `WORKING-STORAGE SECTION` 声明连接参数、查询键、查询结果、余额和两个状态标志。`EXEC SQL INCLUDE SQLCA` 引入 GixSQL 的通信区。
2. `MAIN-PROCEDURE` 先调用连接段落；只有连接成功才做两次主键查找，并在末尾断开。
3. `1000-CONNECT-DATABASE` 用 `DISPLAY ... UPON ENVIRONMENT-NAME` 选择变量名，再由 `ACCEPT ... FROM ENVIRONMENT-VALUE` 读取值，之后执行 `CONNECT`。
4. `2000-LOOKUP-ACCOUNT` 绑定查询键和结果字段，按 SQLCODE 分别显示 `FOUND`、`NOT_FOUND` 或错误 SQLSTATE。
5. `9000-DISCONNECT-DATABASE` 执行 `CONNECT RESET`。数据库错误会设置 `WS-FAILED`，主流程据此返回非零状态。

`build.sh` 的核心步骤是：`gixpp -e` 生成预处理 COBOL；`cobc -fstatic-call` 编译并链接 `libgixsql`；运行时通过 `LD_LIBRARY_PATH` 找到 GixSQL 与 SQLite 驱动。

## 六、修改练习（有答案）

1. 将第一次查询的账号改为 `A000000002`。确认结果来自第二条 SQLite 记录，余额显示 `00875.00`。
2. 将第二次查询的账号改为 `A000000002`。确认第二行从 `NOT_FOUND` 变为 `FOUND`。

参考答案只覆盖这两项修改练习，见 [`answer.md`](./answer.md)；操作说明见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

在表中增加开户日期和账户状态。用宿主变量查询一个活动账户，并把不存在账户与数据库结构错误分别转成业务结果和系统错误。说明为什么数据库路径和认证信息应由部署环境提供。

本题不提供答案。

## 八、参考资料

- [GnuCOBOL FAQ：SQL 数据库接口](https://gnucobol.sourceforge.io/faq/master.html#does-gnucobol-support-any-sql-databases)：GnuCOBOL 需配合 SQL 预处理器/接口。
- [GixSQL README：Embedded SQL、宿主变量和 SQLite 连接](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GixSQL GnuCOBOL/SQLite 样例](https://github.com/mridoni/gixsql/blob/main/examples/TSQL037A-SQLITE.cbl)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)：编译器选项与 COBOL 语言参考。
