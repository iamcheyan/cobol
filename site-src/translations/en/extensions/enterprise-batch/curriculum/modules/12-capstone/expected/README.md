# Expected Results and Independent Reconciliation

The expected results in this directory are calculated independently from the business rules before the reference implementation is run; they are not saved program output (AUTHORING-STANDARD, Section 4).

- Generator: `instructor/modules/12-capstone/tools/gen_course.py`. It independently reimplements the BANKVAL business rules and the Module 07 L2 1:N overdraft rule. It never reads output from any course implementation and does not import the Module 10 generator.
- Fixed, deterministic data (FR-10), business date 20261010.

| File | Meaning |
|---|---|
| `<case>.control.txt` | Count/amount conservation metrics (`k=v`) |
| `<case>.closing.txt` | `account_id=±13-digit closing balance` |
| `<case>.customerday.txt` | `customer_id|classification|account count|±13-digit customer total` |
| `<case>.rc` | Expected process RC for that day type |

## Independent Reconciliation Process

- **Accept/reject**: direction other than C/D → BADDIR; status ≠ N → BADSTATUS; business date mismatch → BADDATE; amount is 0 → BADZERO.
- **Balance**: apply transactions one by one in `(account_id, sequence_no, transaction_id)` order; reject a debit if it would make the balance <0 (OVERDRAFT), and exclude it from amount totals.
- **Conservation**: `opening balance + credits − debits = closing balance` (per account and in total).
- **Customer daily report**: aggregate account count and closing balance total by customer_id; upgrade the enterprise v1 A/B/C/D classification to `<code>1` (A1..D1).

## Expected Results by Day Type

| case | RC | Key points |
|---|---:|---|
| normal | 0 | All 6 transactions posted |
| abnormal | 4 | 4 validation rejects + 1 overdraft reject |
| rerun | 0 | Same feed as normal; 0 transactions posted on the second run |
| extension | 0 | v2 classification, including a `D1` customer |
| broken | 8 | Duplicate transaction_id; nothing is published |
