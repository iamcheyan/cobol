# 学员证据提交模板

请复制本文件为自己的 `evidence.md` 并填写，**不要**预填通过结果，也不要覆盖讲师的作者
验证记录（`evidence/` 下的 `AUTHOR-*.md`）。

```text
Git commit:
GnuCOBOL version / platform:
Command(s) run:
Raw process RC (each command):
Fixture SHA256 manifest result (sha256sum -c SHA256SUMS):
Published output directory:
control.txt content:
Conservation: READ = ACCEPTED + REJECTED = ; BALANCE-TOTAL = (hand sum):
CUSTOMER v1 field catalog (offset/length/PIC/unit/legal values):
One RC8 fixture: name / raw RC / proof no output directory was created:
MOVE experiment table with the rule for each of A-I:
Types experiment (PIC A / 78 / 77 / 88 / group) result + why AB123 is M:
Numeric MOVE to PIC A compile result (must fail):
Layout experiment: canonical record length / off-by-one record length:
Original fixture hashes unchanged (yes/no + how checked):
Limitation or unexpected result:
```

必须包含：一次 RC0 正常、一次 RC4 业务拒绝、一次 RC8 无发布、MOVE 实验表、类型实验
（`TYPESLAB`）结果与 `PIC A`/`78`/`77`/`88` 的观察、布局实验结论。
字段目录与金额必须从原始夹具与 DESIGN 契约独立核算，不能从程序输出反推 expected。以下情况
判为失败：

- `check.sh` / `check.py` 未通过，或与断言不符；
- RC8 夹具产生了任何输出目录；
- 源夹具 SHA256 在执行后发生变化；
- 把 CUSTOMER v1 的 27 字节改成了别的长度，或把程序当前输出当作 `expected/`。
