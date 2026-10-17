# Module 05 synthetic fixtures

All files are ASCII CUSTOMER v1 files terminated by LF; each logical record is 27 bytes, **excluding LF**. The fixed business date is `20261009`. Rebuild deterministically with `python3 scripts/generate-fixtures.py` (this generates data only; it does not implement cleansing). `SHA256SUMS` covers every fixture, and `check.sh` verifies the checksums before and after execution; the runner never rewrites the originals.

| Directory | Fixture | Purpose |
|---|---|---|
| normal | `clean.dat` | 3 fully valid records, including normalization of lowercase status `a` |
| boundary | `empty.dat` | Zero-byte file (valid, READ=0) |
| boundary | `single.dat` | One record |
| boundary | `min-amount.dat` | Minimum amount 0 |
| boundary | `max-amount.dat` | Maximum amount 50,000,000 (inclusive) |
| invalid | `missing-name.dat` | Required name is blank → MISSING-NAME |
| invalid | `bad-id.dat` | ID is not numeric → MISSING-ID |
| invalid | `non-numeric-amount.dat` | Amount is not numeric → BAD-AMOUNT |
| invalid | `amount-over-cap.dat` | Amount exceeds the limit → AMOUNT-RANGE |
| invalid | `unknown-status.dat` | Status `X` → UNKNOWN-STATUS |
| invalid | `duplicate-id.dat` | Adjacent duplicate ID → DUPLICATE-ID on the second record |
| invalid | `mixed.dat` | Mix of accepted and rejected records, demonstrating conservation and reason priority |
| invalid | `unsorted.dat` | IDs out of order → RC8, no publication |
| invalid | `short-record.dat` | Logical record shorter than 27B → RC8 |
| invalid | `long-record.dat` | Logical record longer than 27B → RC8 |
| invalid | `no-trailing-lf.dat` | Final record has no LF → RC8 |
| invalid | `crlf.dat` | CRLF line ending → RC8 |

Business-rejection fixtures (the business cases among the invalid fixtures above) return RC4 and publish rejection details by design. Structural/contract errors return RC8 and are not published.
