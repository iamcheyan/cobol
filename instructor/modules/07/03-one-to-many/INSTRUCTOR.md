# L2 讲师说明

## 提示阶梯

1. 学员先画账户与交易双指针表；指出只前进交易指针还是只前进账户指针，以及 EOF 后如何排空另一侧。
2. 让学员用 normal 的四笔账户1交易手算余额。拒绝的OVERDRAFT不进入入/出账累计。
3. 指出 v1 55B没有原交易引用；REVERSAL-LINK v1按交易ID接入，字段固定48B。
4. 跨账户冲正读取的是已被顺序JOB预装的INDEXED账本记录；检查账户、较早序号、state=A和kind=N，再核对反方向及金额。冲正成功后原记录REWRITE为V，第二次引用被拒绝。
5. 若守恒失败，先检查逐账户控制记录，再核对总Control；如果单账户余额本身超过13位，应是业务拒绝而非运行时数据异常。

## 根因与触发

| 夹具 | 根因 | 预期 |
|---|---|---|
| duplicate-id-cross-account | 不同账户使用同一全局交易ID | 外部排序发现重复，RC8无发布 |
| short-transaction / unsorted-transactions | 原始长度/排序契约破坏 | RC8无发布 |
| invalid-link-key / invalid-link-sequence / invalid-link-id | 关联键、顺序、字符集不符 | RC8无发布 |
| invalid-unused-link | 关联没有对应交易行 | 全部读取后RC8无发布 |
| business-cross-account-reversal | ID指向另一账户已接收的原交易 | 逐笔拒绝CROSS-ACCOUNT，RC4发布 |
| business-future-reference | 目标在同账户更晚序号 | REFERENCE-NOT-PRIOR，RC4发布 |
| business-original-not-accepted | 原交易因透支未入账 | ORIGINAL-NOT-ACCEPTED，RC4发布 |
| business-already-reversed | 已冲正的原交易再次被引用 | ALREADY-REVERSED，RC4发布 |
| business-reversal-mismatch | 冲正金额与原金额不同 | REVERSAL-MISMATCH，RC4发布 |

## 关键审查点

- 不接受每账户数组、Python匹配、SQL JOIN或每笔全文件重扫。
- 全局交易ID检查必须跨账户，排序次序来自C locale下的外部SORT；COBOL主算法仍顺序读取账户与交易。
- INDEXED账本是磁盘工作集，单键随机READ/REWRITE；索引错误要检查FILE STATUS。学生应运行`check-indexed.py`观察22重复键、23未找到和写失败状态。
- 文件原始长度在COBOL读字节时获得，不能先MOVE进55字节字段再判断。
- 账户组输出在Key Break收尾之后；不能把closing提前写出，也不能缓存组。
- 跨账户金额守恒及大于13位的18位总计使用`boundary-aggregate-over-13`独立预期。

## 评分量表（100分）

| 项目 | 分值 | 满分证据 |
|---|---:|---|
| 输入契约与失败保护 | 20 | 原始宽度/LF/排序/字符集/全局ID验证；RC8/12无发布且输入快照不变 |
| 有界Key Break主循环 | 25 | 双指针单调前进，正确处理空组、任意组大小、EOF；逐笔输出后才写closing |
| 账本冲正规则 | 20 | INDEXED按ID读写；状态、账户、日期/先后、方向/金额及重复冲正均正确分类 |
| 金额与守恒 | 20 | 单笔/账户/全局精确累计和SIZE ERROR；逐户及总账守恒真实校验 |
| 独立验收与说明 | 15 | 独立expected、normal/boundary/invalid测试、复现命令、证据与原因分析 |

接口完整性RC8、失败仍发布、跨账户重复ID漏检、核心循环缓存同键组/逐笔重扫文件，均属关键缺陷，课程不得验收；对应评分项最高记0。

## 最小修复提示与常见误区

最小里程碑依次为：先读原始字节并验证记录长度；再建立按ID唯一的INDEXED账本及独立探针；然后实现两个有序输入指针和Key Break；最后接入余额、拒绝原因、控制累计及逐项expected。每个里程碑先运行对应失败用例，再做实现并保留原始RC。

常见误区：将输入MOVE到定长字段后再判断长度会掩盖超长/短记录；只比较当前交易与上一条ID会漏掉跨账户非相邻重复；按组缓存会让最大账户组决定内存；先输出ACCOUNT closing会要求回看或缓存；把业务RC4一律当无发布会丢失已核对的拒绝报告；把冲正当成反向普通交易会漏掉原交易存在、已接收、未冲正及金额/方向的证明；将所有索引非00状态都映成RC8会把磁盘故障误报为数据错误。
