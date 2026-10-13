# 讲师说明：07.1 SORT / 07.2 MERGE

## 教学验收重点

目标是让学习者从原始接口和独立预期推导有序流，而非背诵两条COBOL语句。先让学员画完整键及每一步游标，再打开程序：SORT 的 `LOAD-INPUT` 逐原始字节形成一条TRANSACTION v1记录，`CHECK-FIELDS`检验ASCII字段和Gregorian日期，有效记录才 `RELEASE`；`WRITE-OUTPUT`在 `RETURN` 顺序写出。MERGE的 `VALIDATE-SOURCE` 对每个原始流做同样的字节/字段校验并检查该流严格升序，然后由 `MERGE ... USING FEED-A FEED-B` 真实合并；不能把拼接后排序作为替代。

结构合法zero amount不得在07.1/07.2拒绝：它是合法TRANSACTION v1记录，排序和合并都应原样保留。后续BATCHL2根据业务将其拒绝为ZERO-AMOUNT并返回RC4。ID只允许ASCII大写A–Z/数字，状态仅N；REVERSAL-LINK v1另承载冲正关系。课程不改变canonical copybook或L2业务契约。

## 评分（每课100分）

| 项 | 分数 | 可观察证据 |
|---|---:|---|
| 手工复合键trace | 20 | Z在较小字典序A之前是因为sequence；同sequence A先于M |
| 固定记录字节/字段/日期解释 | 20 | 能说明55B+LF、字段位置、严格ASCII、真实日期和zero policy |
| 真实算法控制流 | 25 | SORT能追踪RELEASE/RETURN；MERGE能逐步说明两游标及输入各自预排序 |
| 错误路径和发布保护 | 20 | 坏原字节/逆序/重复ID映射RC8；系统/工作文件RC12；无失败发布 |
| 独立expected与下游桥接 | 10 | 字节expected、L2报告/master/accepted/rejected与守恒值一致 |
| evidence完整性 | 5 | 命令、原始RC、版本、输入/输出SHA和实际观察值齐全 |

## 最小修复路径

- SORT结果是整行排序：在 `SORT ... ON ASCENDING KEY`里依次指定 `TX-ACCOUNT-ID`、`TRANSACTION-SEQUENCE`、`TRANSACTION-ID`；再跑Z/A/M例子。
- 相同sequence次序偶尔不同：排序键漏了ID，或依赖运行时稳定性；全局ID必须唯一，完整键严格升序。
- 短/长/CRLF/Tab混进候选：检查 `LOAD-INPUT` 是否真的逐byte读到LF，固定55B只有在LF到来时才提交；不能只用LINE SEQUENTIAL PIC X(55)猜宽度。
- MERGE逆序输入仍被接受：`VALIDATE-SOURCE`需分别重置前键并检查每条源的严格升序；不可将Python preflight当成COBOL课程核心。
- 零金额RC8：按TRANSACTION v1把它保留到L2，业务拒绝不是结构错误。
- 输入完整但目标被覆盖：runner的lock、输入快照、候选独立byte/order/multiset验证和no-clobber发布不可跳过。

## 常见误区

1. 整行ASCII顺序等于业务顺序。物理记录的ID位于sequence之前，Z(seq1)/A(seq2)会揭示错误。
2. MERGE会替每条源排序。它要求源已排序；逆序源是数据契约错误RC8。
3. READ进PIC X(55)便能证明文件记录长55。line-sequential会处理行尾和部分字符；核心验收对原始字节逐一读取。
4. 用Python排序或SQL排序给学生展示结果，声称实现了COBOL SORT/MERGE。Python只作JOB门禁/独立oracle；排序/归并核心实际在COBOL。
5. `COB_SORT_MEMORY=2M`等于进程总RSS 2MiB。它只固定GnuCOBOL排序池；证据单独报告core RSS、工作文件和driver资源范围。

## 实际指引

reference核心在本讲师目录；学员starter在两课各自的 `starter/`。共享TRANSACTION定义位于 `curriculum/bank/copybooks/TRANSACTION-V1.CPY`。运行实际验收：`bash curriculum/modules/07-matching/labs/02-sort-merge/check.sh`；压力证据以课程证据JSON为准。讲师须区分某一项用例PASS与整个B02获批，不得提前标记后续模块放行。
