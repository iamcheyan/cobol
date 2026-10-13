# 模块 05 讲师参考（instructor）

参考实现：`CLEANSE.COB`（本目录）。学员起始代码：
`curriculum/modules/05-control/starter/CLEANSE.COB`（可编译，返回 RC12 且不发布）。

## 评分点

| 项 | 分值 | 通过标准 |
|---|---:|---|
| 逐字节读取与长度/CRLF/缺 LF 检测 | 20 | 四类都 RC8 且不发布，`MISSING-FINAL-LF` 等消息出现 |
| 状态规范化与 SEARCH ALL 前提 | 15 | 小写 `a/d` 归一为 `A/D`；表按 A<D 排序 |
| 必填/金额范围/原因分类与优先级 | 25 | 与 DESIGN 原因目录逐字一致，优先级正确 |
| 守恒与控制总数 | 20 | READ = ACCEPT + REJECT；AMOUNT 精确等于接收金额之和 |
| 失败不发布与夹具保护 | 10 | RC8/12 无输出目录；fixtures 哈希不变 |
| 05.2 语言微实验 | 10 | 两个 probe 输出与断言一致 |

## 根因参考（可复现故障）

- **缺末尾 LF**：读取循环在 `STATUS='10'` 且 `RAW-SIZE>0` 时报 `MISSING-FINAL-LF`。若学员用
  `LINE SEQUENTIAL` 会看不到这一错误——这正是本课的考点。
- **CRLF**：逐字节读到 `X'0D'` 立即 RC8；`LINE SEQUENTIAL` 会吞掉 `\r` 造成静默差异。
- **重复 vs 逆序**：数字 ID 等于上一条是业务拒绝 `DUPLICATE-ID`（RC4）；小于上一条是契约
  错误 `UNSORTED-INPUT`（RC8）。学员常把二者混为一谈。
- **SEARCH ALL 陷阱**：把状态表写成未排序仍能编译，但二分搜索会漏掉存在的键（见
  `scripts/search-all-probe.COB` 的 `UNSORTED=MISS`）。

## 提示阶梯

1. 先跑 `normal`，只看 report 是否与 expected 对齐。
2. 再跑 `mixed`，用期望表核对原因优先级与守恒。
3. 遇到 RC8 时先读 stderr 的原因码，再决定是长度、换行还是排序问题。
4. 复位前用 `sha256sum -c inputs.sha256` 确认输入快照未变。

## 已知限制

仅 Linux x86-64 + GnuCOBOL 3.2 实测。金额上限 50,000,000 是本课合成政策。运行时的
`libcob: warning`（libxml 版本提示）是环境噪声，与业务结果无关。
