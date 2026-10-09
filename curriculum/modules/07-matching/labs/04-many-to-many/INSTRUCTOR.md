# 讲师说明与验收标准

## 最小正确实现

学生需做到：

1. 通过 B01 L2 runner 读取原始ACCOUNT/TX/link，并保留 L2 accepted、rejected、master、report；B03不得替代L2做交易入账。
2. 逐字节验证Snapshot36B/Previous39B与Gregorian日期、版本、唯一递增customer key；账户/TX客户归属排序必须保留完整原始47B/55B。
3. 用四个有独立EOF状态的游标选择最小customer key。`<`只推进小键流；`=`消费该客户所有来源一次；EOF流不再READ。
4. 将客户组原始来源逐行写磁盘spool；整个组消费完才判断，不能将所有同客户交易/ID放进数组。
5. 对全部账户状态计数；按L2 accepted C/D核对 `opening + C - D = closing`；Snapshot/Previous差异RC4并隔离关联来源；全局账户、accepted交易、贷借金额分别拆分守恒。
6. 独立验收器从原始输入/L2报告和输出逐流检查宽度、LF、来源字节、客户归属、control值及金额，不得把COBOL的control当作自己的期望值。
7. RC0/4只允许经核验发布；结构错误8、系统/工具/资源错误12不发布。不得覆盖既有目录；任意锁存在时reset拒绝。

## 参考实现讲解顺序

建议先在白板上手动做README中的五行游标trace，再从源码验证每一步的边界：

| 源码段 | 讲解重点 | 快速核查 |
|---|---|---|
| `1100-VALIDATE-SNAPSHOT` / `1200-VALIDATE-PREVIOUS` | 固定原始字节、LF、Gregorian日期、版本和严格递增customer键；先拒绝结构坏流，再进入业务判断 | 直接运行`check-source.py`的短/长/CRLF/Tab/NUL/no-LF用例 |
| `1300-SORT-ACCOUNTS` / `1400-SORT-TRANSACTIONS` | COBOL SD SORT通过`RELEASE/RETURN`把非单调customer来源变成customer有序流；payload保留47B/55B原记录 | normal按account_id读取时account IDs 1,2,3对应customers 2,1,2；customer/account排序后account IDs为2,1,3，对应customers 1,2,2，再查看派生流 |
| `1500-RUN-FOUR-WAY` | 四个EOF标志独立；求当前最小customer，匹配流只推进一次，不匹配的更大游标保持不动 | 手工写A/T/S/P指针表；16种输入EOF组合能发现无效READ |
| `1550-RESET-GROUP` / `1560-CONSUME-*` | spool一个客户的来源；重复账户/交易来自不同流但都按各自业务键唯一消费 | 断点观察spool，确保仅当前客户内容落盘 |
| `1580-DECIDE-GROUP` | 组结束以后再做客户状态、前日opening/count、上限和closing核对；业务差异只设置业务差异状态，不能逐组累加RC4 | 2/3/4个客户隔离仍应统一RC4；结构错误优先RC8 |
| `1590-REPLAY-SPOOL` / `1700-WRITE-CONTROL` | 按结论输出eligible或带来源的isolation；对控制行启用溢出检查；校验候选后runner才发布 | 检查47B/55B原始字段、18项control标签和值、拆分和金额等式 |

外部`sort`只用于把已验证候选按既有L2下游顺序恢复为account/sequence/id；它不承担客户聚合。若修改排序/拼接字段，必须保留原始record payload，不能重新格式化金额或transaction_id。

## 逐步修复作业与评分反馈

- 练习A（15分）：从starter先实现一条Snapshot的36B/LF/date/version验证。用本课直接核心坏字节矩阵作对照；学生源码通过`COURSE_SOURCE=/绝对路径/BATCHL3.COB`走官方runner，并确认错误输入RC8且无发布。若出现RC0，优先检查line sequential是否吞掉末LF或CR。
- 练习B（20分）：完成A/T/S/P最小键选择和独立EOF推进。运行16组合矩阵；常见最小修复是在每次比较后只为消耗流设置READ请求，EOF标志不得复位。
- 练习C（20分）：通过SD排序账户与accepted TX，再按customer写磁盘spool。normal的控制总数应为3账户、4笔accepted、客户期末1900/4100。若少一笔，先对照customer次序，不要尝试客户×账户×交易笛卡尔积。
- 练习D（20分）：在组末实现previous opening/count和snapshot limit。equal limit允许；低一元隔离该客户并RC4；多客户同时隔离仍RC4。隔离明细保留原47/55字节。
- 练习E（15分）：输出完整拆分控制并独立核算opening+credit-debit=closing。只改CONTROL数字却不改实际来源输出时，独立verify必须拒绝。
- 练习F（10分）：以固定2M sort pool运行10k/100k/1m，并分别测试集中单客户组。RSS应是COBOL子进程VmHWM（含libcob）；`/proc`临时FD能观察真实spill；禁止把Python oracle、外部sort或整个runner的RSS冒充核心RSS。

