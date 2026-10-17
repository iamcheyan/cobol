# Module 06 synthetic fixtures

All files are ASCII ACCOUNT v1 files terminated by LF; each logical record is 47 bytes, **excluding LF**. The fixed business date is `20261009`. Rebuild deterministically with `python3 scripts/generate-fixtures.py` (this generates data only; it does not implement validation). `SHA256SUMS` covers every fixture, and `check.sh` verifies checksums before and after execution; the runner never rewrites originals.

| Directory | Fixture | Purpose |
|---|---|---|
| normal | `valid.dat` | 3 valid records (+1000 A / +50 F / -500 C), BALANCE=550 |
| boundary | `empty.dat` | Zero-byte file (valid, READ=0) |
| boundary | `single.dat` | One record |
| boundary | `negative-balance.dat` | Negative opening balance `-9999999999999` |
| boundary | `zero-balance.dat` | Opening balance 0 |
| invalid | `bad-account-id.dat` | Account ID is not numeric → BAD-ACCOUNT-ID |
| invalid | `bad-customer-id.dat` | Customer ID is not numeric → BAD-CUSTOMER-ID |
| invalid | `unknown-currency.dat` | Currency `USD` → UNKNOWN-CURRENCY |
| invalid | `bad-sign.dat` | Sign `*` → BAD-SIGN |
| invalid | `bad-balance.dat` | Balance is not numeric → BAD-BALANCE |
| invalid | `bad-date.dat` | `20260230` is not a calendar date → BAD-DATE |
| invalid | `date-mismatch.dat` | `20261008` ≠ business date → DATE-MISMATCH |
| invalid | `unknown-status.dat` | Status `Z` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | Adjacent duplicate account ID → DUPLICATE-ID on the second record |
| invalid | `mixed.dat` | Mix of accepted/rejected records, demonstrating conservation and priority |
| invalid | `bad-layout.dat` | Layout `002` → RC8, no publication |
| invalid | `unsorted.dat` | Account IDs out of order → RC8 |
| invalid | `short-record.dat` | Logical record shorter than 47B → RC8 |
| invalid | `long-record.dat` | Logical record longer than 47B → RC8 |
| invalid | `no-trailing-lf.dat` | Final record has no LF → RC8 |
| invalid | `crlf.dat` | CRLF line ending → RC8 |

Business-rejection fixtures return RC4 with rejection details published by design; structural/contract errors return RC8 without publication. There is no missing-file fixture; `run.sh` receives a nonexistent path to trigger RC12.
