# Synthetic Inputs for Module 01

All files are ASCII text terminated by LF; each logical record is 47 bytes (the same as ACCOUNT v1 in the
[banking system design](../../../../docs/curriculum/BANK-SYSTEM.md)); LF is not counted in the record length. The fixed business date is 20261009. Fixtures can be
recreated deterministically with `python3 scripts/generate-fixtures.py`; this script only generates bytes and does not implement any batch-processing logic.
`SHA256SUMS` covers every file in this directory.

| Path | Purpose | Expected |
|---|---|---|
| `normal/account.dat` | 3 valid accounts (the three statuses A/F/C) | RC0, all accepted |
| `boundary/empty.dat` | 0-byte input (an empty file allowed by the contract) | RC0, read 0 records |
| `boundary/single.dat` | Only one record (the last record) | RC0, read 1 record |
| `boundary/no-final-lf.dat` | Missing LF after the last record | RC8, no publication |
| `invalid/short.dat` | 46-byte short record | RC8, no publication |
| `invalid/long.dat` | 48-byte long record | RC8, no publication |
| `invalid/crlf.dat` | Record line ends with CRLF | RC8, no publication |
| `invalid/bad-id.dat` | Account contains a non-digit character | RC8, no publication |
| `invalid/bad-layout.dat` | Layout version is 002 | RC8, no publication |
| `invalid/bad-date.dat` | Record date does not match the business date | RC8, no publication |
| `invalid/duplicate-id.dat` | Two records with the same account (duplicate key) | RC8, no publication |
| `invalid/unsorted.dat` | Accounts are in descending order | RC8, no publication |
| `invalid/unknown-status.dat` | Status is the unknown value Z | RC4, rejected detail is published |

RC8 fixtures have no formal report in `expected/` because the contract requires the entire batch to fail and no output directory to be published.
See `expected/unknown-status.control.txt` for the business-rejection fixture. Never rewrite source fixtures in the runner.
