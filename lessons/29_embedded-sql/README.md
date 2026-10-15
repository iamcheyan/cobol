# 第 29 课：Embedded SQL——连接真实数据库并读取账户

到这一课为止，数据都来自文件。真实对账要把账户快照放在关系数据库里，由批处理程序自己连接、查询并区分“查到”“查不到”和“SQL 出错”。本课用 GixSQL 预编译 `EXEC SQL`、连接本机 SQLite 文件数据库，用 COBOL 字段做宿主变量取出一个账户的余额，并按 SQLCODE 分流。

## 为什么现在学

第 15–22 课你已经能从定长/CSV 文件读到记录并匹配，第 23–28 课把代码拆成了可构建的模块工程，但数据源一直是文本文件。缺口是“数据库”：连接串从哪里来、`EXEC SQL` 由谁翻译、查询结果怎么放进 COBOL 字段、查不到行和 SQL 失败怎么区分。本课先把这条链路跑通（单行 `SELECT ... INTO`），第 30 课再换成游标逐行读取。

## 本课完成后的能力与边界

学完本课后，你可以：

- 说明 GnuCOBOL 编译器与负责转换 `EXEC SQL` 的**预编译器**是两件事。
- 从环境变量读取 SQLite 连接串并 `CONNECT`，成功后 `CONNECT RESET` 断开。
- 用 COBOL 字段做 SQL 宿主变量（`:字段名`），执行 `SELECT ... INTO` 主键查询。
- 用 `SQLCODE` 区分查到一行（`0`）、没有匹配行（`100`）和 SQL 错误（其他值），并让错误以非零退出码结束。
- 用 `expected-output.txt` 核对四条标准输出，并说明为什么连接信息不写在源码里。

边界：本课只做单行主键查询，不循环、不写库、不做事务；游标在第 30 课，文件与数据库的对比同步在第 31 课。示例数据库是本机 SQLite 文件（真实 SQL 引擎、真实文件），**不代表** Oracle/PostgreSQL/DB2 的行为。工具链只在本工作区的 x86-64 Linux + GixSQL v1.0.20b 上验证过。

## 运行环境

