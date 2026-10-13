# 讲师参考：事故 01 的防再发改动（未接入交付链）

交付链在 JOB003 已安全失败（RC8，不发布）。本文件给出**防再发**的改动
方向：把重复业务键的检出提前到 JOB002 业务校验之后，使日志在更早阶段点名，
而不是等到排序节点才以结构错误结束。

## 改动点

在 `system/jobs/job002-validate.sh` 的 002c 之后、002e 之前插入一个
重复键节点（此处以 002f 表示，保持 002a-e 与事故材料一致）：

```bash
n_duplicate_keys() {
  local node=$1 out
  out=$(python3 "$here/../lib/validate.py" keys \
    --tx "$work/validate/accepted_tx.dat" 2>&1) || {
    c12_log "$node" ERROR "$out"; c12_marker "$node" 8; return 8; }
  printf '%s\n' "$out" >>"$NIGHT_LOG_DIR/$node.log"
  c12_marker "$node" 0
}
```

`validate.py keys` 已是交付代码（JOB003b 使用）；这里只是把它也放到
JOB002，使“上游重复投递”在业务校验阶段即被点名。

## 为什么不直接改交付链

事故发放材料记录的是 JOB003 失败（`materials/logs/003b-sort.log`）。若把
上述节点接入交付链，重放时会在 JOB002 失败，材料与实际不一致。因此本改动
作为**结业现场**的防再发答案保留，不进入交付链。

## 运营侧

- 要求上游在重投时使用新的业务版本与 run_id，并在 MANIFEST 记录去重后
  的校验和。
- 值班不得直接编辑原始接收文件；恢复走业务更正重跑（见 `INCIDENT-01.md`）。
