# Boss L3：客户日汇总 N:N 对账

## 业务语义与阶段边界

L3 用一个客户作为汇总业务键。一个客户可有N个账户，每个账户可有M笔当日交易；N账户与M交易属于同一客户关联组，但不逐账户×逐交易配对，也不生成笛卡尔积。交易只通过ACCOUNT.customer_id归属一个客户，账户金额和该客户已接收交易各自聚合一次。snapshot与previous-day各是唯一客户记录。

作业入口接收ACCOUNT v1、TRANSACTION v1、REVERSAL-LINK v1、CUSTOMER-SNAPSHOT v1、PREVIOUS-DAY v1。runner先对原始ACCOUNT/TRANSACTION/REVERSAL-LINK调用已验收B01真实L2 JOB；L2负责冻结/关闭、零金额、透支/溢出、跨账户与任意更早冲正等原政策。L3仅消费L2的accepted原交易、rejected原交易和closing master候选，不再次记账。L2若RC0/RC4且候选核验通过，L3继续；L2 RC8/12整批停止。B03仅生成客户对账及“后续可更新”隔离候选，不执行DB更新。CUSTOMER-SNAPSHOT是离线固定字节种子；不能声称来自DB或已完成模块08。

## 日期与版本

ACCOUNT必须为canonical v1 layout `001`且日期为本次BUSINESS_DATE；TRANSACTION采用既有固定TRANSACTION v1 55B契约（该布局不含独立版本字段），日期为BUSINESS_DATE。Snapshot日期必须等于BUSINESS_DATE；Previous-Day日期必须是作业日前一个Gregorian calendar day，**不应用银行工作日日历**。输入都必须是严格宽度ASCII+LF、字段合法、键唯一升序。新增CUSTOMER-SNAPSHOT v1 36B与PREVIOUS-DAY v1 39B字段见[FIELDS](FIELD-CATALOG.md)和对应独立Copybook。日期、版本、结构/排序/重复键错是RC8，整批无发布；不得以旧快照代替缺失或过期快照。

## 聚合、N:N核对与隔离政策

对客户`c`定义：

- `A(c)`：ACCOUNT v1中关联`c`的账户集合；汇总期初`opening(c)`、账户数`accounts(c)`。账户数与余额包括所有ACCOUNT状态A/F/C；冻结/关闭只影响L2交易接受政策，不从客户汇总中丢弃。
- `T(c)`：L2 accepted中经ACCOUNT account_id关联到`c`的交易集合；每条只计一次，分别求`credit(c)`、`debit(c)`、`tx_count(c)`。
- `P(c)`：PREVIOUS-DAY中唯一一条昨日客户摘要，包含`previous_accounts(c)`、有符号`previous_close(c)`。
- `S(c)`：CUSTOMER-SNAPSHOT中唯一一条客户记录，状态与客户账户/余额上限。

结构完整且`S/P`均存在、客户状态A时必须满足：

1. 当前账户聚合期初总额与前日客户closing相等；当前账户数与前日全部关联账户数（含A/F/C）相等。
2. `expected_close = previous_close + accepted_credit - accepted_debit`。
3. L2逐账户closing按customer重新汇总后，必须等于`expected_close`。
4. 当前账户数不超过snapshot.max_account_count；客户closing不得超过snapshot.max_customer_balance。
5. 每条ACCOUNT/L2 accepted TX都映射到唯一customer；每条snapshot/previous记录恰好消费或输出孤儿差异。

缺Snapshot、缺Previous-Day、Snapshot客户D、账户数量/上限不符、期初与前日不一致、聚合余额与L2 closing不一致均为客户级业务拒绝RC4。该客户全部关联账户与交易进入隔离报告，不进入`eligible-master.dat`/`eligible-transaction.dat`，不得供JOB006 DB更新；其他结构合法客户仍可发布。孤儿Snapshot/Previous-Day行作为独立来源差异，消费并标明记录键。RC4输出必须包含原因、customer_id、来源键/计数/金额；业务拒绝记录不可仅靠stdout。

原ACCOUNT与L2 closing master按顺序逐条对应；除balance字段外，其余47B字段必须原字节一致。余额允许因当日accepted交易而改变，且必须独立满足逐账户 opening + accepted credit - accepted debit = L2 closing；客户级opening/closing再按customer聚合。重复/逆序/字段宽度/ASCII/日期/版本错误、重复账户/客户、全局重复transaction_id、accepted tx找不到唯一ACCOUNT、非余额字段变化、控制不守恒是结构或运行契约错误RC8/12，整批不发布。L2 rejected.dat保留原交易字节和原因作为独立B01业务控制，不进入L3 accepted交易金额。全局必须分别核对：原ACCOUNT数=eligible master数+isolated account数；L2 accepted数=eligible accepted TX数+isolated accepted TX数；accepted credit/debit金额各自等于eligible与isolated对应金额之和。L2 rejected count单列，不并入accepted或隔离金额。

