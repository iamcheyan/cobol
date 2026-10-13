# fixtures：固定字节夹具

全部为 ASCII 定宽记录 + LF；宽度与校验和见仓库级 `SHA256SUMS`（模块根目录）。

| 文件 | 宽度 | 用途 |
|---|---:|---|
| `customer-upstream-20261009.dat` | 27B | 08.3 有差异上游（C2 余额 260，C9 文件独有） |
| `customer-upstream-20261009-nodiff.dat` | 27B | 08.3 无差异上游（与 DB 快照一致） |
| `transactions-20261009.dat` | 55B | 08.4 正常交易（唯一键，幂等） |
| `transactions-dup-in-run.dat` | 55B | 08.4 运行内重复 transaction_id（触发 23505/RC8） |

字节内容由业务契约定义，可重复生成；`scripts/check.py` 逐条校验宽度与末尾 LF。
DB 端种子/上游差异均由 `db/seed.sql` 独立核算，命令见模块 README 第 4 节。