最低可接受修复路径：在`1580-DECIDE-GROUP`中先算客户opening + accepted credit - accepted debit，再与L2 customer closing比较；在`1590-REPLAY-SPOOL`按组决定原始来源去eligible或isolation；最后确认runner在校验manifest与独立金额oracle前没有发布目录。重跑`bash scripts/check.sh`，不需要修改canonical L1/L2契约。

## 排错提示

| 现象 | 首查位置 | 期望处理 |
|---|---|---|
| RC8且无结果目录 | 原始固定宽度、末LF、snapshot/previous版本/日期/key顺序 | 结构全批拒绝；不能退成客户RC4 |
| RC4但其他客户有输出 | `customer-status.txt`和`isolation.txt` | 只排除差异客户，eligible/isolation两边分别守恒 |
| RC12无结果目录 | `stderr`中B01/core/system/verify/lock错误 | 清理暂存和锁；不要手动把候选复制成正式输出 |
| 某客户金额翻倍 | `1400-SORT-TRANSACTIONS`与`1550` spool | 检查四流相等时多次消费或误做笛卡尔积 |
| Customer 2被误报缺失 | `1300-SORT-ACCOUNTS` | ACCOUNT原排序键不能充当customer游标顺序 |
| RSS随最大客户组线性增长 | `1550` spool是否真的磁盘文件 | WORKING-STORAGE只留当前行/累计器；不能保存客户组数组 |

## 评分（100分）

| 项目 | 分值 | 判据 |
|---|---:|---|
| 原字节与Copybook契约 | 15 | 47/55/36/39B、LF、ASCII、date/version/key均准确 |
| 真正四流归并 | 20 | 比较`< / = / > / EOF`，只前进匹配流；非单调客户映射通过 |
| N:N业务语义 | 20 | 账户、交易各自聚合一次，无笛卡尔积或重复金额 |
| 磁盘spool与有界内存 | 10 | 大组不进内存；真实SORT池/临时文件观测 |
| L2桥接与冲正 | 10 | 真实REVERSAL-LINK/B01 accepted/rejected/master/report接线 |
| 守恒与RC/发布 | 15 | 拆分control逐值正确；业务RC4发布隔离，8/12无发布 |
| 证据与复现 | 10 | hash、命令、原始RC、实际压力RSS/spill和限制准确 |

最低修复：在 `1580-DECIDE-GROUP` 比较 `GROUP-CLOSING` 与 `GROUP-OPENING + GROUP-CREDIT - GROUP-DEBIT`；原因优先级和隔离规则不改。再在 `1590-REPLAY-SPOOL` 将原47/55字节按原因写出，并确认verify.py逐字节比对。

常见误区：按account_id同步客户游标会误判非单调customer_id；读取 `=` 后只推进一个流会重复/漏客户；把客户组放到WORKING-STORAGE数组会使RSS随最大关联组增长；把accepted与L2 rejected金额相加会破坏账本；RC4不得当系统失败；`splitlines()`会掩盖无末LF/CRLF，发布核验必须检查原始LF字节；不能以空程序输出缺失冒充真实输出写满。

### 讲师复现记录

| 命令/fixture | 原始结果 | 证据 |
|---|---:|---|
| `python3 scripts/check.py` | RC0 | 9项人工政策案例、RC4多组隔离与L2业务拒绝、锁、坏字节 |
| `python3 scripts/check-source.py` | RC0 | reference列宽、starter/编译失败12、reset锁保护与学生源码保留 |
| `bash scripts/run.sh ...fixtures/normal...` | RC0 | normal master/totals与独立人工expected逐字节一致 |
| 独立主代理B03矩阵 | RC0 | 10案例分类和隔离守恒；`validation/evidence/B03-primary-independent.json` |

完整的多档压力证据在 `evidence/B03-author-pressure-2026-10-10.json`。未生成该证据前，不能将压力项目标为通过。