## 四流状态与消费表

ACCOUNT和L2 accepted交易原始键按account_id。由于`customer_id`不随account_id单调，不能把客户snapshot指针与账户扫描直接前移比较。本实现由COBOL进行带source key的账户/交易客户归属、以固定2M `COB_SORT_MEMORY`对派生客户流排序，再对客户键流作四路有界归并。中间记录保留原account/transaction字节及account_id，证明来源。最终客户级判断直到该客户四路组消费完成才确定；因此核心使用单客户磁盘spool按记录写入账户/交易来源，再完成等式和limit判断。判定合格后顺序重放spool到eligible候选；拒绝时逐条重放为来源定位隔离记录，清空spool后进入下个客户。内存只留键、计数/金额累计器和一条当前记录，组大小只影响临时盘，不缓存整组数组。

| 比较状态 | 输出/累计 | 推进规则 |
|---|---|---|
| 任一流EOF | EOF独立布尔状态；不可用零/全9哨兵 | 已EOF不再READ；清空剩余非EOF来源 |
| 最小customer key只见Account | 汇总一个或多个账户opening/count；若缺snapshot/previous则RC4隔离 | 仅推进对应账户流当前customer组 |
| 最小key只见Accepted-TX | 必须能关联到ACCOUNT，否则RC8；汇总每笔贷/借/数量一次 | 仅推进该流当前customer组 |
| 最小key只见Snapshot或Previous | 输出孤儿来源差异；不丢行 | 推进该单行快照流 |
| 多流最小key相等（`=`） | 该customer所有来源合并为一份有界累计器，算守恒并输出MATCH或具体差异 | 每个参与流只消费同key记录；组结束读下一条 |
| Account/Transaction customer key `<`其它流 | 完成本客户账户/交易组；缺失来源按RC4隔离 | 推进小key来源，不推进其它流 |
| Snapshot/Previous customer key `<`其它流 | 输出对应孤儿快照/前日记录 | 推进较小的快照流 |
| 多个客户键交错 | 选当前未EOF流的最小键处理；重复全键/客户已由预检RC8 | 每次消费必须增加某个流的唯一来源计数 |

**手工trace主例：**ACCOUNT按account_id为A1→customer02 opening1000、A2→customer01 opening2000、A3→customer02 opening3000；交易分别A1 C50/D20、A2 D100、A3 C70。客户键排序后A流customer01(2000)、customer02(1000+3000)。T流客户01 D100；客户02 C50/D20/C70。Snapshot customer01 statusA max_account_count1 max_balance8000，customer02 A/2/10000。Previous-Day customer01 account_count1 close2000，customer02 account_count2 close4000。客户01期末1900，客户02期末4100；总体3账户、4交易、期初6000、贷120、借120、期末6000。每笔TX仅归属一个account后贡献给唯一customer；customer02 snapshot的账户数/金额只检查一次，不能分别复制到A1和A3。

四游标trace使用customer key而非原account key：起始键A=01、T=01、S=00、P=01，`S<A/T/P`，先输出Snapshot-only 00并只推进S；下一步四键均01，`=`时消费各自customer01组一次；推进后四键均02，再消费customer02；最后A/T/S为EOF而P=03，只输出Previous-only 03。若任一流先EOF，EOF状态独立保存，其他流继续直到全EOF。自动测试枚举A/T/S/P存在性的16种EOF组合；孤立交易（无account）由前置L2分类NO-ACCOUNT，不成为L3 accepted流。

## RC与发布

| RC | 策略 | 正式输出 |
|---:|---|---|
| 0 | 所有客户核对通过、无L2拒绝及L3业务差异 | 验证后发布 |
| 4 | 有L2拒绝或客户级差异；输出原始拒绝与L3隔离结果，其它合格客户可继续 | 验证后发布，后续JOB须允许RC4并排除隔离记录 |
| 8 | 任一输入/版本/排序/唯一性/映射/守恒结构错误 | 不发布 |
| 12 | 构建/权限/磁盘/排序工作文件/锁/核验/发布/意外RC错误 | 不发布 |

输出先写锁保护的私有候选目录，独立byte/count/金额核验通过后no-clobber发布。任意锁存在时reset拒绝并保留所有文件。原始输入快照SHA不变；候选stdout不代表正式结果。run.sh会保留L2报告、L2 accepted/rejected、客户对账报告、隔离来源报告、eligible候选、control与输入/输出manifest。
