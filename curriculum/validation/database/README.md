# P1：真实 Embedded SQL 工具链验证

此目录是工具链技术验证，不是完整模块08。采用GnuCOBOL 3.2、GixSQL固定源码commit与PostgreSQL17；验证平台Linux x86-64。Docker中隔离安装，不修改宿主编译器/数据库，不对外开放端口。

## 运行与复位

在仓库根目录：

```bash
bash curriculum/validation/database/check.sh
```

首次联网构建需数分钟；后续可复用镜像缓存。脚本创建唯一名称的Docker网络和数据库容器，用只读挂载取得源码，在临时工具容器中预编译→cobc编译→运行，再用独立psql会话核对提交。退出时删除本次数据库和网络；工具镜像保留用于重复实验。Ctrl-C也应执行EXIT清理。强制杀进程后按终端显示的 `cobol-p1-*` 名称确认再清理，勿操作其他容器。

数据库只含两条合成账户：`(1,100,NULL)`、`(2,200,'ready')`。只在一次性隔离网络内使用trust认证，不用于实际数据库。没有生产凭据。

## 独立预期

| 操作 | 预期 | 检查方式 |
|---|---|---|
| SELECT NULL + Indicator | 指示器-1 | SINGLE-NULL=YES |
| SELECT不存在的id999 | SQLSTATE02000 | EMPTY=02000 |
| 按id游标读取 | 2条，第一条NULL，第二条非NULL | NULL=YES、ROWS=2及值断言 |
| 再次FETCH | SQLSTATE02000 | EOF=02000 |
| 更新id1到999，然后插入重复id1 | PostgreSQL唯一约束23505 | DUPLICATE=23505 |
| ROLLBACK | id1恢复100 | 再次SELECT断言 |
| 更新id1到101，COMMIT | 独立连接读取101 | psql硬断言，不能仅信DISPLAY |
| 仍打开的游标COMMIT，再次OPEN/FETCH | 正确重开、读到101和NULL | REOPEN=YES |
| 连接隔离网络内的错误端口 | 连接类08 SQLSTATE，程序RC12 | 单独运行fail-connect模式 |

SQLCODE由中间件映射，不照抄DB2的-803作为PostgreSQL实际结果。SQLSTATE保留DB语义。课程RC映射与SQLCODE不是同一层概念。

## 锁定与安装细节

基础镜像、数据库镜像在Dockerfile/check.sh中按digest引用。GixSQL源码固定到 `69e26719ecaca2c31bdf91d7add270b1c0ce2286`。APT依赖尚未冻结为snapshot，因此不是完整的位级可复现构建；验收记录必须保留实测版本，不能仅写镜像标签。

构建使用上游prepdist/prepbuild生成autotools材料；GCC14补入`-include cstdint`以满足源码使用uint64_t的声明。SQL先由gixpp处理，再由cobc链接libgixsql。NULL变量使用该版本要求的 `PIC S9(4) COMP` 和 `:VALUE:INDICATOR`；游标声明END-EXEC带句点。连接明确关闭autocommit，否则PostgreSQL原生游标缺少事务块。

官方说明：[GixSQL源码及用法](https://github.com/mridoni/gixsql)、[PostgreSQL错误码](https://www.postgresql.org/docs/17/errcodes-appendix.html)。这些说明仅用于确定候选，最终兼容性以本目录实际运行结果为准。

## 两个必需的本地修补

当前上游固定commit不能直接通过本探针，构建明确应用两份小补丁，不能把结果描述为未修改上游即可通过。

1. `gixsql-cursor-null.patch`：FETCH取得is_null后未传给COBOL数据转换，指示器错误地为0。传入nullptr/0后才得到-1。
2. `gixsql-closed-cursor.patch`：事务终结前重复CLOSE已经关闭的游标，导致PostgreSQL事务中止；随后COMMIT可能正常返回但实际回滚。只关闭打开状态的游标，并更新逻辑状态。

第二个故障由独立psql检查发现：程序打印COMMIT=101，但外部读到100。保留此案例作为模块11事故设计素材，不能将打印“成功”当作业务证据。补丁适配仅通过本探针，不宣称中间件全部功能已验证；P4须扩充数据库断线、并发和幂等验证。

上游文件受[GixSQL许可证](https://github.com/mridoni/gixsql/blob/main/LICENSE)约束；补丁保留同一上游许可证条件，仓库不内置第三方完整源码。

## 其他候选与已知限制

[Open-COBOL-ESQL复现包](../rejected-ocesql/README.md)保留失败路线，不作为课程默认工具。尚未验证macOS/WSL/ARM、真实网络断线、提交后恢复、幂等记账和全JOB；这些是后续模块08/10的制作门禁。

本机GnuCOBOL运行时有libxml编译/运行版本提示（212/209）；未屏蔽该提示，字节与SQL断言仍实际执行。后续发布需要用干净环境复核依赖一致性。
