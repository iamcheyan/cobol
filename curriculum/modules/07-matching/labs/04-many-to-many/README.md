# Boss L3：客户日汇总与四流归并

本课把已验收的 L2 账务结果与客户日快照、前一日控制数据核对。一个客户可以有多个账户和多笔交易。账户和交易都只归属一个客户；分别按客户汇总账户余额、账户数、accepted 收付金额和笔数。这里的 N:N 表示多个账户与多笔交易共享一个客户汇总键，**不**产生账户×交易笛卡尔积，也不把客户余额复制到各账户。

L2 仍是账务事实来源。官方 runner 先把原始 ACCOUNT、TRANSACTION、REVERSAL-LINK 交给 B01 L2，保留 accepted、rejected、完整 closing master 和报告，再运行本课核心。L3 不重复记账，也不更新数据库。Snapshot 是离线种子数据；真正的数据库抽取和更新属于模块08。

账户按 account_id 排列时 customer_id 可以跳回：账户1→客户2、账户2→客户1、账户3→客户2。因而必须先在 COBOL 中生成带 customer_id 的磁盘排序流，再归并 ACCOUNT、accepted TX、Snapshot、Previous 四个流。每次只保留四个游标、当前记录和固定精度累计器；客户组暂存到磁盘 spool，组末才决定 eligible 或隔离。

## 字段与政策

打开 [DESIGN](DESIGN.md) 与 [FIELD-CATALOG](FIELD-CATALOG.md)，再用 `:CobolGotoCopybook` 跳到本课真实的 `CUSTOMER-SNAPSHOT-V1.CPY` 和 `PREVIOUS-DAY-V1.CPY`。ACCOUNT v1 是 canonical 47B，TRANSACTION v1 是 canonical 55B且没有布局版本字段；Snapshot v1 为36B，Previous-Day v1为39B。所有记录必须 ASCII 固定宽度并以 LF 结束。日期用真实 Gregorian 日历；Previous 是前一日历日，不套用银行营业日历。

每个完整客户组核对：客户账户数与前日账户数一致；当前期初与前日 closing 一致；`expected closing = previous closing + L2 accepted credit - L2 accepted debit`；重算 closing 与 L2 closing master 汇总一致；账户数和 closing 不超过 snapshot 控制值。账户数/余额包括 A、F、C 全部账户状态。L2 rejected 单独保留，不计入 accepted 金额。

缺 Snapshot/Previous、客户D、账户数/余额业务差异返回 RC4，并把关联账户/accepted交易按原始47B/55B字节及原因写入隔离文件。缺失行等孤儿 Snapshot/Previous 也必须记录原始36B/39B来源。结构错误（无LF、CRLF、错误宽度、错误日期/版本、重复或逆序键）返回 RC8且不发布。工具、权限、排序盘、核验、锁和发布异常映射RC12且不发布。RC4 仍可发布其他通过客户，但下游必须排除隔离文件。

全局控制分别满足：原ACCOUNT数=eligible master数+isolated account数；L2 accepted数=eligible accepted TX数+isolated accepted TX数；accepted credit和debit分别等于eligible与isolated金额之和；opening+credit-debit=closing。L2 rejected count单列。

## 学习路径

1. 先人工追踪 `fixtures/normal`：按账户读到客户顺序2、1、2；记下客户1的2,000−100=1,900与客户2的4,000+120−20=4,100。用 `expected/normal-master.dat` 和 `expected/normal-customer-totals.csv` 对照；从仓库根目录执行`(cd curriculum/modules/07-matching/labs/04-many-to-many && sha256sum -c SHA256SUMS)`。
2. 阅读参考源 `instructor/modules/07/04-many-to-many/BATCHL3.COB` 的 `1300-SORT-ACCOUNTS`、`1400-SORT-TRANSACTIONS`、`1500-RUN-FOUR-WAY`、`1550-RESET-GROUP`、`1580-DECIDE-GROUP`、`1590-REPLAY-SPOOL`。本表按真实程序阶段记录每次READ后的游标：组开始时选择四流最小customer key；程序先把该客户全部ACCOUNT读到组末，再把全部accepted TX读到组末，然后分别读取匹配Snapshot和Previous各一次，最后才决定/重放spool。表中游标一律表示该阶段READ完成后的当前记录；未变化的流保持原位置。原ACCOUNT的customer序列是2,1,2；按customer/account排序后account IDs为2,1,3。accepted TX客户序列为`01:T003`、`02:T001,T002,T004`。

| ordinal | 本阶段消费的记录 | A当前 | T当前 | S当前 | P当前 | 组内累计或决定 |
|---:|---|---|---|---|---|---|
| 0 | 初始READ | 01:A02 | 01:T003 | 01:S01 | 01:P01 | 最小组键01 |
| 1 | 消费A02后READ | 02:A01 | 01:T003 | 01:S01 | 01:P01 | 客户01：账户2 opening 2000 |
| 2 | 消费T003后READ | 02:A01 | 02:T001 | 01:S01 | 01:P01 | 客户01：T003借100 |
| 3 | 消费S01后READ | 02:A01 | 02:T001 | 02:S02 | 01:P01 | 客户01 snapshot已消费一次 |
| 4 | 消费P01后READ；决定01 | 02:A01 | 02:T001 | 02:S02 | 02:P02 | 2000−100=1900；完成客户01 |
| 5 | 消费A01后READ | 02:A03 | 02:T001 | 02:S02 | 02:P02 | 客户02：账户1 opening 1000 |
| 6 | 消费A03后READ | EOF | 02:T001 | 02:S02 | 02:P02 | 客户02：账户3 opening 3000；账户流EOF |
| 7 | 消费T001后READ | EOF | 02:T002 | 02:S02 | 02:P02 | 客户02：贷50 |
| 8 | 消费T002后READ | EOF | 02:T004 | 02:S02 | 02:P02 | 客户02：借20 |
| 9 | 消费T004后READ | EOF | EOF | 02:S02 | 02:P02 | 客户02：贷70；交易流EOF |
| 10 | 消费S02后READ | EOF | EOF | EOF | 02:P02 | 客户02 snapshot已消费一次 |
| 11 | 消费P02后READ；决定02 | EOF | EOF | EOF | EOF | 4000+贷120−借20=4100；完成客户02 |

