# 07.3 / Boss L1：两个有序流的 1:1 突合

建议 2 小时。先修：能读 SELECT/FD/FILE STATUS、PERFORM、EVALUATE；理解定长文件字节宽度。尚未具备基础时先阅读[数据契约](../../../../../docs/curriculum/BANK-SYSTEM.md)，再做[字节实验](../../../../validation/layout/README.md)。

## 你的业务任务

夜间处理收到账户 Master 和交易文件。上游承诺本练习每账户最多一笔交易。你需要区分：双方都有、只有账户、只有交易。孤立交易可能代表上游账户尚未到达，不能静默丢弃。本课只分类，**不更新余额、不扣款**；后面的 L2 才定义状态、入出账和金额政策。

不要把全部文件放入数组，也不要对每条交易重新扫描 Master。每个文件只向前读，工作区只保存当前记录、上一个键及固定数量的计数器。

## 从干净 checkout 运行

Linux 验证环境需要 GnuCOBOL 3.2、Bash、GNU coreutils（含 realpath、sha256sum）、Make/Git；验收另需 Python 3。不需要插件和数据库。macOS/WSL 尚未验证。

在仓库根目录运行参考程序：

```bash
lab=curriculum/modules/07-matching/labs/01-one-to-one
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank-l1-first 20261009
cat /tmp/bank-l1-first/report.txt
diff -u "$lab/expected/normal.txt" /tmp/bank-l1-first/report.txt
(cd /tmp/bank-l1-first && sha256sum -c inputs.sha256)
python3 "$lab/scripts/check.py"
```

每次使用新的输出目录。若 `/tmp/bank-l1-first` 已存在，脚本返回 12，保留旧结果。复位时只删除你明确创建的运行目录；测试自动使用临时目录并清理。脚本支持从任何目录启动，参数可以含空格。

`run.sh` 默认使用独立的讲师参考实现，方便先观察业务结果。练习时先将 starter 复制到自己的目录，设置 `COURSE_SOURCE` 后运行同一脚本/验收：

```bash
cp "$lab/starter/MATCH.COB" /tmp/MY-MATCH.COB
export COURSE_SOURCE=/tmp/MY-MATCH.COB
python3 "$lab/scripts/check.py"  # starter 应失败，完成后才应通过
```

starter 能编译但明确返回 12，不伪装成完成的程序。全部参考答案在 `instructor/`，自测时先不要阅读。

## 输入与输出

账户每条 47 字节，交易每条 55 字节，每条之后必须有 LF，LF 不计入宽度。日期为 `20261009`。Copybook 的数字输入先用 PIC X 接收，再判断 IS NUMERIC；不能让无效数据先参加运算。

详细字段见 [DESIGN.md](DESIGN.md)。本课允许空文件、零金额、0000000000 键。账户严格升序；交易账户键严格升序（1:1）。交易 ID 为 16 位大写 ASCII 字母/数字，全局唯一。空行、CRLF、NUL、短/长行、缺少末尾 LF、逆序、重复键、旧营业日及未知版本均返回 8。

输出 `report.txt` 按键顺序列出 `MATCH|account_id`、`MASTER-ONLY|account_id`、`TX-ONLY|account_id`。尾行五个计数依次为账户读入、交易读入、MATCH、MASTER ONLY、TX ONLY，每项补零至 12 位。

正常夹具的手工核算：账户 1/3/5/8；交易 1/2/5/7。共同键 1/5；账户孤立 3/8；交易孤立 2/7。所以 `4=2+2`、`4=2+2`。预期文件是按此集合关系编写，不是程序输出的副本。金额没有改变，原始输入快照随结果保留供后续追踪。

## 逐步实现

1. 画两个读取指针，先手工追踪正常夹具的每一次比较。
2. 定义两个独立 EOF 标志。真实键全零或全 9 都不能用于代替 EOF。
3. 单独实现 read-master/read-transaction，保留原始长度，先校验字段和顺序，再交给比较循环。
4. 一次比较只推进应消费的流；相等时同时推进。EOF 后排空另一侧。
5. 输出三类明细，核对计数等式，检查 CLOSE 状态；成功返回 0。
6. 跑自动验收，再故意把比较分支写反，确认测试能抓住它。

## 修改与故障练习

- 增加账户 0000000000 与 9999999999，分别放在首尾，证明 EOF 不是哨兵键。
- 将最后一条交易改成不存在的账户；提交新的手工 trace 和预期。
- 用 `fixtures/invalid/` 的文件替换对应输入。预期 RC8、无新输出目录；缺失文件预期 RC12。
- 运行期间保留同名 `.lock`，观察 RC12。锁属于正在运行的尝试，不能自动删除别人的锁；进程异常终止后先确认无人运行，再人工清理残留锁。
- 为什么 1:N 不能直接重复运行本课？说明严格升序限制及 L2 需要的 Key Break 状态。

## 插件与纯终端调查

在 `MATCH.COB` 用 `:CobolGotoDef` 跟踪 PERFORM、`:CobolGotoCopybook` 查看 COPY、`:CobolCalcRecord` 估算 47/55 字节；不要用估算替代实测。也可直接 `rg -n 'PERFORM|READ|EOF|COPY'`、`nl -ba`、`od -An -tx1` 完成同样调查。

## 交付与通过条件

提交源码、状态转换表、正常/异常命令及 RC、原始输入 SHA256、报告和两条计数守恒式。使用 [evidence/README.md](evidence/README.md) 记录。通过自动验收并不替代能解释“这一步为什么只推进某一侧”。内存增长检查另见 [pressure.py](scripts/pressure.py)；运行器与数据生成进程不计入 COBOL matcher 的 RSS。
