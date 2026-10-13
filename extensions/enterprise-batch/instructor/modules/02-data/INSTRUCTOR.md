# 模块 02 讲师说明

## 参考实现与结构

- `CUSTLOAD.COB`：逐字节读取（`PIC X(1)` 直到 `X'0A'`），长度校验基于原始字节；拒绝原因按
  `NAME-MISSING` > `BAD-AMOUNT` > `UNKNOWN-STATUS` 优先级；`BALANCE-TOTAL` 用 18 位无符号
  累加并 `ON SIZE ERROR` 保护。
- 学员入口 `starter/CUSTLOAD.COB` 可编译、返回 RC12、不发布。
- `copybooks/CUSTOMER-V1.CPY` 是 27 字节实物；`experiments/layout/CUSTOMER-V1.CPY` 是刻意
  错写成 `X(11)`（28 字节）的**非契约错误布局对照**，用 `LENGTH-PROBE.COB` 演示偏移移动；
  它不是 CUSTOMER v1 契约，也不是 27→28 迁移。

## 提示阶梯

1. 先让学员说清 `PIC 9(8)` 与 `PIC X(8)` 的“逻辑位数 vs 存储字节”差异。
2. 让学员手算 normal 的 `BALANCE-TOTAL = 12345+50+9999999 = 10012394`。
3. 拒绝优先级：一条记录可能有多个问题，只报最高优先级原因，避免“随机原因”。
4. MOVE 实验：先预测再看 `MOVELAB` 输出；重点 H（高位截断）与 I（隐式小数）。
5. 类型实验：先预测 `TYPESLAB` 输出再看结果；重点 `AB123` 移入 `PIC A` 仍原样保存（判 `M`），
   必须用 `IS ALPHABETIC` 自行校验；数值项 `MOVE` 到 `PIC A` 直接编译失败。
6. 布局实验：改 `PIC X(10)→X(11)` 后重编，观察 `LENGTH OF` 与文件长度校验同时变化。

## 根因与触发

| 夹具/实验 | 根因 | 预期 |
|---|---|---|
| boundary/no-final-lf | 末条缺 LF | RC8 无发布 |
| invalid/short、long | 原始字节长度 ≠27 | RC8 无发布 |
| invalid/crlf | 记录含 CR | RC8 无发布 |
| invalid/bad-id | ID 含非数字 | RC8 无发布 |
| invalid/duplicate-id、unsorted | ID 非严格升序 | RC8 无发布 |
| invalid/name-missing | 名称全空格 | RC4 `NAME-MISSING` |
| invalid/bad-amount | 余额含非数字 | RC4 `BAD-AMOUNT` |
| invalid/unknown-status | 状态非 A/D | RC4 `UNKNOWN-STATUS` |
| MOVELAB H | `MOVE 12345 TO PIC 9(3)` | `345` 高位截断 |
| TYPESLAB `AB123` | `MOVE X(5)` 到 `PIC A(5)` 不校验 | 原样保存，`IS ALPHABETIC` 判假→`M` |
| TYPESLAB 数值→A | 数值项 `MOVE` 到 `PIC A` | 编译失败，无法发布 |
| layout off-by-one | 名称 `X(11)`（非契约错误布局） | 记录 28 字节，偏移后移 |

## 关键审查点

- 长度、字符、排序校验必须基于原始字节；不能先把记录 MOVE 进 27 字节定长字段再判断。
- 拒绝原因优先级必须固定，同一条只产生一个原因。
- `BALANCE-TOTAL` 只累计接收记录；被拒记录的 `balance_demo` 不得进入合计。
- RC8 必须整批失败且不产生输出目录；不得把契约错误降级为逐条拒绝。
- 27 字节契约不得被“美化”成 `PIC 9(8)` 而改变存储/比较语义。
- 12/18 位定宽是刻意保留的接口格式。

## 评分量表（100 分）

| 项目 | 分值 | 满分证据 |
|---|---:|---|
| CUSTOMER v1 字段目录与 Copybook | 20 | 偏移/长度/PIC/单位/合法值完整且与实测长度一致 |
| 装载实现与字节级校验 | 30 | 原始长度/字符/排序校验；RC0/4 正确发布与守恒 |
| 数据表示解释（位数/字节/隐式小数） | 20 | MOVE 实验 A–I 与类型实验逐条给出规则，非复制输出 |
| 布局/偏移影响调查 | 20 | `LENGTH-PROBE` 27 vs 28，说明联动影响，且指明错误布局非契约 |
| 证据与限制说明 | 10 | 命令、原始 RC、校验和、平台限制 |

改变 27 字节契约、失败仍发布、把原始长度当成定长字段长度、把 MOVE 截断当“编译器 bug”，
均属关键缺陷，对应评分项最高记 0。

## 常见误区

把名称当成“字符数=字节数”（多字节实验留待后续）；用 `PIC 9(8)` 存 ID 后前导零丢失；把余额
合计算进被拒记录；把 `VALUE` 当成运行期赋值（它只是初值）；用浮点近似做金额。
