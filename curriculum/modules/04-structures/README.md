# 模块 04 复杂数据结构（04.1–04.3）

建议 5 小时。先修：模块 02（01/05/77/88、分组）、模块 03（字节布局）。
本模块只讲结构与布局，不改任何冻结契约：CUSTOMER v1=27B、ACCOUNT v1=47B、
TRANSACTION v1=55B 保持不变；04.3 复用模块 07 的 175 字段企业客户记录。

## 1. 业务为什么需要（需求）

接手一个陌生 Batch 时，记录里往往有**别名视图**（同一段字节有两种读法）、
**可重复片段**（地址行、电话）、以及**变长段**（按数量决定长度）。更麻烦的是：
客户区分字段从 1 位扩成 2 位时，后面**所有字段的偏移都会移动**。本模块的任务是：
读懂这些结构，产出可追踪的字段目录，并能回答“改一个字段会移动哪些后续字段”。

## 2. 输入从哪来、格式与前提

- 04.1/04.2 不读输入：程序自己声明结构并打印 `LENGTH OF` / 偏移证据。
- 04.3 读**原始二进制**记录流，每条 `ENTERPRISE-CUSTOMER-V1` = 1,778 字节，无分隔符。
  Copybook canonical 位于
  `instructor/modules/07/05-large-record/ENTERPRISE-CUSTOMER-V1.CPY`（**只读复用**）。
- 字段目录 [FIELD-CATALOG.csv](FIELD-CATALOG.csv) 是模块 07 canonical catalog 的副本，
  175 个具名叶子字段；偏移由 1 起算，组项目不占字节，无 FILLER 凑数。
- 夹具由 [scripts/generate-fixtures.py](scripts/generate-fixtures.py) 确定性生成
  （正常/边界/非法），SHA256 见 [fixtures/SHA256SUMS](fixtures/SHA256SUMS)。
- 前提：GnuCOBOL 3.2、Linux x86-64、默认方言。

## 3. 构建 / 运行 / 复位（任意启动目录）

```bash
cd /home/tetsuya/development/cobol
bash curriculum/modules/04-structures/scripts/run.sh 04.1 /tmp/m04-shape
bash curriculum/modules/04-structures/scripts/run.sh 04.2 /tmp/m04-copy
bash curriculum/modules/04-structures/scripts/run.sh 04.3 /tmp/m04-ent \
     curriculum/modules/04-structures/fixtures/normal/enterprise-2.dat
cat /tmp/m04-ent/report.txt
```

- 04.3 输入字节数必须是 1,778 的整数倍，否则运行器先判 RC8 且**不发布**。
- 输出目录必须不存在（no-clobber）；私有 stage 全部校验通过后才原子发布；
  失败或已有同名目录一律拒绝（RC12）。
- 复位：`bash curriculum/modules/04-structures/scripts/reset.sh /tmp/m04-ent`
  仅在文件集合完整且 `manifest.sha256` 校验通过时删除输出目录。

派生文件：`report.txt`、`stderr.txt`、`compiler.txt`、`source.sha256`、
`manifest.sha256`；04.3 另有输入快照 `input.dat` 与 `inputs.sha256`。

## 4. 预期输出、RC 与独立核算

- **04.1 RC0**：`REDEFINES` 别名视图不重复计长（父组=18 字节）；
  `66 RENAMES` 长度 7；`OCCURS ... INDEXED BY` 按索引取值；`OCCURS DEPENDING ON`
  的 `LENGTH OF` 随计数变化（count=3→17，count=7→37）。见
  [expected/04.1-structures.txt](expected/04.1-structures.txt)。
- **04.2 RC0**：V1=1,778，V2（`CUSTOMER-CLASSIFICATION` 由 `X(1)` 扩 `X(2)`）=1,779，
  移位 +1。见 [expected/04.2-copy-shift.txt](expected/04.2-copy-shift.txt)。
