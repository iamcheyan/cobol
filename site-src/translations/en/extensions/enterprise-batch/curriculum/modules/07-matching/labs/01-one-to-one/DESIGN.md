# L1 interface and state design

## Input interfaces

Canonical Copybooks are under `curriculum/bank/copybooks/`. Read every field as text first and convert only after numeric validation. The layout matches the [global contract](../../../../../docs/curriculum/BANK-SYSTEM.md).

| File | Fields and positions (1-based) | Validation in this lesson |
|---|---|---|
| ACCOUNT | ID 1–10, customer 11–18, currency 19–21, sign 22, balance 23–35, status 36, date 37–44, version 45–47 | Numeric ID/customer/amount; JPY; +/-; A/F/C; date=job date; 001 |
| TRANSACTION | account 1–10, transaction ID 11–26, date 27–34, sequence 35–40, direction 41, amount 42–54, status 55 | Numeric key/sequence/amount; ID A–Z/0–9; date=job date; C/D; N |

This lesson classifies only; frozen/closed accounts can still MATCH, which does not mean they may be posted to. Zero amount is valid. Amounts are integer minor units, initially JPY; do not invent two legal decimal places for JPY. Input requires strict LF; missing final LF is an interface error.

Raw-byte input uses SEQUENTIAL one-byte records and checks LF before filling bounded buffers. This avoids LINE SEQUENTIAL normalization of short rows, NUL, Tab, or CR. Reject a row immediately if it exceeds its width; reject unterminated bytes at EOF. Read operations grow linearly with input bytes and cost more than block reading; see the pressure report for measured performance.

## Comparison states

| M EOF | T EOF | Other condition | Output | Advance |
|---|---|---|---|---|
| No | No | M=T | MATCH | M, T |
| No | No | M<T | MASTER ONLY | M |
| No | No | M>T | TX ONLY | T |
| Yes | No | None | TX ONLY | T |
| No | Yes | None | MASTER ONLY | M |
| Yes | Yes | None | Reconcile counts and finish | None |

Check EOF before comparing keys; stale buffer contents have no meaning after EOF. Every validated record enters exactly one category. Keys are fixed-width ASCII digits, so lexical order equals numeric order without binary conversion.

## Responsibilities and RC

COBOL checks dates, raw widths, fields, account-key sorting/uniqueness, the three-way sequential match, and input counts. Shell uses SORT/uniq to check global transaction ID uniqueness, avoiding storage of every transaction ID in COBOL; this does not replace the core matching algorithm with an external tool.

| RC | Meaning in this lesson | Publish |
|---|---|---|
| 0 | All inputs valid; classification and counts reconcile | One directory rename |
| 8 | Interface/business-data error | No |
| 12 | File/build/lock/environment failure | No |

This lesson does not use RC4; orphan records are normal classifications. Shell input/output system-call failures must map to RC12. COBOL stdout may already contain candidate rows before a later error is found, so stage it; never treat stdout directly as the official report.

The run directory keeps input copies, checksums, compiler version, source checksum, business date, and report; original files are never modified. A new directory is this lesson's simplified run_id. A directory lock prevents concurrent publication to one target, and existing output is rejected. There is no DB commit here; do not infer database/file atomicity from this lesson's rename.
