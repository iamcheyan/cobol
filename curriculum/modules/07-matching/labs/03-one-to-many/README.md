# 07.4 / Boss L2：有界状态的 1:N 账户入账

建议4小时。先修07.3 L1、文件状态和十进制金额。客户需求：每天一个账户有0到多笔已排序交易；逐笔更新余额、解释拒绝，支持有原交易引用的冲正。完成后能说明Key Break如何收尾、为什么交易ID需全局去重，以及为什么55字节v1无法表达原交易。

## 运行

需要 Linux x86-64、GnuCOBOL 3.2（BDB索引文件支持）、Bash、GNU coreutils、Python 3（仅验收驱动）、`sort`。macOS/WSL未验证。所有文件在新输出目录运行；不覆盖输入或已有输出。参考实现位于instructor，starter可编译但返回12。

```bash
lab=curriculum/modules/07-matching/labs/03-one-to-many
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-run 20261009
rc=$?
set -e
test "$rc" -eq 4   # 本案例含业务拒绝，RC4仍发布完整核对结果
diff -u "$lab/expected/normal.txt" /tmp/bank-l2-run/report.txt
python3 "$lab/scripts/check.py"
python3 "$lab/scripts/check-indexed.py"
```

金额输出使用固定宽度有符号整数。RC4是逐笔业务拒绝、输出经核对仍发布；RC8是接口/排序/全局唯一性错误，RC12是系统故障，二者均无输出目录。跨账户冲正目标是业务拒绝RC4并发布原因，关联文件账户/序号与被指交易不一致则是结构错误RC8且整批不发布。

发布目录包含`report.txt`、完整47字节期末`master.dat`、接收原交易`accepted.dat`、带原因的拒绝原交易`rejected.dat`，以及输入/输出SHA256清单和源码版本摘要。单独查看stdout不能替代正式发布目录。

本机GnuCOBOL BDB运行时对LINE SEQUENTIAL缓冲写入`/dev/full`会出现WRITE/CLOSE状态仍为00、程序返回业务RC4的情况。因此参考核心只允许经`run.sh`作为JOB入口运行：它流式核对report、输入原记录、三类输出、逐户/总金额控制；任何缺行、截断、CRLF或守恒差异都映射RC12且不发布。直接运行构建出的核心程序不具备发布保证。

## 学习路径与可执行任务

按以下顺序完成，每一阶段先预测，再运行命令核对：

1. **人工trace**：阅读`DESIGN.md`微算例，手算normal每笔期末余额；圈出T03引用的T01，并说明T02为何不影响定位。运行`awk '{print NR, length($0)}'`查看行宽，用`od -An -tc`确认LF。
2. **EOF与Key Break**：定位`1000-MAIN`的双指针`EVALUATE`和`4000-CLOSE-ACCOUNT`。画出交易先耗尽、账户无交易、最后账户结束时的指针状态。说明closing为何只能在该组交易消费后产生；对照`boundary-no-transactions`及`boundary-empty-all`的expected。
3. **ledger状态**：查看`1700-INDEX-TRANSACTIONS`的预装、`6000-POST-TX`中的随机`READ`与`REWRITE`。运行`check-indexed.py`观察写读、重复键22、缺键23及打开失败；解释为何账本保存原交易接受/冲正状态，不保存账户组余额。
4. **守恒**：独立核算normal每户`opening + credits - debits = closing`及总控制；检查`boundary-aggregate-over-13`中每户金额合法而全局累计超过13位。预期必须从夹具独立计算，不能复制程序输出。
5. **故障调查**：先复制夹具到临时目录。零金额修改应RC4并输出拒绝原因；篡改REVERSAL-LINK账户应RC8且不发布。比较`run.txt`、`inputs.sha256`和`source.sha256`，确认作业快照与来源证据。

`COURSE_SOURCE`可将可编译starter接入同一runner。starter预期RC12，并验证无输出发布：

```bash
starter=$(realpath "$lab/starter/BATCHL2.COB")
set +e
COURSE_SOURCE="$starter" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-starter 20261009
rc=$?
set -e
test "$rc" -eq 12 && test ! -e /tmp/bank-l2-starter
```

## 构建、验收与复位

```bash
bash "$lab/scripts/build.sh" /tmp/batchl2  # 编译练习；正式作业仍经run.sh发布
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-l2-run
```

`reset.sh`只接受带本课程`run.txt`、`inputs.sha256`、`outputs.sha256`和`report.txt`标记的非符号链接目录，拒绝仓库路径及未标记目录。手动练习先复制夹具，不改fixtures原件。测试中间文件自动清理。

## 业务接口与练习

ACCOUNT仍47字节、TRANSACTION仍55字节；完整政策和人工核算见[DESIGN](DESIGN.md)。冲正单独使用48字节REVERSAL-LINK v1：账户、序号、冲正ID、原交易ID。关联文件不改变公开交易v1。读源码先跟踪两个顺序指针与账户Key Break，再查看临时INDEXED账本的READ KEY/REWRITE；账本用于跨交易ID引用，核心余额仍逐笔顺序算法。

插件路径可用`:CobolGotoDef`看读段；光标放在参考源码的`COPY "ACCOUNT-V1.CPY"`或`COPY "TRANSACTION-V1.CPY"`行执行`:CobolGotoCopybook`检查canonical接口。终端替代为`rg -n 'KEY BREAK|READ|REWRITE|OVERDRAFT|PERFORM'`和`od -An -tc`。练习：新增零金额拒绝断言；再把冲正引用改为已存在的跨账户原交易ID，预期RC4并发布`CROSS-ACCOUNT`；另把关联行的账户改掉，预期RC8且无发布；解释拒绝交易如何保持期末余额与守恒式。

学员交源码、正常逐笔余额表、至少一个失败RC/无发布证据、输入SHA256及计数/金额守恒证据。讲师根因、提示和参考源码在`instructor/modules/07/03-one-to-many/`。
