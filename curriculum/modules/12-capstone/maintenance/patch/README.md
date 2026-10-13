# 修正补丁（企业客户区分 1 → 2 位）

本目录记录实际交付的修正。**交付链已包含修正**（可运行参考实现），
故这里不重复贴大段代码，只列出改动与可复现入口：

| 改动 | 文件 | 说明 |
|---|---|---|
| 新接口 | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | 32B 冻结接口（企业布局 v2） |
| 校验/归一化 | `system/cobol/CUSTV2.COB` | 接受 31/32B；v1→v2 升级；BADSTATUS/BADCLASS/BADVERSION |
| 日报宽度守卫 | `system/cobol/NIGHTRPT.COB` | declared layout 与物理宽度一致 |
| 存储 | `system/lib/capdb.py` | customer.table 存 32B |
| 字节守卫 | `system/lib/validate.py` | 企业布局宽度 31/32 |

变更作用于**独立、版本化的企业客户布局**（`CAP-CUSTOMER-FEED` v1/v2），
不是 canonical CUSTOMER v1 的 27 字节；第 27 字节状态语义不动。

修改前基线（RED）：`starter/CUSTV2.COB`（v1-only，遇 v2 RC12）。

RED→GREEN 可复现入口：

```bash
bash curriculum/modules/12-capstone/maintenance/regression/red-green.sh /tmp/m12-rg
```

回滚：见 `maintenance/change-policy.md` 第 4 节。
