# P1 / L1 验收记录

日期：2026-10-09。源码/材料与本证据同一提交发布；旧course工作区补丁未纳入本阶段。

环境：Debian 13、Linux x86-64、glibc2.41、GnuCOBOL3.2、GNU coreutils9.7、Python3.13；4逻辑CPU、约15.6GiB内存。Docker隔离测试PostgreSQL17.11、GixSQL1.0.21dev，源码commit及两项补丁见数据库README。

## 实际执行

- `bash curriculum/check.sh`：字节23B逐字节一致、24个原型用例、L1十个测试方法（包含EOF/异常子用例）、夹具SHA256、72列格式检查通过。原始输出见local-check.txt。
- `bash curriculum/validation/database/check.sh`：真实SELECT NULL、无结果、两条游标、EOF、23505、回滚100、提交101、独立psql101、错误连接RC12、仍打开游标COMMIT后重开均通过。
- `python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py`：每侧1万/10万/100万条，逐行验证全部MATCH与计数；0.396/3.714/36.356秒，wait4返回的子进程最大RSS为12600/12892/12892KiB。完整测量见JSON。

RSS包含子进程整个生命周期，可能包含启动开销；不是只测COBOL工作区。运行器、数据生成器未计入被等待进程。此结果只证明本环境这些档位没有随行数线性增长，不是生产容量或跨平台承诺。性能回归粗门槛为最大RSS不超过首档+16MiB。

从Git暂存区导出独立临时checkout后，再次运行本地检查和Docker数据库检查均通过；没有读取未暂存的旧course补丁。

## 修复前失败证据

- 交易ID含NUL曾返回0；新增异常断言先失败，再增加A–Z/0–9逐字节验证。
- 预建目标.lock曾仍发布；新增断言先失败，再增加独占mkdir锁。
- 非约定RC3曾直接外传；新增断言先失败，再归一为RC12并保留原码诊断。
- 独立审查复现并发空目录被mv替换；改为no-clobber并检查是否实际移动，现有回归验证目录仍为空、RC12。
- 未修补GixSQL FETCH的NULL指示器为0；最小游标NULL补丁后变为-1。
- 第一项补丁后程序显示COMMIT=101，但独立psql为100；根因为重复CLOSE已关闭游标导致事务中止。第二项补丁后独立连接为101。

## 源码校验和

```text
bcf49b761af7439c1054108b495fc31722620884fa48217c1220d434e0508bb2  instructor/modules/07/01-one-to-one/MATCH.COB
c2153501e2cec9a3701da84bc616b77d84ccc3da4f99a24bd8e79e3bfb7ead8d  curriculum/bank/copybooks/ACCOUNT-V1.CPY
5c4371d69985d153bb791a46b452ed1ab2b14bfa8e1d0c6586fa5eb1beb568a2  curriculum/bank/copybooks/TRANSACTION-V1.CPY
3254e4a30670fc2a1dd6a320a4c01a79d4d33102a689264dbb4e88c04863a19b  curriculum/validation/database/PROBE.COB
1c7f8e27387130505cea2f7178f2e74f8ac4430c5f5b689dc9feb48f9b050195  curriculum/validation/database/gixsql-closed-cursor.patch
0b899724d8857165c1df23e85a714da513bb93815b7a472039e3cb5c5ef0536f  curriculum/validation/database/gixsql-cursor-null.patch
```

## 范围限制

本记录不代表完整模块07/08通过。L2/L3/L4、SORT/MERGE教学、坏Packed解析、DB幂等与崩溃恢复、其他平台以及其余模块仍待实施。GixSQL为带本地修补的固定候选，不宣称未修改上游兼容。libxml运行版本提示未隐藏，见原始日志。
