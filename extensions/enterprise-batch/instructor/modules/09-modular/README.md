# 模块 09 讲师参考实现

本目录是模块 09 的 canonical 参考实现与讲师材料。

- `BATCH09.COB`：主程序（调用者），组合三个共通模块。
- `AMTCALC.COB`：金额入账共通模块，接口 `AMT-CALC-INTERFACE` v1。
- `CUSTVAL.COB`：客户校验共通模块，接口 `CUST-VAL-INTERFACE` v1。
- `LOGGER.COB`：追加日志共通模块，接口 `LOG-INTERFACE` v1。
- `INSTRUCTOR.md`：提示阶梯、根因表、评分量与常见误区。

接口 Copybook 在 `curriculum/modules/09-modular/copybooks/`；学员任务、运行与复位命令见
`curriculum/modules/09-modular/README.md`，接口布局见其 `DESIGN.md`。

从仓库根目录编译：

```bash
cobc -Wall -I curriculum/modules/09-modular/copybooks \
  -I curriculum/bank/copybooks -x -o /tmp/batch09 \
  instructor/modules/09-modular/BATCH09.COB \
  instructor/modules/09-modular/AMTCALC.COB \
  instructor/modules/09-modular/CUSTVAL.COB \
  instructor/modules/09-modular/LOGGER.COB
```

正式运行请用 `curriculum/modules/09-modular/scripts/run.sh`（发布前用独立模型校验）。
