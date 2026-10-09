# 学员证据提交模板

请复制本文件为自己的 `evidence.md` 并填写，不要覆盖讲师的作者验证记录。

```text
Git commit:
GnuCOBOL version / platform:
Business date:
Command:
Raw process RC:
Fixture SHA256 manifest result:
Published output directory:
Input rows: accounts= / transactions= / reversal-links=
Transaction conservation: read=accepted+rejected=
Account conservation: accounts=has-transactions+no-transactions=
Amount conservation per account (include one worked account):
Global opening + accepted credits - accepted debits = closing:
Reversal target and its state before/after:
Failure fixture, raw RC, and proof no output was published:
Original input hashes unchanged:
Limitation or unexpected result:
```

至少提交 normal、一个RC4业务拒绝、一个RC8无发布，以及aggregate-over-13证据。账号与金额必须从原始夹具和契约独立计算，不能从报告反推expected。
