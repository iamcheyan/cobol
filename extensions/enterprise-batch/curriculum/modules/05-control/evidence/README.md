# 学员证据提交模板（module 05）

复制本文件为自己的 `evidence.md` 并填写，不要覆盖讲师的作者验证记录。

```text
Git commit:
GnuCOBOL version / platform:
Business date:
Command:
Raw process RC:
Fixture SHA256 manifest result:
Published output directory:
Input rows:
Transaction conservation: read = accept + reject =
Amount conservation: sum(accepted balance_demo) =
Accepted status normalisation observed (lower-case in -> canonical out):
Duplicate/reason-priority case and its reason:
Failure fixture (RC8 or RC12), raw RC, and proof no output was published:
Original input hashes unchanged:
05.2 probe results (language-probe / search-all-probe):
Limitation or unexpected result:
```

至少提交：`normal`、一个 RC4 业务拒绝、一个 RC8 契约错误（无发布）以及 `mixed` 的守恒与
金额证据。账号与金额必须从原始夹具和契约独立计算，不能从程序报告反推 expected。
