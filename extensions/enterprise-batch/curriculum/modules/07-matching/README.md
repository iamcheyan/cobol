# 模块07：企业 Batch 核心算法（12 小时）

模块07是企业夜间银行 Batch 的处理核心，也是全部课程难度与验收标准的标杆。它把模块06的文件契约、模块10的JOB编排与模块11的事故调查都串在同一个突合/排序模型上：SORT 与 MERGE 产生**可证明有序**的输入，L1 做 1:1 分类，L2 做 1:N Key Break 与余额、冲正，L3 做多流/N:N 客户日汇总，L4 做 150+ 字段逐字段差异。**核心排序/突合/余额/逐字段差异必须用 COBOL 顺序读与有界状态实现**；Python 只用于生成数据、独立 oracle 与 JOB 门禁，不得用 SQL JOIN 或全量数组替代被教的算法。

## 课次与实验单元

| 课次 | 实验单元 | 主题 |
|---|---|---|
| 07.1 | [labs/02-sort-merge/01-sort](labs/02-sort-merge/01-sort/README.md) | SD SORT、INPUT/OUTPUT PROCEDURE、真实工作文件与临时空间失败 |
| 07.2 | [labs/02-sort-merge/02-merge](labs/02-sort-merge/02-merge/README.md) | 至少两路已排序流的 MERGE、排序键与同键次序 |
| 07.3 | [labs/01-one-to-one](labs/01-one-to-one/README.md) | Boss L1：1:1、三类输出、双 EOF 组合 |
| 07.4 | [labs/03-one-to-many](labs/03-one-to-many/README.md) | Boss L2：1:N Key Break、余额守恒、拒绝、带原交易引用的冲正 |
| 07.5 | [labs/04-many-to-many](labs/04-many-to-many/README.md) | Boss L3：Master/交易/Snapshot/前日 四流、业务 N:N 客户日汇总 |
| 07.6 | [labs/05-large-record](labs/05-large-record/README.md) | Boss L4：175 具名字段、字段目录、逐字段 RAW/TEXT-NORM/NUMERIC/IGNORE 比较 |

关联练习路线（同一银行模型、同一冻结契约）：

```text
模块06 校验输出 ──unserated transactions──▶ 07.1 SORT ──有序──▶ 07.2 MERGE（多路）
        │                                                        │
        ▼                                                        ▼
   ACCOUNT/TRANSACTION v1 ──▶ 07.3 L1 分类 ──▶ 07.4 L2 余额/冲正 ──accepted──▶ 07.5 L3 客户日汇总
                                                                                     │
                                       企业客户二进制快照（1778B/175 字段）────────▶ 07.6 L4 逐字段差异
```

- 07.1/07.2 的 `common/` 固定了 SORT 与 MERGE 普通流进入 L2 的桥接（含零金额桥接 RC4）与逐字节 expected。
- 07.5 的官方 runner 从原始 ACCOUNT/TRANSACTION/REVERSAL-LINK 进入真实 L2，再以 accepted 推进客户聚合，不伪造已接受交易、不重复应用交易。
- 07.6 独立使用企业客户二进制快照，与文件突合解耦，专注字段级比较。

## 冻结契约（不得静默更改）

- CUSTOMER v1 = 27 字节；ACCOUNT v1 = 47 字节；TRANSACTION v1 = 55 字节（见 [bank/copybooks](../../bank/copybooks/) 与 [BANK-SYSTEM.md](../../../docs/curriculum/BANK-SYSTEM.md)）。
- 交易排序全键 = (account_id, sequence_no, transaction_id)；55 字节原始字段逐字保留，输出 LF。
- RC 约定：0 正常；4 业务拒绝/差异但发布核对结果；8 致命数据错误不发布；12 系统错误不发布。
- 冲正使用独立版本化的 REVERSAL-LINK 关联接口，不重解释 55 字节交易字段。
- 150+ 字段企业客户记录为 1778 字节固定二进制，字段目录见 [labs/05-large-record/FIELD-CATALOG.csv](labs/05-large-record/FIELD-CATALOG.csv)。

## 从干净 checkout 运行

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/modules/07-matching/check.sh        # 模块07全部实验的快速验收入口
bash curriculum/check.sh                            # 仓库级总入口（含模块07与全部基线）
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py   # L4 大记录完整链路压力
```

每个实验单元都支持任意启动目录、空格路径；运行器先隔离候选、独立核验后再 no-clobber 发布；失败时不留正式输出、不删除他人锁。学员 starter 与讲师参考分离，参考答案在 [instructor/modules/07](../../../instructor/modules/07/)。

## 学员包

`bash curriculum/scripts/package-student.sh <目标目录>` 生成排除 `instructor/`、讲师根因与答案快照的学生练习包（可重复、内容稳定）。学生包中的 run/check 命令可直接运行；需要查看答案时在完整讲解仓库中阅读 `instructor/`。

## 验收要点

- SORT/MERGE 使用真实 SD/RELEASE/RETURN 与 MERGE USING；逆序、重复全局 ID、逐字节字段错误都被拒绝。
- L1 覆盖双 EOF 与三类输出计数守恒；L2 覆盖同键累计、次序、重复交易、溢出、冲正与两级金额守恒；L3 覆盖四流基数表、状态消费、快照日期/版本与客户级拆分守恒；L4 覆盖 175 字段目录与独立差异清单（无漏报/误报）。
- 内存/磁盘有界：顺序算法工作区不随文件总数或同键组规模线性增长；SORT 真实溢写与资源失败有独立证据。
- 每个实验都有正常/边界/异常夹具、独立 expected、starter、参考实现、故障练习与学员证据模板。
- 插件（大纲、段落跳转、Copybook 预览、PIC 估算）与纯终端替代路线并列。

主代理独立验收记录见 [tasks/enterprise-cobol-review.md](../../../tasks/enterprise-cobol-review.md)。
