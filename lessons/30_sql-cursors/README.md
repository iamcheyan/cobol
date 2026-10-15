# 第 30 课：Cursor——逐行读取数据库结果

> 状态：课程草稿。主程序 100 行固定格式源码；已在 GnuCOBOL 3.2.0、GixSQL 1.0.20b 和真实 SQLite 文件数据库上验证多行读取与 EOF。

## 一、课程目标

学完本课后，你可以：

- 声明一个 SQL 游标并通过 `OPEN` 开始查询。
- 重复执行 `FETCH ... INTO`，逐行把结果写入 COBOL 宿主变量。
- 用 SQLCODE 0 处理一行、100 识别结果集末尾，并把其他状态归入错误路径。
- 在正常 EOF、读取错误之后关闭游标，再断开连接。
- 对比有两行和空结果集，确认空结果不是 SQL 故障。

本课使用第 29 课建立的真实 GixSQL/SQLite 工具链。SQLite 文件是真实数据库；游标在 COBOL 中由 GixSQL 管理。本课只读取结果集，不使用 `FOR UPDATE` 或 `WHERE CURRENT OF`。

## 二、复用第 29 课工具链

先完成一次第 29 课工具链安装；若已安装，可直接继续：

```sh
cd ../29
./install-toolchain.sh
cd ../30
./build.sh check
./build.sh build
./build.sh run
```

第 30 课默认从 `../29/build/toolchain/usr/` 读取 GixSQL。自定义安装位置时设置 `GIXSQL_ROOT`，例如：

```sh
GIXSQL_ROOT=/opt/gixsql/usr ./build.sh run
```

需要 `cobc`、`sqlite3`、`gcc` 和第 29 课安装的 GixSQL 预处理器、SQLCA Copybook、运行库及 SQLite 驱动。`build.sh clean` 删除本课生成的数据库、预处理文件和程序，不会删除第 29 课工具链。

## 三、运行与预期结果

```sh
./build.sh run
./build.sh run-empty
```

`run` 会创建 `build/cursor.db`，装入两条账户记录，再运行游标程序。`run-empty` 创建相同结构但不插入行，用于检查当前 GixSQL SQLite 驱动的空结果行为。

正常的两行查询输出：

```text
CONNECT=OK
CURSOR=OPEN
ROW=A000000001 CUSTOMER=C0001001 BALANCE=01250.75
ROW=A000000002 CUSTOMER=C0001002 BALANCE=00875.00
FETCH=EOF SQLCODE=100
CURSOR=CLOSED
ROWS=002
DISCONNECT=OK
```

GixSQL 1.0.20b SQLite 驱动在空表上实际返回一条空白宿主变量记录（SQLCODE 0），下一次 FETCH 才返回 SQLCODE 100。因此 `run-empty` 的输出不是 `ROWS=000`；这是本课所用驱动的已复现边界，不能把空白记录当业务数据。请在将游标用于可能为空的生产查询前，针对目标驱动验证该行为。

## 四、游标生命周期

源码 `ACCOUNT-CURSOR` 声明查询列和排序顺序。主程序按以下顺序执行：

1. `1000-CONNECT-DATABASE` 从 `DATASRC`、`DATASRC_USR` 和 `DATASRC_PWD` 环境变量连接 SQLite。
2. `2000-OPEN-CURSOR` 执行 `OPEN`。成功时才标记游标已打开。
3. `3000-FETCH-ROWS` 循环取行。SQLCODE 为 0 时输出并计数；100 时报告 EOF 并离开循环；其他值设置失败标志并离开循环。
4. `4000-CLOSE-CURSOR` 在 EOF 或 FETCH 错误后关闭已打开游标。
5. `9000-DISCONNECT-DATABASE` 执行 `CONNECT RESET`。任何连接、打开、读取、关闭或断开错误都会令进程返回非零状态。

SQLCA 的 SQLCODE“无数据”值可通过 GixSQL 的 `GIXSQL_NOREC_CODE` 配置。本课运行脚本将其固定为 100。正常两行查询在最后一条记录后收到 100；空表查询的实际驱动行为见上一节，不能据此假设首次 FETCH 必定返回 EOF。

## 五、SQLite 游标边界

GixSQL 的 SQLite 样例提供游标读写示范；其文档说明 SQLite 的可更新游标由驱动模拟，并依赖表上的唯一键。该例程避免引入可更新游标：查询按主键排序，仅执行 `OPEN`、`FETCH`、`CLOSE`。这样，练习关注流式读取生命周期，而不混入 SQLite 的更新游标差异。

游标声明中的 `ORDER BY ACCOUNT_NO` 使输出顺序稳定。删除 `ORDER BY` 后，关系数据库不保证结果顺序，即使 SQLite 当前某次运行看起来相同。

## 六、修改练习（有答案）

1. 把游标查询的排序改为 `ORDER BY ACCOUNT_NO DESC`。确认两行顺序反转，但总行数和 EOF 状态不变。
2. 在游标查询中增加 `WHERE ACCOUNT_NO = 'A000000002'`。确认只输出一个账户，随后仍通过 SQLCODE 100 到达 EOF。

答案只回答这两项修改练习，见 [`answer.md`](./answer.md)；步骤见 [`exercise.md`](./exercise.md)。

## 七、举一反三（无答案）

为账户表增加 `ACCOUNT_STATUS`，只让游标返回活动账户。分别验证零行、一行和多行结果；说明查询错误与 SQLCODE 100 的区别，并确保任何成功打开的游标都能关闭。

本题不提供答案。

## 八、参考资料

- [GixSQL README：游标、宿主变量和 SQLite 驱动](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GixSQL SQLite 游标样例 `TSQL037A-SQLITE.cbl`](https://github.com/mridoni/gixsql/blob/main/examples/TSQL037A-SQLITE.cbl)
- [GixSQL SQLCA Copybook](https://github.com/mridoni/gixsql/blob/main/copy/SQLCA.cpy)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
