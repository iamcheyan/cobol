# Enterprise Customer Record Fixtures

All `.dat` files are generated deterministically by [../scripts/generate-fixtures.py](../scripts/generate-fixtures.py). Each record is 1,778 bytes (`ENTERPRISE-CUSTOMER-V1`), with no LF or separators. See [SHA256SUMS](SHA256SUMS) for SHA256 hashes.

- `normal/enterprise-2.dat`: 2 valid records.
- `boundary/enterprise-1.dat`: 1 record; `boundary/enterprise-empty.dat`: 0 bytes.
- `invalid/`: length mismatch (1783B), version `009`, ABI mismatch, and nonnumeric key.

The generator places only a small number of sentinel values at known catalog offsets; it does not compile or run COBOL and therefore is not a source of correct answers for layout validation. The layout is measured independently by the `ADDRESS OF` probe in `../scripts/check.py`.
