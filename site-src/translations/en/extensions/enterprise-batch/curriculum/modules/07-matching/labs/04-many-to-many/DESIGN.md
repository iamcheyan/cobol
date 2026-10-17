# Boss L3: customer-day N:N reconciliation

## Business semantics and stage boundaries

L3 uses one customer as the aggregation business key. A customer may have N accounts, each with M transactions that day; the N accounts and M transactions belong to the same customer association group, but are not paired account-by-transaction and do not form a Cartesian product. A transaction belongs to one customer only through `ACCOUNT.customer_id`; account amounts and that customer's accepted transactions are each aggregated once. Snapshot and previous-day each contain one record per customer.

The JOB entry receives ACCOUNT v1, TRANSACTION v1, REVERSAL-LINK v1, CUSTOMER-SNAPSHOT v1, and PREVIOUS-DAY v1. The runner first calls the accepted B01 real L2 JOB on raw ACCOUNT/TRANSACTION/REVERSAL-LINK. L2 owns the existing policies for frozen/closed accounts, zero amounts, overdraft/overflow, cross-account references, and reversals of any earlier transaction. L3 consumes only L2 accepted originals, rejected originals, and closing-master candidate; it does not post again. If L2 returns RC0/RC4 and candidate validation passes, L3 continues; L2 RC8/12 stops the batch. B03 generates customer reconciliation and “eligible for later update” isolated candidates only; it does not update a DB. CUSTOMER-SNAPSHOT is an offline fixed-byte seed; do not claim it came from a DB or that Module 08 is complete.

## Dates and versions

ACCOUNT must use canonical v1 layout `001` and this run's BUSINESS_DATE. TRANSACTION uses the existing fixed TRANSACTION v1 55B contract, which has no separate version field, and must use BUSINESS_DATE. Snapshot date must equal BUSINESS_DATE; Previous-Day must be the prior Gregorian calendar day, **not a bank business day**. Inputs must be strict-width ASCII + LF with valid fields and unique ascending keys. New CUSTOMER-SNAPSHOT v1 36B and PREVIOUS-DAY v1 39B fields are in [FIELDS](FIELD-CATALOG.md) and their separate Copybooks. Date/version/structure/order/duplicate-key errors are RC8 and fail the whole batch without publication. Never substitute an old snapshot for one missing or stale.

## Aggregation, N:N reconciliation, and isolation policy

For customer `c`, define:

- `A(c)`: accounts in ACCOUNT v1 associated with `c`; aggregate opening `opening(c)` and account count `accounts(c)`. Count and balance include every ACCOUNT status A/F/C; frozen/closed status affects L2 acceptance only and does not remove an account from customer aggregation.
- `T(c)`: L2 accepted transactions associated with `c` through ACCOUNT account_id; count each once and calculate `credit(c)`, `debit(c)`, and `tx_count(c)`.
- `P(c)`: the single prior-day customer summary, with `previous_accounts(c)` and signed `previous_close(c)`.
- `S(c)`: the single customer record in CUSTOMER-SNAPSHOT, with status and customer account/balance limits.

For structurally complete groups where both S/P exist and customer status is A, require:

1. Current aggregated account openings equal prior-day customer closing; current account count equals the previous count of all associated accounts, including A/F/C.
2. `expected_close = previous_close + accepted_credit - accepted_debit`.
3. L2 per-account closings re-aggregated by customer equal `expected_close`.
4. Current account count does not exceed `snapshot.max_account_count`; customer closing does not exceed `snapshot.max_customer_balance`.
5. Every ACCOUNT/L2 accepted TX maps to one unique customer; every Snapshot/Previous row is consumed once or emitted as an orphan difference.

Missing Snapshot/Previous, Snapshot customer status D, account-count/limit mismatch, opening-vs-previous mismatch, or aggregate-vs-L2 closing mismatch are customer-level business rejections RC4. All related accounts and transactions for that customer go to isolation reports and are excluded from `eligible-master.dat`/`eligible-transaction.dat`; they must not be passed to JOB006 DB updates. Other structurally valid customers may still publish. Orphan Snapshot/Previous rows are independent source differences; consume and identify their record keys. RC4 output must contain reason, customer_id, source key/count/amount; business rejections cannot exist only on stdout.

Match original ACCOUNT rows to L2 closing-master rows sequentially. All original 47B bytes other than balance must match. Balance may change due to that day's accepted transactions and must independently satisfy per-account opening + accepted credit - accepted debit = L2 closing; then aggregate customer opening/closing by customer. Duplicate/descending rows, bad width/ASCII/date/version, duplicate account/customer, globally duplicate transaction IDs, accepted TX with no unique ACCOUNT, non-balance byte changes, or failed conservation are structural/runtime contract errors RC8/12 and the batch is not published. L2 `rejected.dat` preserves original transaction bytes and reasons as separate B01 business control and does not enter L3 accepted transaction totals. Globally reconcile separately: original ACCOUNT count = eligible master count + isolated account count; L2 accepted count = eligible accepted TX count + isolated accepted TX count; accepted credit and debit totals each equal the corresponding eligible and isolated amounts. Keep L2 rejected count separate; it is not part of accepted or isolation amounts.

