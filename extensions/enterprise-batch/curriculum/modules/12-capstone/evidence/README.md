# 模块 12 证据模板（学员填写，勿预填通过结果）

对每个实验/日类型复制一份，填写实际命令与**原始退出码**。证据与断言
不符即判失败；不得只写“通过”。

```
实验/日类型: normal | abnormal | rerun | extension | incident-01 | ...
仓库版本 (git rev-parse HEAD):
平台: Linux x86-64 / GnuCOBOL <cobc -V 首行>
营业日: YYYYMMDD
run_id:
command: <完整命令>
原始 RC: <数字>
输入校验和: <sha256sum 输出>
输出校验和: <sha256sum -c MANIFEST.sha256 结果>
核对表: received / validate_accepted / validate_rejected /
        match_accepted / match_rejected / ledger_applied /
        opening_total / credit_total / debit_total / closing_total
下游 customer-day 校验和:
调查结论:
限制/未验证项（如 DB 层为离线文件检查点）:
```

## 四类日必须提交

| 日 | 期望 RC | 已发布 | 关键期望 |
|---|---:|---|---|
| normal | 0 | 是 | closing/customer-day 与 `expected/` 一致 |
| abnormal | 4 | 是 | 控制总数守恒，拒绝有分类 |
| rerun | 0 | 是 | 账本/余额不变，`new_transactions=0` |
| extension | 0 | 是 | v2 区分（含 `D1`），v1 兼容 |

## 恢复与事故必须提交

- 五类崩溃边界：`--crash-at` 的原始 RC（97）与恢复后 RC（0）、账本行数。
- 事故 01：现象/时间线/假设/最小复现/根因/恢复/防再发，附原始证据路径。

## 判为失败

任何 JOB 失败却产生正式发布；同日重跑重复扣款；崩溃恢复后
DB/账本/文件/状态不一致；把旧 `publish/<run_id>` 冒充本次；把系统失败
落成业务拒绝；声称真实 DB 已验证（本模块 DB 层是离线文件检查点）。
