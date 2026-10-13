# db：schema、种子、复位与工具镜像

| 文件 | 作用 |
|---|---|
| `schema.sql` | `schema_version=001` 的 DDL（可重复执行，先 DROP 再 CREATE） |
| `seed.sql` | 合成客户/账户/探针种子（无真实数据、无凭据） |
| `reset.sql` | 清空业务表并保留 schema，用于运行中课程库复位 |
| `Dockerfile` | ESQL 工具镜像（复用 P1 固定 GixSQL commit 与两个本地补丁） |

## 构建与运行

```bash
lab=$(cd curriculum/modules/08-database && pwd)
bash "$lab/scripts/docker-image.sh"       # 生成/复用 cobol-course-gixsql:m08
```

`Dockerfile` 引用 `gixsql-cursor-null.patch` 与 `gixsql-closed-cursor.patch`；这两个
补丁来自 P1 `curriculum/validation/database/`，由 `scripts/docker-image.sh` 复制进临时
构建上下文（**不修改 P1 文件**）。模块08 的 COBOL 与 DB 实验在此镜像内运行。

## 手动对运行中课程库复位

```bash
PGHOST=… PGPORT=5432 PGUSER=postgres psql_dsn bash "$lab/scripts/reset.sh" --db
# 或显式：
psql -v ON_ERROR_STOP=1 -f "$lab/db/schema.sql"
psql -v ON_ERROR_STOP=1 -f "$lab/db/seed.sql"
```

自动化实验使用一次性容器，退出即销毁；此目录的复位脚本只影响显式指定的课程库。