## Four-stream states and consumption table

Original ACCOUNT and L2 accepted transactions are keyed by account_id. Since `customer_id` is not monotonic with account_id, the customer snapshot pointer cannot be advanced by comparing it directly during the account scan. This implementation uses COBOL to associate accounts/transactions with customer keys, externally sorts derived customer streams using fixed 2M `COB_SORT_MEMORY`, then performs a bounded four-way merge by customer key. Intermediate records preserve original account/transaction bytes and account_id as source proof. A customer-level decision is not known until all four streams' rows for that group are consumed; therefore the core writes each account/transaction source record to a single-customer disk spool, then checks equations and limits. On success, replay the spool in order to eligible candidates; on rejection, replay each row as a source-locating isolation record, clear the spool, and proceed to the next customer. Memory holds only keys, count/amount accumulators, and one current row; group size affects temporary disk only, never a full-group array.

| Comparison state | Output/accumulator | Advance rule |
|---|---|---|
| Any stream EOF | Independent EOF boolean; never use zero/all-9 sentinel | Do not READ an EOF stream; drain remaining non-EOF sources |
| Minimum customer key appears only in Account | Sum one or more account openings/counts; if Snapshot/Previous missing, isolate as RC4 | Advance only the account stream's current customer group |
| Minimum key appears only in Accepted-TX | Must map to ACCOUNT or RC8; sum each credit/debit/count once | Advance only this stream's current customer group |
| Minimum key appears only in Snapshot or Previous | Emit orphan-source difference; do not drop row | Advance that single snapshot stream |
| Minimum keys equal (`=`) across streams | Combine all sources for customer into bounded accumulators; check conservation and emit MATCH or specific differences | Consume same-key rows in each participating stream; read next row after group |
| Account/Transaction customer key `<` another stream | Finish this customer's account/transaction group; isolate missing source under RC4 | Advance smaller-key source, not other streams |
| Snapshot/Previous key `<` other streams | Emit corresponding orphan snapshot/previous row | Advance the smaller snapshot stream |
| Customer keys interleave | Process smallest key among non-EOF streams; duplicate full/customer keys were rejected by precheck as RC8 | Each consume must advance a unique source count |

**Main hand-trace example:** ACCOUNT in account_id order: A1→customer02 opening1000, A2→customer01 opening2000, A3→customer02 opening3000. Transactions: A1 C50/D20, A2 D100, A3 C70. After sorting by customer, A stream has customer01(2000), customer02(1000+3000). T stream has customer01 D100; customer02 C50/D20/C70. Snapshot: customer01 status A, max_account_count 1, max_balance 8000; customer02 A/2/10000. Previous-Day: customer01 account_count 1 close2000; customer02 account_count 2 close4000. Closings are 1900 and 4100; overall 3 accounts, 4 transactions, opening 6000, credit 120, debit 120, closing 6000. Each TX belongs to one account and then one customer; customer02's snapshot count/amount is checked once, never copied separately to A1 and A3.

Four-cursor trace uses customer keys, not original account keys: initial A=01, T=01, S=00, P=01. Since `S<A/T/P`, emit Snapshot-only 00 and advance only S. Next all keys are 01; on `=`, consume each source's customer01 group once. After advancing, all keys are 02 and customer02 is consumed. Finally A/T/S are EOF and P=03; emit only Previous-only 03. If any stream reaches EOF first, retain its independent EOF state while the others continue to EOF. Automated checks enumerate all 16 presence/EOF combinations of A/T/S/P. An orphan transaction without an account is classified by upstream L2 as NO-ACCOUNT; it is not in the L3 accepted stream.

## RC and publication

| RC | Policy | Official output |
|---:|---|---|
| 0 | All customers reconcile; no L2 rejection or L3 business difference | Publish after validation |
| 4 | L2 rejection or customer-level difference; preserve original rejections and L3 isolation while other valid customers may continue | Publish after validation; downstream JOB must allow RC4 and exclude isolation |
| 8 | Any input/version/order/uniqueness/mapping/conservation structural error | Do not publish |
| 12 | Build/permission/disk/sort-work-file/lock/verification/publication/unexpected RC failure | Do not publish |

Write output first to a lock-protected private candidate directory, then publish without clobbering after independent byte/count/amount verification. Reset refuses and preserves all files when any lock exists. Original input snapshot SHA remains unchanged; candidate stdout is not the official result. `run.sh` retains the L2 report, L2 accepted/rejected records, customer reconciliation report, isolated-source report, eligible candidates, control, and input/output manifests.
