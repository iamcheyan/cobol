# 07.5 file field catalog

All text files are ASCII and LF-terminated; LF is excluded from field widths. CRLF, short/long rows, missing final LF, or control characters are not allowed. Amounts are integer JPY minor units, not floating point or decimal yen. Existing `ACCOUNT-V1.CPY` / `TRANSACTION-V1.CPY` remain unchanged. New layouts have independent versions and do not redefine the 27B CUSTOMER v1 teaching record in BANK-SYSTEM.

## CUSTOMER-SNAPSHOT v1 (36B)

Unique key: customer_id; strictly ascending, at most one row per customer. This offline file is a fixed seed snapshot before Module 08's real DB extraction; it does not indicate that a database connection or consistent read has been implemented.

| Byte | Width | Field | Rule / use |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII digits, nonempty, unique, matches ACCOUNT customer_id |
| 9–16 | 8 | snapshot_business_date | Valid Gregorian YYYYMMDD; must equal job date |
| 17–19 | 3 | layout_version | `001` only |
| 20 | 1 | customer_status | `A` active; `D` disabled and business-isolated |
| 21–23 | 3 | max_account_count | ASCII digits; customer associated-account limit. Count includes all Master records in statuses A/F/C |
| 24–36 | 13 | max_customer_balance | ASCII digits; customer total closing-balance limit, integer JPY |

Physical record width is 36B. COBOL layout is defined in `copybooks/CUSTOMER-SNAPSHOT-V1.CPY`; compile-time `LENGTH OF` and the checker measure total width.

## PREVIOUS-DAY v1 (39B)

Unique key: customer_id; strictly ascending, at most one row per customer. Date must be the prior real Gregorian calendar day before the job business date; weekends and Japanese bank holidays are not skipped. The prior-day summary aggregates all associated accounts (all statuses A/F/C) and must not be applied separately to each account.

| Byte | Width | Field | Rule / use |
|---:|---:|---|---|
| 1–8 | 8 | customer_id | ASCII digits, nonempty, unique |
| 9–16 | 8 | previous_business_date | Valid Gregorian YYYYMMDD equal to the calendar day before job date |
| 17–19 | 3 | layout_version | `001` only |
| 20–25 | 6 | account_count | ASCII digits; prior customer-associated account count, including all A/F/C statuses |
| 26 | 1 | closing_sign | `+` or `-`; negative only for total balance |
| 27–39 | 13 | closing_total | ASCII digits; prior-day customer closing-balance total |

Physical record width is 39B. COBOL layout is defined in `copybooks/PREVIOUS-DAY-V1.CPY`; compile-time `LENGTH OF` and the checker measure total width.

## Four business streams and sources

| Stream | Upstream interface | Ordering/cardinality | Role in this stage |
|---|---|---|---|
| ACCOUNT | Canonical v1 47B | Unique account_id ascending; multiple accounts per customer and customer_id need not be monotonic with account_id | Current opening and customer association; reconcile each account with L2 candidate master |
| TRANSACTION | Canonical v1 55B + separate REVERSAL-LINK v1 | Strict account/sequence/id order; globally unique id; 0..N per account | Raw transactions go to real L2 first; L3 consumes L2 accepted stream and retains L2 rejects/controls |
| CUSTOMER-SNAPSHOT | This lesson's v1 36B | Unique customer_id ascending | Status, account-count limit, closing-total limit; offline DB snapshot seed |
| PREVIOUS-DAY | This lesson's v1 39B | Unique customer_id ascending | Previous-day customer account-count and closing-total control |
