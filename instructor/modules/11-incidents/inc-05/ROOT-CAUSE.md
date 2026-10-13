# inc-05 讲师根因（系统资源失败 / 临时空间或权限）

## 触发条件
JOB003 在父目录下用 `mktemp -d` 创建排序工作区。本窗口内临时空间/
权限异常，`mktemp` 失败，节点以 **RC12** 中止。

## 根因
**环境/资源失败**，非数据或业务缺陷。`job003-sort.sh` 已把
`mktemp` 失败映射为 RC12，并保证：

- 不产生 `publish/<run_id>`（无正式发布）；
- 不残留临时目录；
- 释放业务日锁。

## 逐层提示阶梯（对应 student/hints.md）
1. 失败在 JOB003，RC12（系统）。
2. 读 `job003-sort.sh`：`mktemp -d` 建排序工作区；失败点即资源。
3. 复现脚本在 PATH 上注入必败的 `mktemp` 重现现场。
4. 失败后现场完整性：无临时残留、无发布、锁释放。
5. 恢复=修环境 + 新 run_id；防再发=前置资源检查与水位告警。

## 误导线索
- “把失败当业务拒绝 RC8”：RC12 是系统异常的课程约定。
- “重试会自动成功”：资源问题不修，重试仍失败。
- “只要程序退出就算没发布”：要显式检查 publish/ 与锁，而非凭日志推断。

## 证据
- `scene/logs/nightly.log`：`JOB003 ERROR: cannot create sort workspace
  (temp space/permission)`；RC=12（`scene/rc.txt`）。
- `scene/scheduler-status.txt`：JOB003 FAILED rc=12，JOB004+ NOT_RUN。
- 失败后：无 `publish/<run_id>`、无 `work/.m11sort.*` 残留、锁目录已清。

## 最小修复
修复临时空间/权限（或改指可写 `TMPDIR`）；程序侧可选加前置资源检查。

## 恢复 / 重跑
资源恢复后用**新 run_id**重跑；不沿用失败目录。

## 防再发
JOB 入口磁盘水位/可写性前置检查、集中临时目录、失败清理与告警。

## 评分点
- RC12 正确分类，区别于 RC8。
- 用命令证明“无发布、无锁残留、无临时残留”。
- 恢复步骤与防再发措施具体可执行。
