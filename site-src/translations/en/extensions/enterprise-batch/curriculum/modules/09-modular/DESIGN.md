# Module 09 Design: Callable Modules and Interface Contracts

## 1. Business motivation

The same logic is needed repeatedly across nightly batch jobs: posting amount validation, customer validity checks, and standardized logging. If every job keeps its own copy, rules drift as soon as one changes, and during incident investigation no one can tell “which copy is actually correct.” This module extracts these three pieces of logic into **callable subprograms**, lets callers reuse them through **versioned interfaces**, and demonstrates how faults travel between caller and callee when interface length/version does not match or when stale, uninitialized state remains inside a subprogram.

GnuCOBOL multi-program compilation: `cobc` can link multiple source files in one invocation. A program containing `PROCEDURE DIVISION` (without `USING`) is the main program; other `PROGRAM-ID`s become subprograms callable by name with `CALL`. Module command:

```bash
cobc -Wall -I curriculum/modules/09-modular/copybooks \
     -I curriculum/bank/copybooks -x -o batch09 \
     BATCH09.COB AMTCALC.COB CUSTVAL.COB LOGGER.COB
```

## 2. File contracts (frozen, unchanged)

Following `BANK-SYSTEM.md`, this module changes none of these:

| Record | Length | Key fields |
|---|---:|---|
| CUSTOMER v1 | 27B | `customer_id`(8) `name`(10) `balance_demo`(8) `status`(1) |
| ACCOUNT v1 | 47B | account/customer/currency/sign/opening(13)/status/business date/`layout_version`(45–47=`001`) |
| TRANSACTION v1 | 55B | account/transaction ID/business date/sequence/direction/amount(13)/status |

All files are ASCII with LF endings; LF is excluded from logical width. Accounts are strictly ascending by `account_id`; transactions by `account_id`, `sequence_no`, `transaction_id`. `transaction_id` is also a **global business idempotency key**: it may not occur twice in the transaction stream (neither under one account with different sequences nor across accounts); otherwise the job returns RC8 and publishes nothing. Compared with v1, this module narrows/removes the reversal and ledger features from 07, retaining only “customer validation + amount posting + logging” to focus on CALL semantics.

## 3. Versioned call interfaces (`copybooks/`)

The first section of every interface is a fixed **length header + version header**. The caller supplies the record length and version it expects; the callee measures its own expected size with `LENGTH OF` and compares. A mismatch returns RC8 (interface error) without entering business logic. This makes parameter length/version mismatch detectable instead of relying on convention and crashing when it is violated.

Lengths were measured with `LENGTH OF` using the default GnuCOBOL 3.2 dialect on this machine:

| Interface | Length | Fields (order is offset order) | Semantics |
|---|---:|---|---|
| `AMT-CALC-INTERFACE` v1 | 45 | LENGTH(2,`COMP-5`) VERSION(3) OP(3) DIRECTION(1) AMOUNT-IN(13) BALANCE(`S9(13) COMP-3`,7) REASON(16) | Posting calculation; BALANCE is bidirectional |
| `CUST-VAL-INTERFACE` v1 | 40 | LENGTH(2) VERSION(3) CUSTOMER-ID(8) NAME(10) STATUS-IN(1) REASON(16) | Customer validation |
| `LOG-INTERFACE` v1 | 54 | LENGTH(2) VERSION(3) SEVERITY(1) EVENT(8) MESSAGE(40) | Append a log entry |

`VERSION` is fixed at `001`; `AMT-IFACE-OP` is fixed at `PST` for this lesson. Callers must use `MOVE LENGTH OF <interface> TO <interface>-LENGTH`; do not hard-code magic numbers unless deliberately running a fault experiment.

## 4. Parameter passing semantics and return codes

| Semantics | Use in this module | Observation point |
|---|---|---|
| `BY REFERENCE` (default) | AMTCALC and CUSTVAL interfaces | The callee writes BALANCE/REASON in the interface; the caller sees the changes |
| `BY CONTENT` | LOGGER interface | The callee receives a copy and cannot change the caller’s fields |
| `BY VALUE` | Demonstrated only in `scripts/ifaceprobe.COB` | Numeric argument is passed by value; callee changes are not returned |
| `RETURNING` | At each of the three module call sites: `... RETURNING WS-SUB-RC` | Receives the callee’s `RETURN-CODE` |

**Platform fact (measured on GnuCOBOL 3.2)**: if a callee declares `RETURNING <item>` on `PROCEDURE DIVISION`, compilation emits `warning: program RETURNING is not implemented`, and runtime accesses invalid memory. Therefore every callee does `MOVE <rc> TO RETURN-CODE` followed by `GOBACK`, and the caller uses `RETURNING` to receive it. This matches the repository’s existing implementation. `BY VALUE` also emits a `-Wunfinished` warning, so production modules do not use it; it appears only in the probe.

RC conventions (consistent with the course):

| RC | Meaning | Publication policy |
|---:|---|---|
| 0 | All accepted; conservation checks pass | Publish |
| 4 | One or more per-transaction business rejections | Publish verified results; caller job must explicitly allow RC4 |
| 8 | Interface length/version/operation or file layout/date/order contract error | Fail the whole batch; publish nothing |
| 12 | Filesystem, open/write, build, publication, or other system failure | Fail the whole batch; publish nothing |

The main program checks the result with `EVALUATE` immediately after every CALL. On 8/12 it runs `STOP RUN`, so the failure status **is produced by the callee and accurately returned as the process exit code by the caller**.

## 5. Working-storage lifecycle and state leakage

