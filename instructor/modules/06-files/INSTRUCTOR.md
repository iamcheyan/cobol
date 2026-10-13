# 模块 06 讲师参考（instructor）

参考实现：`FILEVAL.COB`（本目录）。学员起始代码：
`curriculum/modules/06-files/starter/FILEVAL.COB`（可编译，返回 RC12 且不发布）。

## 评分点

| 项 | 分值 | 通过标准 |
|---|---:|---|
| 逐字节读取与文件状态 | 20 | OPEN/EOF 状态正确；短/长/CRLF/缺 LF 都 RC8 不发布 |
| 定长 vs LINE SEQUENTIAL | 10 | 能说明 LF 存在但不计入逻辑宽度并给出实测 |
| 字段级分类与优先级 | 25 | 原因码与 DESIGN 逐字一致，优先级正确 |
| 输入控制总数与守恒 | 20 | READ=ACCEPT+REJECT；BALANCE 精确 |
| 缺失/空文件政策 | 10 | 空文件 RC0；缺失 RC12 不发布 |
| 06.4 索引/相对阅读实验 | 15 | 记录真实状态码与跨进程锁边界 |

## 根因参考（可复现故障）

- **缺失文件**：`OPEN INPUT` 返回 `35`（file not found），程序映射 RC12，不发布。
- **空文件 vs 缺失**：空文件首次 `READ` 返回 `10`（EOF），合法 0 条；缺失文件在 `OPEN` 就失败。
- **layout 版本**：`002` 触发 RC8，而非逐笔拒绝——接口版本不符是整批契约错误。
- **重复 vs 逆序**：等于上一条是 `DUPLICATE-ID`（RC4）；小于上一条是 `UNSORTED-INPUT`（RC8）。
- **跨进程锁**：默认 GnuCOBOL/BDB 不互斥，第二个进程仍能打开同一索引文件（`00`）；必须由
  JOB 层 `.lock` 目录保证单实例。不要把它误当作文件系统独占锁。
- **LINE SEQUENTIAL 陷阱**：它会吞掉换行，使超长/CRLF 无法在逻辑宽度上暴露。

## 提示阶梯

1. 先跑 `normal`，比对 report/expected 与 filestatus.log。
2. 再跑 `mixed` 核对原因优先级与 BALANCE。
3. RC8 时先读 stderr 原因码，判断是长度、换行、排序还是 layout。
4. 复位前 `sha256sum -c inputs.sha256`；确认失败案例没有发布目录。

## 已知限制

仅 Linux x86-64 + GnuCOBOL 3.2（BDB）实测。金额为最小单位整数，不做小数换算。运行时的
`libcob: warning` 是环境噪声。
