# Module 02 Synthetic Inputs

All files are ASCII text, LF-terminated, with 27 bytes per logical record (the same as CUSTOMER v1 in the
[bank system design](../../../../docs/curriculum/BANK-SYSTEM.md)); LF is not counted in the record length. The name field is restricted to ASCII first, to avoid mistaking character count for byte count. Rebuild deterministically with
`python3 scripts/generate-fixtures.py`; this script generates bytes only and does not implement load/validation logic.
`SHA256SUMS` covers every file in this directory.

| Path | Purpose | Expected |
|---|---|---|
| `normal/customer.dat` | 3 valid customers (both A/D statuses) | RC0, all accepted, balance total 10012394 |
| `boundary/empty.dat` | 0 bytes (empty file allowed) | RC0, 0 records read |
| `boundary/single.dat` | Only one record (the final record) | RC0 |
| `boundary/max-balance.dat` | `balance_demo` at the 8-digit maximum, 99999999 | RC0 |
| `boundary/name-full.dat` | Name is exactly 10 characters | RC0 |
| `boundary/no-final-lf.dat` | Missing LF after the final record | RC8, no publish |
| `invalid/short.dat` | 26-byte short record | RC8, no publish |
| `invalid/long.dat` | 28-byte long record | RC8, no publish |
| `invalid/crlf.dat` | Record line ends with CRLF | RC8, no publish |
| `invalid/bad-id.dat` | Customer ID contains non-digits | RC8, no publish |
| `invalid/duplicate-id.dat` | Two identical customer IDs | RC8, no publish |
| `invalid/unsorted.dat` | Customer IDs in descending order | RC8, no publish |
| `invalid/name-missing.dat` | Name consists entirely of spaces | RC4, reason `NAME-MISSING` |
| `invalid/bad-amount.dat` | `balance_demo` contains non-digits | RC4, reason `BAD-AMOUNT` |
| `invalid/unknown-status.dat` | Status is Z | RC4, reason `UNKNOWN-STATUS` |
| `types/typeinput.dat` | Type experiment input: three 5-byte records, `ABCDE`/`AB123`/`AB CD` | `TYPESLAB` matches `expected/typeslab.txt` byte for byte |

RC8 fixtures have no formal expected report because the contract requires the entire batch to fail without publishing an output directory. Never rewrite source fixtures in the runner.
`types/typeinput.dat` is line-oriented input with 5 bytes per record for `experiments/types/TYPESLAB.COB`; it is not part of the CUSTOMER v1 27-byte contract.
