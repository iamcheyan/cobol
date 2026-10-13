# 学员证据提交模板（module 06）

复制本文件为自己的 `evidence.md` 并填写，不要覆盖讲师的作者验证记录。

```text
Git commit:
GnuCOBOL version / platform (cobc -info indexed handler):
Business date:
Command:
Raw process RC:
Fixture SHA256 manifest result:
Published output directory:
Input rows:
Conservation: read = accept + reject =
Balance conservation: signed opening_balance sum =
File status evidence (OPEN/EOF codes from filestatus.log):
Missing-file case: raw RC and proof no output was published:
Contract-error case (RC8) and its stderr reason:
Original input hashes unchanged:
06.2 line-vs-fixed byte observation (raw bytes incl. LF):
06.4 indexed statuses observed (WRITE/DUP/READ/REWRITE/DELETE/REOPEN/MISS-OPEN):
06.4 relative statuses observed and applicability boundary:
Limitation or unexpected result:
```

至少提交：`normal`、一个 RC4 字段拒绝、一个 RC8 契约错误（无发布）、缺失文件 RC12（无发布）、
`mixed` 的守恒与 `BALANCE` 证据，以及 06.2/06.4 的原始状态码。计数与金额必须从原始夹具和
契约独立计算，不能从程序报告反推 expected。
