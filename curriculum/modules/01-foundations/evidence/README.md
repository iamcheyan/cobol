# 学员证据提交模板

请复制本文件为自己的 `evidence.md` 并填写，**不要**预填通过结果，也不要覆盖讲师的作者
验证记录（`evidence/` 下的 `AUTHOR-*.md`）。

```text
Git commit:
GnuCOBOL version / platform:
Business date:
Command(s) run:
Raw process RC (each command):
Fixture SHA256 manifest result (sha256sum -c SHA256SUMS):
Published output directory:
control.txt content:
Conservation: READ = ACCEPTED + REJECTED =
One RC8 fixture: name / raw RC / proof no output directory was created:
Column truncation experiment: TRUNC-BAD result / TRUNC-GOOD result / first 72-column diff:
src-to-executable evidence (file/ldd/readelf summary):
Original fixture hashes unchanged (yes/no + how checked):
Limitation or unexpected result:
```

必须包含：一次 RC0 正常、一次 RC4 业务拒绝、一次 RC8 无发布、列截断前后对比，以及
`env-report.sh` 的环境/可执行证据。控制报告与计数必须从原始夹具和 DESIGN 契约独立核算，
不能从程序输出反推 expected。以下情况判为失败：

- `check.sh` / `check.py` 未通过，或与断言不符；
- RC8 夹具产生了任何输出目录；
- 源夹具 SHA256 在执行后发生变化；
- 把某个程序的当前输出直接当作 `expected/`。
