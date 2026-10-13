# 模块 04 学员证据模板

- 姓名 / 日期：
- 源文件 SHA256（参考实现或你的 starter）：
- 编译器与 ABI 版本（`cobc -V`，Linux x86-64）：
- 逐 lesson 命令与**原始 RC**：
- 04.1：REDEFINES 父组 `LENGTH OF`（证明不重复计长）、66 RENAMES 长度、
  OCCURS INDEXED BY 取值、ODO 计数 3 与 7 的 `LENGTH OF`：
- 04.2：V1/V2 `LENGTH OF`、加宽字段与其后字段的偏移移动量、reference modification 结果：
- 04.3：1,778B 记录读取、字段定位值、175 字段目录与 `ADDRESS OF` 实测对照（含你的手算）：
- 结构错误（长度/版本/ABI/key）为何 RC8 且零发布：
- 故意破坏（ODO 非末项 / REDEFINES 未紧邻）的 `cobc` 原始错误：
- 加宽 `CUSTOMER-CLASSIFICATION` 的 V1→V2 影响调查：受影响的字段、文件、下游与回滚：
- `bash scripts/check.sh` 的输出：