- GnuCOBOL 3.2.x（`cobc`）+ `sqlite3` 命令行程序。
- **预编译器与运行库**：[GixSQL](https://github.com/mridoni/gixsql) `v1.0.20b`（Ubuntu 22.04 包）及其 `libfmt8` 运行时。`./install-toolchain.sh` 从官方 Release 与 Ubuntu 镜像下载两个 `.deb`、校验固定 SHA-256 后解包到 `build/toolchain/`，**不改动系统软件包**；仓库不提交这些二进制。
- 还需 `curl`、`dpkg-deb`、`sha256sum`（安装脚本会用）。
- 非 x86-64 Linux 或想用别的 GixSQL 版本时，自行安装兼容版本并把 `GIXSQL_ROOT` 指向其 `usr` 目录。
- 构建目录是课内 `build/`（`BUILD_DIR` 可覆盖），已被仓库忽略。

## 工具链：为什么需要预编译器

GnuCOBOL 本身不解析 `EXEC SQL`。本课的链路是：

```text
lesson.cob --(gixpp -e)--> 预处理 COBOL --(cobc -fstatic-call -lgixsql)--> 可执行文件
                                              ↑
                                    运行期由 LD_LIBRARY_PATH 找到 libgixsql 与 SQLite 驱动
```

`build.sh check` 只跑到预编译 + `cobc -fsyntax-only`（不产出可执行文件）；`build.sh build` 才链接出可执行文件；`build.sh run` 会先重建数据库再运行。**没有工具链时不要用模拟 SQL 顶替**——那会把“没有验证过”写成“已经实现”。

## 构建和运行

```sh
./install-toolchain.sh    # 只需一次：下载并解包 GixSQL（写入 build/toolchain/）
./build.sh check          # 预编译 + 语法检查
./build.sh build          # 预编译 + 编译 + 链接
./build.sh run            # 重建 build/accounts.db 并运行
echo $?                   # 查看退出码
./build.sh clean          # 删除 build/（含工具链、预编译文件与数据库）与预编译器日志 gixsql.log
```

`run` 用 [`schema.sql`](./schema.sql) 新建 `build/accounts.db`，因此每次运行都从干净数据开始：表 `ACCOUNT_SNAPSHOT` 有 2 行，`A000000001` 余额 `1250.75`、`A000000002` 余额 `875.00`。

**预期结果：**

| 观察项 | 预期值 |
|---|---|
| `./build.sh check` 退出码 | `0` |
| `./build.sh build` 退出码 | `0` |
| `./build.sh run` 退出码 | `0` |
| 标准输出 | 4 行，与 [`expected-output.txt`](./expected-output.txt) 逐行一致 |
| 生成物 | `build/accounts.db`、`build/lesson_29.cbsql`、`build/lesson_29`，以及工具链日志 `gixsql.log`（GixSQL 预编译器写在源文件旁、运行库追加到进程工作目录；已被 `.gitignore` 覆盖） |

```text
接続=成功
検索=A000000001 状態=FOUND 顧客=C0001001 BALANCE=01250.75
検索=A99999999X 状態=NOT_FOUND
切断=成功
```

**输出对照（实际标签 → 含义）：** `接続=成功` = 连接成功；`検索=` = 查询键；`状態=FOUND` / `状態=NOT_FOUND` = 查到 / 未查到（`NOT_FOUND` 来自 SQLCODE `100`）；`顧客` = 客户号；`BALANCE` = 余额；`切断=成功` = 断开成功。

**实际观察到的环境细节：** 在本工作区运行可执行文件时，标准错误会输出 `Warning: program compiled against libxml 212 using older 209`。这是运行环境的链接库版本警告，不是本程序的标准输出；其触发组件尚未定位。

## SQL 与 COBOL 的接口

### 1. 连接信息来自环境

`WS-DATASRC`、`WS-DBUSER`、`WS-DBPASS` 是 COBOL 字段。程序用 `DISPLAY ... UPON ENVIRONMENT-NAME` 选择变量名、再用 `ACCEPT ... FROM ENVIRONMENT-VALUE` 读取值，然后执行 `CONNECT`。所以源码和夹具里**不保存**机器专属路径或口令；`build.sh run` 通过 `DATASRC=sqlite://<绝对路径>` 等环境变量注入。生产部署也应由环境或密钥管理提供这些值。

### 2. 宿主变量与单行查询

SQL 中以冒号开头的字段是宿主变量（如 `:WS-LOOKUP-ACCOUNT`），GixSQL 会把它们转成 SQLite 参数：

```cobol
           EXEC SQL
               SELECT ACCOUNT_NO, CUSTOMER_ID, BALANCE
                 INTO :WS-ACCOUNT, :WS-CUSTOMER, :WS-BALANCE
                 FROM ACCOUNT_SNAPSHOT
                WHERE ACCOUNT_NO = :WS-LOOKUP-ACCOUNT
           END-EXEC
```

账户号在表与 COBOL 中都是 10 字符、客户号都是 8 字符。固定长度 `PIC X` 会保留字段宽度，宿主变量宽度必须与数据库字段和实际取值约定一致；余额 `PIC 9(7)V99` 接到 `1250.75` 后显示为 `01250.75`。

### 3. SQLCODE：三种结果必须分开

| `SQLCODE` | 含义 | 本课行为 | 退出码影响 |
|---:|---|---|---|
| `0` | 查询成功，返回一行 | 显示 `状態=FOUND` 与客户号、余额 | 无 |
| `100` | 没有匹配行 | 显示 `状態=NOT_FOUND`（**不是错误**） | 无 |
| 其他 | SQL 错误 | 显示 `状態=エラー SQLSTATE=` 并置失败标志 | `1` |

`SQLCODE = 100` 是正常业务结果；把它当故障会让“查不到账户”这种日常情况中止批次。反过来，把 SQL 错误当成“查不到”会掩盖真正的数据库问题——所以本课用 `EVALUATE SQLCODE` 把两者分开。

### 4. 收尾

连接成功后，`9000-DISCONNECT-DATABASE` 执行 `CONNECT RESET` 并检查 SQLCODE；任何失败都会让主流程以状态 `1` 结束，便于 shell 作业发现。

## 修改练习

两项都从原始 `lesson.cob` 开始，每次改完用 `./build.sh run` 重跑（脚本会重建数据库，避免上次结果污染）：

1. 把第一次查询的账号从 `A000000001` 改成 `A000000002`，核对客户号与余额（应为 `C0001002` / `875.00`），说明 `SELECT ... INTO` 如何把数据库列放进 COBOL 字段。
2. 从原始源码开始，把第二次查询的账号从 `A99999999X` 改成 `A000000002`，比较两次查询的 SQLCODE 分支与输出。

完整题目与预期见 [`exercise.md`](./exercise.md)，参考答案见 [`answer.md`](./answer.md)。

## 举一反三练习

在表里增加开户日期和账户状态，用宿主变量查询一个活动账户；把“账户不存在”和“数据库结构错误”分别变成业务结果与系统错误，并说明为什么数据库路径与认证信息应由部署环境提供。本题不提供答案。

## 在企业中的位置

数据库批处理的契约不只是 SQL 写法：连接信息的来源、没有匹配行与 SQL 错误的区分、宿主变量宽度与列类型的一致，都要在接口层面约定。本课把这些都在真实 SQLite 上跑通了一遍。

但它只证明“本机 SQLite + GixSQL v1.0.20b 下这条链路可用”。跨数据库方言、事务边界、SQL 失败后的部分写入与重跑策略都不在本课范围：游标见第 30 课，文件与数据库的快照对比和失败残留见第 31、32 课。

## 参考资料

- [GnuCOBOL FAQ：SQL 数据库接口](https://gnucobol.sourceforge.io/faq/master.html#does-gnucobol-support-any-sql-databases)
- [GixSQL README：Embedded SQL、宿主变量与 SQLite 连接](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GixSQL GnuCOBOL/SQLite 样例](https://github.com/mridoni/gixsql/blob/main/gixsql-tests-nunit/data/TSQL037A-SQLITE.cbl)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
- 仓库课程主页：[README.md](../../README.md)
