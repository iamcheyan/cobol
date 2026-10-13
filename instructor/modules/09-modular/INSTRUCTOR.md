# 模块 09 讲师说明

## 提示阶梯

1. 让学员先画出“主程序 ↔ 三个模块”的调用图，标出每个 `CALL` 传的是什么接口、用哪种
   `BY ...`，以及从哪个字段读回结果。
2. 接口第一段为什么要有长度/版本头：演练用硬编码长度替换 `LENGTH OF`，观察被调用者如何
   在进入业务前就拒绝。
3. 让学员在 `ifaceprobe` 上对比 `STATIC` 与 `INITIAL`，解释为什么 LOGGER 的递增序号是
   “有意状态”，而业务模块不应有跨调用状态。
4. 金额模块只负责“给定方向+金额+余额→新余额或拒绝原因”，账户状态/账户存在性由调用者判定。
   让学员说清责任边界，避免把接口错误当业务拒绝。
5. 若主程序返回的 RC 与预期不符，先看是调用者没检查返回值，还是被调用者返回错；再看
   `run.sh` 是否在发布前用独立模型拦下了错误。

## 根因与触发

| 注入 | 位置 | 预期 |
|---|---|---|
| 版本改 `002` 送 AMTCALC | `6200-APPLY-AMOUNT` | AMTCALC 返回 8 `IFACE-VERSION`，主程序 RC8，无发布 |
| 版本改 `002` 送 CUSTVAL | `2200-ONE-CUSTOMER` | CUSTVAL 返回 8，主程序 RC8，无发布 |
| `MOVE 1 TO AMT-IFACE-LENGTH` | `6200-APPLY-AMOUNT` | AMTCALC 返回 8 `IFACE-LENGTH`，无发布 |
| 静态工作区无初始化 | `ifaceprobe` `STATIC-ACC` | 第 2 次调用残留，返回 `0002` |
| 账户布局版本 `002` / 短记录 / 错误业务日 / 交易逆序 | 账户/交易夹具 | 主程序 RC8 `CONTRACT-FAIL`，无发布 |
| 全局重复 `transaction_id`（同账户不同序号或跨账户） | 交易夹具 `dup-global-txid`/`dup-cross-account` | JOB 外排唯一性校验 RC8 `duplicate global transaction_id`，无发布 |
| 冻结/关闭账户、0 金额、透支、溢出、未知方向、无账户 | 业务夹具 | RC4，逐笔原因，仍发布 |

`check.py` 的 `check_starter_and_faults` 会自动做前三条注入，断言 RC8 且无发布目录。

## 关键审查点

- 被调用者只通过接口与 `RETURN-CODE` 回传，不读写调用者私有区；`RETURN-CODE` 每次 CALL 后
  立即检查，8/12 不得降级为业务拒绝。
- 调用者必须用 `LENGTH OF` 填接口长度；硬编码魔数只能出现在故障实验里。
- 发布前必须有独立于 COBOL 的模型核对（本课为 `oracle.py`/`verify-publish.py`）；仅靠程序
  自身 stdout 不构成验收。
- `transaction_id` 必须做**全局**唯一性校验（同账户不同序号、跨账户重复都致命 RC8），
  且使用有界内存的外排（`cut|sort|uniq -d`，JOB 级），不得用全量数组替代被教的顺序突合；
  该校验不能被学员 `COURSE_SOURCE` 绕过。
- 状态泄露要能复现并有 `IS INITIAL`/显式初始化修复；业务模块应无跨调用业务状态。

## 评分量表（100 分）

| 项目 | 分值 | 满分证据 |
|---|---:|---|
| 接口规格与版本/长度校验 | 20 | 接口 Copybook、`LENGTH OF` 填充、长度/版本不匹配 RC8 且无发布 |
| CALL 语义正确使用 | 20 | `BY REFERENCE`/`BY CONTENT`/`BY VALUE`/`RETURNING`/`GOBACK` 各有实测证据 |
| 工作区生命周期 | 15 | 静态残留与 `IS INITIAL` 对比实验，及业务模块无隐式共享状态 |
| 业务正确性与守恒 | 25 | normal/boundary 逐字节报告、逐户与全局计数/金额守恒 |
| 失败传播与独立验收 | 20 | RC0/4/8/12 传回准确、失败不发布、独立模型逐字节拦截 |

关键缺陷（对应项最高记 0）：失败仍发布；把 8/12 当业务拒绝；被调用者改写调用者私有区；
硬编码接口长度/版本冒充契约；状态泄露无法复现或无法修复；expected 由程序输出回抄。

## 最小修复提示与常见误区

最小里程碑：先让主程序把接口头（长度/版本）填对并调用 AMTCALC 得到 RC；再接入 CUSTVAL 与
LOGGER；最后实现账户 Key Break 与守恒。每个里程碑先跑对应失败用例并保留原始 RC。

常见误区：`RETURNING` 写到被调用者的 `PROCEDURE DIVISION` 上（GnuCOBOL 3.2 未实现，会
非法访存；应 `MOVE ... TO RETURN-CODE` + `GOBACK`）；把 `LOG_FILE` 当必然存在（GnuCOBOL 对
不存在的文件 `OPEN EXTEND` 返回 35，需回退 `OPEN OUTPUT`）；把 `LINE SEQUENTIAL` 当定宽输出
（会裁掉行尾空格）；只对单笔交易测一次就断言“多次调用正确”；把账户“无交易”与“交易全被拒”
混为一谈（口径是账户是否收到过交易）。
