# Module 09 Fixtures

All files are ASCII, fixed-width, and end each line with LF; LF is not counted in the logical width. The business date is fixed at `20261010`. Layouts are frozen contracts: CUSTOMER v1 = 27 bytes, ACCOUNT v1 = 47 bytes, TRANSACTION v1 = 55 bytes. Directory layout: `normal/` (main case, with three `.dat` files directly inside the directory), `boundary/<case>/`, and `invalid/<case>/`. Fixtures are generated deterministically by `../scripts/generate-fixtures.py`; `SHA256SUMS` covers this file and all `.dat` files.

| Directory | Coverage | Expected RC | Published? |
|---|---|---|---|
| `normal` | All accepted: 8-digit customer validation passes, per-transaction amount calculations are correct | 0 | Yes |
| `empty-customers` | Customer file is empty; accounts/transactions are normal | 0 | Yes |
| `no-transactions` | Transaction file is empty; accounts still output closing balances | 0 | Yes |
| `max-amount` | A single transaction amount and balance reach the 13-digit limit and remain valid | 0 | Yes |
| `all-empty` | All three files are empty | 0 | Yes |
| `customer-bad-status` | Customer status `Z`; `CUSTVAL` returns a business rejection | 4 | Yes |
| `customer-bad-id` | Customer ID contains non-digits; `CUSTVAL` returns a business rejection | 4 | Yes |
| `customer-no-name` | Customer name consists entirely of spaces; `CUSTVAL` returns a business rejection | 4 | Yes |
| `zero-amount` | Transaction amount is 0; `AMTCALC` returns a business rejection | 4 | Yes |
| `overdraft` | Debit exceeds available balance; `AMTCALC` returns a business rejection | 4 | Yes |
| `overflow` | Credit causes the balance to exceed the 13-digit limit; `AMTCALC` returns a business rejection | 4 | Yes |
| `unknown-direction` | Transaction direction is neither `C` nor `D`; `AMTCALC` returns a business rejection | 4 | Yes |
| `no-account` | Transaction account does not exist in the account file; caller determines a business rejection | 4 | Yes |
| `frozen-account` | Account status `F`; caller rejects each transaction according to business policy | 4 | Yes |
| `bad-layout-version` | Account layout version `002`; file contract error | 8 | No |
| `short-account` | Account record is 46 bytes; input length contract error | 8 | No |
| `bad-account-date` | Account business date does not match the job business date; contract error | 8 | No |
| `unsorted-transactions` | Transactions are not sorted by account/sequence in ascending order; contract error | 8 | No |

RC4 fixtures still publish verified reports and derived files (the caller of JOB must explicitly allow continuation for RC4).
RC8 fixtures fail the entire batch and produce no output directory.