- **04.3**：正常/边界 RC0，逐记录打印定位字段；结构错误（长度、版本、ABI、非数字 key）
  RC8 且零发布。见 [expected/04.3-normal.txt](expected/04.3-normal.txt) 等。
- **独立核算**：`scripts/check.py` 生成两个探针程序，用 GnuCOBOL 的 `ADDRESS OF`
  逐字段测量 175 个叶子的偏移并与目录比较；再测量 V1/V2 的 `LENGTH OF` 与关键字段
  地址，证明“加宽一个字段使后续偏移 +1”。不把程序输出当答案。
- **发布前语义核验**：`scripts/run.sh` 在发布前调用 `scripts/verify.py`：04.1/04.2 由
  结构语义重算期望报告；04.3 按 `FIELD-CATALOG.csv` 的偏移与 PIC 从输入原始字节重算
  每条记录的 ID/STATUS/SURNAME/CLASS/RISK/SYNC 与记录数。仅把 `WS-EXERCISES-DONE`
  改成 `'Y'`、占位报告、跳过记录或错误字段值都会失败且**不发布**；`check.py` 已加入
  对应回归。

## 5. 需要修改哪里、哪些不能破坏

修改 `starter/M04SHAPE.COB`、`starter/M04COPY.COB`、`starter/M04ENTERPRISE.COB`
的 TODO，完成后把各自的 `WS-EXERCISES-DONE` 设为 `'Y'`。**不能破坏**：

- 模块 07 canonical Copybook（只读复用，不复制成不同实现）；
- 175 字段的目录与偏移（改字段宽度必须走 V2 影响调查，见 §6）；
- CUSTOMER/ACCOUNT/TRANSACTION 冻结契约；固定格式 80 列规则。

## 6. 故意破坏与恢复（可复现故障）

1. **ODO 不是组内最后一项**：`faults/odo-not-last.COB` 编译被拒（真实 `cobc` 错误）。
2. **REDEFINES 未紧邻被重定义项**：`faults/redefines-not-adjacent.COB` 编译被拒。
3. **加宽字段的连锁偏移**：把 `CUSTOMER-CLASSIFICATION` 由 `X(1)` 改 `X(2)`，
   其自身偏移不变（460），但其后**每个**字段 +1，总长 1,778→1,779。V1 文件不得原地改写；
   必须设计 V2（布局版本 002）、旧文件拒绝/转换、并行比对与回滚。
4. **结构错误**：`invalid/` 的长度错位、版本、ABI、非数字 key 一律 RC8、零发布。

**恢复**：修好结构或实现后重跑；运行器从不覆盖既有输出目录，V1 fixtures 不变。

## 7. 插件路线与纯终端替代

- 插件：`gd` 跳字段定义、`K` 预览 COPY、Aerial 看层级、`:CobolCalcRecord` 估算记录大小。
  插件估算**不得**作为布局最终依据。
- 纯终端：`rg -n 'REDEFINES|OCCURS|DEPENDING|COPY REPLACING'`；用 `awk -F,` 按
  `FIELD-CATALOG.csv` 的 offset 切片；`od -An -tc`/`xxd` 看原始记录。两者都能独立完成。

## 8. 交付证据与失败判定

需交：源文件与 SHA256、编译器版本、每 lesson 命令与原始 RC、175 字段目录与
`ADDRESS OF` 实测对照、V1→V2 加宽后的偏移移动清单、结构错误 RC8 零发布证据、
`check.sh` 输出。模板见 [evidence/README.md](evidence/README.md)。

**失败判定**：用 FILLER 凑字段数；REDEFINES/OCCURS 重复计长；把变长 ODO 当固定长；
改 PIC 前不做影响调查；只给插件截图不给实测偏移；或只把 `WS-EXERCISES-DONE` 改为
`'Y'` 提交占位/错误报告（`run.sh` 的独立语义核验会拒绝且不发布）。任一即失败。
