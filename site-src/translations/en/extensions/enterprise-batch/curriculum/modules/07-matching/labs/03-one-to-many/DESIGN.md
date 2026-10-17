# Boss L2: v1 file and business contract

## Versioned interfaces

ACCOUNT v1 remains 47 bytes; TRANSACTION v1 remains 55 bytes. Interpret both as defined in `BANK-SYSTEM.md`; do not redefine status=N, direction, or amount. Files are ASCII and LF-terminated; LF is excluded from logical width. Reject short/long rows and missing final LF. The job business date is passed as an argument. Amounts are integer JPY minor units; no decimal conversion.

A new `REVERSAL-LINK v1` association file is 48 bytes per record: account ID 10, reversal transaction sequence 6, reversal transaction ID 16, original transaction ID 16. Records are strictly sorted by account/sequence/reversal transaction ID. Every reversal has exactly one association; other transactions have none. This interface preserves the 55-byte transaction layout while explicitly validating the reversal target.

## Business policy

- Only account status A can be posted; transactions on frozen F and closed C accounts are rejected individually and do not change the balance. Accounts with no transactions still appear in the closing master.
- Zero amount is rejected as `ZERO-AMOUNT`. Thirteen nines is the per-transaction/account balance limit; exceeding the maximum balance is `OVERFLOW`, and debiting more than the available balance is `OVERDRAFT`. Transaction amounts are never negative; direction expresses credit/debit. Opening balance consists of sign plus 13-digit amount and ranges from ±9,999,999,999,999.
- Normal transactions must have status N. A transaction with no account is an orphan and is rejected as `NO-ACCOUNT`. Each input transaction is either accepted or rejected exactly once.
- A reversal must reference a previously accepted normal transaction from this business date, on the same account and with a lower sequence; transaction IDs are globally unique. Direction must be opposite and amount exactly equal. An original transaction may be reversed only once. A missing/not-yet-accepted/reversal/already-reversed/cross-account target, or amount/direction mismatch is rejected; rejection changes neither balance nor ledger. A reversal is also checked for overdraft/overflow. It can refer to any earlier transaction on that account; intervening transactions are allowed.
- Globally repeated transaction IDs (including across accounts and nonadjacent rows) and repeated reversal association IDs are data-contract errors: RC8, no publication. Checking only adjacent IDs on one account is not global deduplication.
- If a transaction has multiple business problems, rejection priority is fixed: account F/C status, zero amount, reversal-reference validity, overdraft/overflow. Structural input damage is always global RC8, never downgraded to a per-record rejection.
- Processing reads accounts and transactions sorted by account/sequence/ID. Working memory holds one account balance and current records; a temporary BDB INDEXED ledger looks up accepted originals by ID and REWRITEs reversal status. Disk use grows with transaction count; memory does not grow with file/group size. External SORT is used only to check global duplicate IDs.

## Hand-calculated example

Account A1 opens at 1000: T01 posts credit 500 → 1500; T02 debits 200 → 1300; T03 reverses T01 and debits 500 → 800 (the original is found even with T02 in between); T04 debits 900 and is rejected for overdraft, leaving 800. Therefore A1 closes at 800, 3 accepted and 1 rejected. A credit of 100 on frozen account A2 is rejected; its balance stays 50. A3 has no transactions and remains 0. Globally 5 reads = 3 accepted + 2 rejected; closing total 850 = opening 1050 + accepted credits 500 − accepted debits 700. The reversal counts in its opposite direction; it does not delete transaction history.

## Output and RC

Candidate report rows are emitted in order for each POST/REJECT, then account closing and account control rows, and finally the global control row. The publication directory also contains `master.dat` (original 47-byte master retaining all non-balance fields and changing only balance sign/amount), `accepted.dat` (original 55-byte accepted transactions), and `rejected.dat` (original 55-byte rejected transactions, delimiter, and per-record reason). Files are written to a private stage and published together only after conservation and status checks; candidate stdout is not the official result. The runner saves input/output SHA256 manifests and reference-source SHA256. Controls include read/accepted/rejected counts and accepted credits/debits; rejected amounts enter no balance or total. RC policy:

| RC | Meaning | Output policy |
|---:|---|---|
| 0 | No business rejection; all conservation checks pass | Publish |
| 4 | Per-transaction business rejection (frozen/closed/overdraft/overflow/zero/orphan/reversal-reference issue), while file contract remains valid | Publish checked results with rejection details; calling JOB must explicitly allow RC4 to continue |
| 8 | File layout, ordering, global ID uniqueness, association completeness, or other contract error | Fail whole batch; do not publish |
| 12 | Filesystem, index, build, lock, or publication error | Fail whole batch; do not publish |

Per account: `closing = opening + accepted credits - accepted debits`; transaction count = accepted + rejected. Global checks: input transactions = accepted + rejected; account count = accounts with transactions + accounts without; independently reconcile global accepted amount and rejected counts. Account/global count fields are 12 digits and SIZE ERROR fails. Per-account balances/transaction amounts are 13 digits; global amount totals are exact 18-digit decimals. Overflow fails without publication. Emit transaction rows before each account closing row to avoid buffering a same-key transaction group.
