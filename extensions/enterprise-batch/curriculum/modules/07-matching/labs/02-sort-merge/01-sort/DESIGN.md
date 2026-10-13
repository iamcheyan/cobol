# 07.1 SORT：交易文件确定性排序契约

## 接口与顺序

输入/输出均为TRANSACTION v1：每条55个ASCII字节+LF；LF不计55字节。输入日由参数指定并逐行做Gregorian校验。账户、交易ID、日期、sequence、方向为C/D、金额为13位无符号数字（零合法）、状态仅N；ID只允许ASCII A–Z和0–9，日期按真实Gregorian日历校验。空输入允许，非空最后一行必须LF终止。不得先读入定长PIC再猜原始长度。

业务排序键是(account_id 1–10, sequence_no 35–40, transaction_id 11–26)，三段严格升序。原始55字段字节必须全部保持不变，输出规范LF。sequence相同但ID不同是合法记录，transaction_id决定唯一次序。transaction_id全局重复（包括非相邻、不同账户）是契约错误RC8，无发布；完整复合键相同因此也必然拒绝。不得依赖运行时对相同全键的稳定性。

人工微例：Z…001属于sequence 000001，A…002和M…003同属sequence 000002；按业务键输出Z…001、A…002、M…003。sequence 1的Z字典序排在sequence 2的A之后，但业务顺序必须让Z先；同序号组内A又必须先于M。这同时证明排序不是整行/ID字典序。实际完整样例见expected/normal.dat。

## 程序边界与RC

COBOL SD sort work record由TRANSACTION-V1.CPY组成。SORT的INPUT PROCEDURE逐字节读取、验证并RELEASE；OUTPUT PROCEDURE按RETURN顺序写55字节记录。runner显式设置COB_SORT_MEMORY，默认不继承GnuCOBOL 128M大池；配置必须≥1M。超出排序池进入磁盘work-file。独立外部cut/sort仅检查全局ID唯一，不参与交易排序结果。

| RC | 条件 | 发布 |
|---:|---|---|
| 0 | 输入契约合法、唯一ID、SORT-RETURN=0、输出核验通过 | 原子发布 |
| 8 | 长度/字符/字段/日期错误或重复ID | 不发布 |
| 12 | 打开/读写/锁/构建/临时工作文件/权限/意外SORT-RETURN/核验/发布失败 | 不发布 |

验收器按流核对输出字节、全键升序、原始记录逐字段保持、输入/输出条数守恒和ID唯一；任何候选stdout或部分文件都不是正式产物。SORT返回工作文件资源错误必须确认`SORT-RETURN`，映射RC12。
