# 模块 12 讲师包（答案、根因、评分）

> 公开仓库无法保密；自学者需知道答案在本目录。

## 交付物对照

| 学员材料 | 讲师材料 |
|---|---|
| `curriculum/modules/12-capstone/` | `instructor/modules/12-capstone/` |
| `starter/CUSTV2.COB`（RC12 骨架） | `system/cobol/CUSTV2.COB`（参考实现） |
| `maintenance/`（变更包） | 本文件第 3 节影响调查要点 |
| `incidents/incident-01/`（不含根因） | `INCIDENT-01.md`（根因/修复/评分） |
| 评分说明 | `grading/grade.py`、`grading/GRADING.md` |

## 1. 参考实现位置

- 客户校验 v2：`curriculum/modules/12-capstone/system/cobol/CUSTV2.COB`
- 客户日报：`curriculum/modules/12-capstone/system/cobol/NIGHTRPT.COB`
- DB 12 表：`curriculum/modules/12-capstone/system/lib/capdb.py`
- 32 节点：`curriculum/modules/12-capstone/system/jobs/*.sh` + `nightly.sh`
- 独立 oracle：`instructor/modules/12-capstone/tools/gen_course.py`

## 2. 常见错误与提示阶梯

1. 把 v2 当作"改第 27 字节"而不是"在区分字段上追加子码" → 提示：企业布局
   前 27 字节是 canonical CUSTOMER v1（第 27 字节 = 状态），只读前 27 字节
   的旧读者必须仍正确。
2. 用 `FUNCTION TRIM` 判宽度却不保证末字节非空格 → 提示：区分码两字节都非
   空格，物理宽度 = trim 长度。
3. 认为“MANIFEST 通过就等于数据没问题” → 指向 `INCIDENT-01.md`。
4. 崩溃恢复时“删完成标记再跑” → 提示：走幂等账本，不要删标记。
5. 断言 `check.py` 通过就当毕业 → 提示：硬门禁与事故现场另行判定。

## 3. 企业客户区分扩展的影响调查要点

- 对象：**独立、版本化的** CAP-CUSTOMER-FEED 布局（v1 31B / v2 32B），
  `CUSTOMER-CLASSIFICATION`（v1 X(1) A/B/C/D → v2 X(2) A1..D1），布局版本
  001→002；与模块 07 L4 命名/版本约定对齐。
- 使用位置：CUSTV2、NIGHTRPT、capdb（customer.table）、JOB002d 调用点、
  fixtures、下游 `customer-day.dat`。
- 不改：06/07/10 canonical、ACCOUNT/TRANSACTION 宽度、**canonical CUSTOMER
  v1 的 27 字节与第 27 字节状态语义**。
- 兼容：v1 读者读企业 v1 仍正确；v2 读者读 v1 升级为 `<code>1`（A→A1..D→D1）。
- 回滚：代码回退 + customer.table 32B→31B 投影（丢弃子码，需备份）。

## 4. RED→GREEN

`maintenance/regression/red-green.sh`：RED 用 `starter/CUSTV2.COB`（v1-only）
对 extension 的 32B 企业客户 feed，期望**非 0**且不产出 v2 流；GREEN 用
`system/cobol/CUSTV2.COB`，期望 0。原始输出见 `evidence/RED-GREEN.md`。

## 5. 事故与结业现场

- 本模块事故见 `INCIDENT-01.md`（重复投递导致重复 transaction_id）。
- 结业现场应另备一个**未展示过**的事故变体（可从模块 11 素材或本模块
  `broken` 的其它触发条件构造），限时调查，评分点同上。
