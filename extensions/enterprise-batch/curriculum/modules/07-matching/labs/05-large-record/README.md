# 07.6 Boss L4：企业客户大记录逐字段比较

本课让你追查两批企业客户快照中，究竟哪些具名业务字段改变。V1 是独立的 1,778 字节固定二进制接口，不改变 27 字节 CUSTOMER、47 字节 ACCOUNT 或 55 字节 TRANSACTION。建议 4 小时；先完成 07.5，并熟悉 PIC、COMP、COMP-3、顺序文件和 RC。

## 实验步骤

```bash
cd curriculum/modules/07-matching/labs/05-large-record
scripts/build.sh /tmp/batchl4
scripts/run.sh fixtures/old.dat fixtures/new.dat /tmp/b04-result
cat /tmp/b04-result/report.txt
(cd /tmp/b04-result && sha256sum -c manifest.sha256)
```

两个文件是无分隔符的固定记录流；文件字节数必须为 1778 的整数倍。`fixtures/old.dat` 有客户 1、3；新批次有客户 1、2、3。客户 2 是 NEW-ONLY；客户 1 的修订号和分类改变；报告会给出字段 ID。每条 FIELD/AUDIT 差异行都携带 run ID、输入版本、旧/新记录序号、遮蔽客户键、field_id 与 canonical COBOL 字段名，因此多个客户在同一字段上各自不同的变化仍能唯一归属到具体记录。返回码 4 表示有合法业务差异，RC0 表示没有差异，RC8 表示输入结构错误，RC12 表示构建、锁、文件或发布故障。目标必须不存在，运行不会覆盖目标。

## 先手算，再改程序

打开 `FIELD-CATALOG.csv`，按 1-based offset 手算 `CUSTOMER_CLASSIFICATION` 与 `LEGAL_SURNAME` 的切片。把新旧客户 1 的记录号和差异字段写进 `evidence/student-template.md`。再生成一份只改尾字段 `SYNC_STATE` 的记录；它是 `IGNORE-AUDIT`，应增加 audit-only 计数而不改变业务差异 RC。尝试仅改变姓氏大小写并补尾空格：按 TEXT-NORM 语义结果应等价。修改 `starter/BATCHL4.COB` 的 TODO 后用 `COURSE_SOURCE=/path/to/BATCHL4.COB` 运行；未完成 starter 必须以 RC12 结束且不能发布。

## 字节与布局

`DESIGN.md`定义 framing、ABI、NULL、比较规则和版本政策。`copybooks/ENTERPRISE-CUSTOMER-V1.CPY` 展示组与叶字段；canonical 参考 Copybook 位于 `instructor/modules/07/05-large-record/`。GnuCOBOL 3.2/Linux x86-64 实测 PIC COMP 为 big-endian；COMP-5 不属于此接口。COMP-3 必须先检查每个 digit nibble 与 C/D sign，再转换或比较；正负零数值相等。不要把二进制字节当文本检验 ASCII。

## 变更调查：客户区分扩成两位

本接口保留 V1 的一位 `CUSTOMER_CLASSIFICATION`：A/B/C/D。调查所有消费点、排序/比较键、文件版本和恢复流程后，另行设计 V2：字段宽度 PIC X(2)、布局版本 002、映射 A1/B1/C1/D1。V1 文件不能原地改写；需要说明旧批次拒绝或转换、并行比对、切换和回滚。`RECORD_STATUS` 是另一语义，不能拿来当分类。

## 工具路线

插件用户可打开 Copybook 与 BATCHL4，使用 `gd` 跳字段、`K` 预览 COPY 并从 Aerial 查看层级。纯终端路线：`rg -n 'CUSTOMER-CLASSIFICATION|COPY|READ|PERFORM' instructor/modules/07/05-large-record curriculum/modules/07-matching/labs/05-large-record`，再用 `awk`/Python 按目录切片核对offset；无需 Neovim 插件。

用 `scripts/init-workspace.sh /tmp/b04-work` 初始化新学员目录；`scripts/reset.sh /tmp/b04-work` 只会删除文件集合完整且输入/结果hash验证通过的 `output/`。遇锁、未知文件、篡改或软链会拒绝，并保留源码和其他学员文件。完整检查入口：`bash scripts/check.sh`，包括逐字段实际offset核对与比较语义矩阵。