ACCOUNT/TX两个循环分别消费当前客户的所有记录；不会在A03和T001/T002/T004之间逐笔配对。客户02最终有2账户、3交易；每笔交易先归属ACCOUNT，再随account.customer_id进入客户汇总，不重复记金额，也不生成笛卡尔积。
3. 自己建立工作副本并运行starter，确认它按TODO返回RC12、没有发布。先只实现四游标比较和EOF状态，手工trace每次READ；再添加客户spool和组末重放；最后添加金额公式、客户差异隔离和控制守恒。每个阶段用reference对照，不要一次把预期结果硬编码进学生程序。
4. 在独立工作副本把账户1的customer_id从02改为01，保持原交易仍按账户归属；更新快照/前日行并独立计算。检查客户01/02金额是否只按其账户聚合一次，没有客户余额复制。然后移除客户01 snapshot：客户01的account/TX来源应按原字节隔离，客户02仍可发布，JOB为RC4。
5. 将某Snapshot日期改旧、移除最后LF、或复制一条snapshot key：结构错误应为RC8且无目标目录。用 `python3 scripts/check.py` 查看每个永久案例，再用 `bash scripts/check.sh` 运行全部业务/原字节/starter/reset/fixture校验。

## 构建、运行、检查、复位

```bash
lab=curriculum/modules/07-matching/labs/04-many-to-many
bash "$lab/scripts/build.sh" /tmp/batchl3
python3 "$lab/scripts/check.py"
bash "$lab/scripts/check.sh"
```

正式运行会创建锁和隔离暂存目录，做输入快照，运行B01，再运行本课COBOL，外部 `sort` 只把候选输出重排到下游既定的 account/sequence/id 字节序。候选经独立磁盘SQLite oracle逐流核对后才发布。常规教学命令：

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
work=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$work/"
cd "$work"
bash "$lab/scripts/run.sh" account.dat transaction.dat \
  reversal-link.dat customer-snapshot.dat previous-day.dat \
  output-20261009 20261009
cd - >/dev/null
(cd "$work/output-20261009" && sha256sum -c inputs.sha256 \
  && sha256sum -c manifest.sha256)
```

普通无差异批次RC0；L2或客户业务隔离RC4且目录已发布；结构错误RC8无目录；系统错误RC12无目录。所有正式输出写在新目录，目标已经存在时拒绝覆盖。`COURSE_SOURCE=/绝对路径/BATCHL3.COB` 可指定学员源码；该覆盖只用于B03，L2仍运行已验收参考实现。

Starter 使用独立源：

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
student=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$student/"
cp "$lab/starter/BATCHL3.COB" "$student/BATCHL3.COB"
if COURSE_SOURCE="$student/BATCHL3.COB" bash "$lab/scripts/run.sh" \
  "$student/account.dat" "$student/transaction.dat" \
  "$student/reversal-link.dat" "$student/customer-snapshot.dat" \
  "$student/previous-day.dat" "$student/result" 20261009; then
  starter_rc=0
else
  starter_rc=$?
fi
[[ $starter_rc == 12 && ! -e $student/result ]]
```

它应返回12且不创建result。完成TODO后再检查。`scripts/init-workspace.sh DIR` 仅给空目录写入工作区标记；`scripts/reset.sh DIR` 只重置带标记且没有任何运行锁的工作区。任意锁存在都会返回12并保留全部文件。

## 练习验证

尝试下列练习，每次保留命令、原始RC、输出manifest、核心stdout/stderr和fixture hash：

| 练习 | 预期 | 验证点 |
|---|---|---|
| Snapshot余额限额恰为4100 | RC0 | 等于上限允许 |
| 上限改为4099 | RC4 | 只隔离客户02 |
| 缺客户01 Snapshot | RC4 | 客户02 eligible，客户01来源原字节隔离 |
| Previous closing改4001 | RC4 | opening mismatch，拆分金额仍守恒 |
| Snapshot日期改旧日 | RC8 | 全批无发布 |
| customer_id重复或逆序 | RC8 | 不得覆盖旧输出或发布候选 |

## 故障调查顺序

先看runner原始RC，再看候选阶段：RC4要检查`customer-status.txt`、`isolation.txt`与control拆分；RC8先核对原始LF/宽度、日期、版本和customer键序；RC12查看stderr中的构建、排序、临时目录、锁、独立核验或发布失败。`run.sh`失败时自动清理私有stage与锁，正式输出目录不应出现。若目录已成功发布，用 `sha256sum -c inputs.sha256` 证明输入快照一致，再用 `sha256sum -c manifest.sha256` 检查输出文件；这些hash用于完整性检查，业务正确性由独立oracle和control等式检查。

终端替代编辑器插件：`rg -n '1500-RUN-FOUR-WAY|1580-DECIDE-GROUP|1590-REPLAY-SPOOL' instructor/modules/07/04-many-to-many/BATCHL3.COB`，用 `od -An -tc` 查看实际行尾和字节。插件跳转只指向这里实际存在的段落及本课COPY。
