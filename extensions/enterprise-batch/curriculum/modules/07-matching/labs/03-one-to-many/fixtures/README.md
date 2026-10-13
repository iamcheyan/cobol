# L2 合成输入

所有文件是ASCII文本、LF终止；ACCOUNT 47B、TRANSACTION 55B、REVERSAL-LINK 48B（均不含LF）。数据固定营业日20261009。通过`python3 scripts/generate-fixtures.py`可确定性重建；该脚本只生成数据，不实现账户突合或入账。`SHA256SUMS`覆盖全部输入文件。

| 夹具组 | 目的 |
|---|---|
| normal | 四笔同账户交易、交易间隔冲正、透支拒绝、冻结账户、无交易账户 |
| boundary-* | 空文件/无交易、最大单笔、溢出、零金额、总金额/单账户累计超过13位 |
| business-* | 孤立账户、关闭、跨账户冲正、未来/未接受/重复原交易、冲正金额差异 |
| duplicate-id-cross-account | 不同账户、远隔记录重复全局ID |
| short-transaction / unsorted-transactions | 原始长度和账户/序号排序错误 |
| invalid-link-* | 错账户、错序号、非法ID字符、无对应交易的孤立关系 |

业务拒绝夹具按设计RC4发布拒绝明细；接口/排序/全局唯一性错误RC8不发布。绝不在运行器中改写这些源夹具。
