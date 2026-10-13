# 模块 04 讲师参考

- `M04SHAPE.COB`：04.1 REDEFINES / 66 RENAMES / OCCURS INDEXED BY / ODO。
- `M04COPY.COB`：04.2 COPY REPLACING 加宽字段、`LENGTH OF` 偏移、reference modification。
- `M04ENTERPRISE.COB`：04.3 读取 1,778B 企业客户记录并定位字段。
- 只读复用 `instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY`。

## 提示阶梯

1. 先让学生只读 `FIELD-CATALOG.csv` 手算 `CUSTOMER-CLASSIFICATION`（460）与
   `SYNC-STATE`（1778）的 1-based 偏移，再给 Copybook。
2. REDEFINES 用 `LENGTH OF` 父组证明不重复计长，而不是口头说明。
3. ODO 的 `LENGTH OF` 随计数变化是本题关键；“编译期固定长度”的先验假设是常见错误。
4. COPY REPLACING 只替换 `字段名 PIC X(1)` 这一 token 序列，避免误伤其它 `X(1)`。
5. 加宽字段后，用 `ADDRESS OF` 比较被加宽字段与其后末字段的地址，量化 +1 偏移。

## 注意（易错）

- `REDEFINES` 必须紧邻被重定义项；ODO 必须是组内最后一项；否则编译失败。
- 两个 01 组同名必须用 `OF ENT-V1`/`OF ENT-V2` 限定。
- `LENGTH OF` 总长**不能**替代逐字段 `ADDRESS OF` 证据。
- 不要把模块 07 的 Copybook 复制成第二份不同实现；只加宽练习用 COPY REPLACING 临时派生。

## 评分（建议）

- 结构语义（REDEFINES/66/OCCURS/ODO）正确 25%
- COPY REPLACING 与偏移移动说明 25%
- 175 字段目录与 `ADDRESS OF` 实测一致 25%
- 结构错误 RC8 零发布、锁与复位 15%
- V1→V2 影响调查与证据 10%
