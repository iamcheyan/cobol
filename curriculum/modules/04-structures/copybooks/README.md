# 版本化接口（只读复用）

本模块**不复制**企业客户 Copybook，避免出现第二份不同实现。canonical 版本随学生包
发布，位于：

    curriculum/modules/07-matching/labs/05-large-record/copybooks/ENTERPRISE-CUSTOMER-V1.CPY

（仓库内讲师副本在 `instructor/modules/07/05-large-record/`，二者内容一致。）
模块 04 通过 `cobc -I <canonical copybook dir>`（见 `scripts/build.sh`，有讲师树时
优先讲师树，否则用上者可发布路径）在编译期 `COPY` 该文件；04.2 另用 `COPY ...
REPLACING` 在**内存中**派生 V2（`CUSTOMER-CLASSIFICATION` 由 `X(1)` 扩为 `X(2)`），
不落地新 Copybook。

基础银行接口（CUSTOMER v1=27B、ACCOUNT v1=47B、TRANSACTION v1=55B）另见
`curriculum/bank/copybooks/`，本模块不改动。
