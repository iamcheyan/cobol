# 学员证据提交模板

复制本文件为自己的 `evidence.md` 并填写；不要覆盖讲师的作者验证记录或 fixtures 原件。

```text
Git commit:
GnuCOBOL version / platform (uname -m):
Business date:
Command (run.sh, exact args):
Raw process RC:
Failure fixture, raw RC, and proof no output directory was published:
Published output directory (and its inputs.sha256 / outputs.sha256 check result):
Input rows: customers= / accounts= / transactions=
Customer conservation: READ = OK + REJECT =
Transaction conservation: TX = ACCEPT + REJECT =
Account conservation: ACCOUNTS = NOTX + (accounts with transactions) =
Amount conservation per account (show one worked account, opening+credit-debit=closing):
Global OPENING + CREDIT - DEBIT = CLOSING =
Interface experiment: version mismatch RC/reason, length mismatch RC/reason:
Workspace lifecycle: static CALL1/CALL2 and INITIAL CALL1/CALL2 from ifaceprobe:
Interface version/length you sent to each module (and why LENGTH OF, not a magic number):
Original input hashes unchanged:
Limitation or unexpected result:
```

至少提交：normal 报告与 `ledger.dat`；一个 RC4（发布）用例；一个 RC8 或 RC12（不发布）用例；
`ifaceprobe` 的字节/RC 输出；输入与输出 SHA256 校验结果。账号与金额必须从原始夹具和
DESIGN 契约独立演算，不能从已生成的报告反推 expected。