- A subprogram’s `WORKING-STORAGE SECTION` is **static by default**: values persist between calls in the same process. LOGGER intentionally uses this to maintain an increasing `WS-SEQ`.
- If logic that should be fresh on every call is also kept in static storage, a second call sees leftovers from the first and can trigger an “uninitialized residue on second call” incident. `IS INITIAL` resets that program’s `WORKING-STORAGE` before each call.
- `scripts/ifaceprobe.COB` compares two minimal subprograms: `STATIC-ACC` returns `0001/0002` on calls 1/2, while `INIT-ACC` (`IS INITIAL`) returns `0001` both times. This reproduces state leakage and its minimal fix.
- The three business modules have no cross-call business state (AMTCALC/CUSTVAL recalculate each time), so `check.py`’s repeat-call cases prove correct repeated results without hidden shared state.

## 6. Business rules

**CUSTVAL** (returns 0/4): nonnumeric ID → `BAD-ID`; all-space name → `CUST-NO-NAME`; status `A` passes, `D` → `CUST-DISABLED`, anything else → `CUST-BAD-STATUS`. Interface mismatch → 8.

**AMTCALC** (returns 0/4): interface mismatch → 8; nonnumeric amount → `AMT-NOT-NUMERIC`; amount 0 → `ZERO-AMOUNT`; direction other than `C/D` → `BAD-DIRECTION`; `new = balance ± amount`; exceeding 13 digits (`±9999999999999`) → `OVERFLOW`; negative result after debit → `OVERDRAFT`; otherwise write the new balance and `OK`. Amounts are integer yen in the smallest unit; no floating point.

**Main program** (determines RC4): transaction status other than `N` → `TX-STATUS`; account status other than `A` → `ACCOUNT-STATUS`; account not found → `NO-ACCOUNT`. Business rejections are recorded per transaction and do not affect conservation checks; contract errors (length/date/layout version/order) immediately return RC8.

Business rejection reason priority: `TX-STATUS` < `ACCOUNT-STATUS` < AMTCALC internal checks. Interface structure errors always return RC8; they are never downgraded to per-transaction rejection.

**Job-wide transaction uniqueness** (`run.sh`, before CALL/posting): ordered streaming comparison by account/sequence/id guarantees order, but **cannot** guarantee global `transaction_id` uniqueness. The job uses external sorting (`cut -c11-26 | sort | uniq -d`; `sort` performs an external merge with bounded memory) to detect global duplicates. A duplicate returns RC8 and publishes nothing. This is a **job-level** uniqueness check: it does not load the full transaction stream into an in-memory array (and does not replace the sequential merge algorithm being taught), and cannot be bypassed by a learner replacing `COURSE_SOURCE`. `oracle.py` independently checks duplicates with a set (same account/different sequence or across accounts); fixtures are `fixtures/invalid/dup-global-txid` and `fixtures/invalid/dup-cross-account`.

## 7. Output format

`report.txt` (stdout, one line per entry):

```text
CUST|<id>|OK|<name>                       CUST|<id>|REJECT|<reason>
CUST-CONTROL|READ=<12>|OK=<12>|REJECT=<12>
POST|<acct>|<txid>|ACCEPT|<sign13>        POST|<acct>|<txid>|REJECT|<reason>
ACCT|<acct>|<sign13>
POST-CONTROL|ACCTS=<12>|NOTX=<12>|TX=<12>|ACCEPT=<12>|REJECT=<12>
  |OPENING=<sign18>|CLOSING=<sign18>|CREDIT=<18>|DEBIT=<18>
```

Counts are zero-padded to 12 digits. Amounts `<sign13>`/`<sign18>` contain an explicit sign and fixed-width digits; CREDIT/DEBIT are unsigned 18-digit values. Derived files: `ledger.dat` (47B closing Master; only sign and opening/balance fields change), `customers-valid.dat` (27B accepted records), `customers-rejected.dat` (27B original record + `|` + reason), `batch09.log`, two SHA256 manifests, `run.txt`, `compiler.txt`, and `source.sha256`.

Each `batch09.log` line is written by LOGGER: `<YYYYMMDD>|<seq:6>|<sev>|<event:8>|<message>`. GnuCOBOL `LINE SEQUENTIAL` trims trailing spaces, so line width is not fixed; the independent model trims the same way.

## 8. Manual worked example (normal)

Customers 1/2 both pass with status `A`. Account 1 opens at 1000: T01 credits 500→1500; T02 debits 200→1300. Account 2 opens at 500: T03 credits 100→600. Closing balances are therefore 1300/600; total opening is 1500, credits 600, debits 200, and closing total is `1500+600-200=1900`. Three input transactions = 3 accepted + 0 rejected; two accounts = 2 with transactions + 0 without. In the frozen-account case, the account **does receive transactions** (all rejected), so it is not counted in `NOTX`. The correct measure is “whether the account received any transaction,” not “whether any transaction was accepted.”

## 9. Key review points

- Do not hard-code interface lengths/versions or other magic numbers; fault experiments must explicitly change the interface header, not disguise a fault as data.
- A callee may write only interface fields + `RETURN-CODE`; it must not read or write the caller’s private working storage.
- Check the return code after every CALL. Treating 8/12 as business rejections or publishing after failure is a critical defect.
- `transaction_id` requires **global** uniqueness checks; a duplicate under the same account with a different sequence or across accounts is fatal RC8. Ordered comparison by account/sequence/id alone misses global duplicates; do not replace the bounded mechanism with an in-memory array of the entire file.
- State leakage must be reproducible with `ifaceprobe` and have a minimal fix using `IS INITIAL` or explicit initialization.
