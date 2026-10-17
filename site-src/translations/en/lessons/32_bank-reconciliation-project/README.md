---
_translated_from: lessons/32_bank-reconciliation-project/README.md
_translated_by: site-src/translation agent
---

# Lesson 32: Bank Account Reconciliation Batch — Capstone Project: File Posting and Database Synchronization

## The Business Setting

It is 1:20 a.m., and the end-of-day batch is at its final step. You have two things:

- The **transaction file** exported by the core system: what happened today (deposits, withdrawals, transfers), in entry order, unsorted;
- The **account snapshot** in the system’s main database: the balances currently recorded there (this lesson uses SQLite; in a real environment, the host might not even let you access a shell).

Two things must be done, in the right order: first apply the transactions to the account master, calculate what each account **should contain**, and write accepted/rejected details; then synchronize those results back to the database.

Three groups will ask for something the next morning:

1. **Reconciliation** compares your calculated balances with the upstream record and amount totals;
2. **Operations** uses the rejection details to answer a customer who asks, “Why didn’t yesterday’s transfer arrive?”;
3. **Downstream systems** take the accepted file and continue posting.

So the acceptance criterion for this step is not “the program finished”; it is **this batch is ready to hand off**: every transaction has an outcome, every count makes sense, and when something fails, you know what was left behind.

Let’s state the least pleasant part plainly: both output files are overwritten. If the process crashes halfway through, the directory contains **partial results**—there is no rollback and no “on failure, keep the old file.” So before each handoff, the counts and row totals must be checked.

(The institution, times, and amounts are for an educational demonstration; they are not data from a real institution.)

## Why Learn This Now

Each earlier lesson verified one ability: reading files, sorting, matching, classifying, writing results, or connecting to a database. Each is straightforward on its own.

The hard part is **handing all of them off as one batch**: the file side and database side must reconcile, failures must leave traces that can be explained, and rerunning must not add the money twice. This lesson closes the whole chain and is the acceptance test for the course: the skills accumulated in the first 31 lessons are brought together here for the first time.

## What This Knowledge Point Is and What Problem It Solves

**What it is.** Connect independent batch steps into a buildable, rerunnable, auditable project: two COBOL subprograms (file posting and database synchronization), a main program, and a shared Copybook. `build.sh` compiles and links them, prepares the run directory, runs the project, and cleans up; a `check.sh` runs the normal, rerun, missing-file, and partial-SQL-failure scenarios.

**What business problem it solves.**

- **Every record is accounted for:** `記帳 + 拒否 = 取引` and `更新 + 変更なし + 挿入 = 口座`. With these two equations, you can give the team lead the counts on the spot when they ask whether anything is missing, without rerunning the batch.
- **Failures can be explained:** business rejections go to the rejection file with a reason (`INSUFFICIENT` / `BAD_TYPE` / `NO_ACCOUNT`); system failures produce a nonzero exit code. The next day, investigators can read the file instead of your screen.
- **Reruns do not post transactions twice:** every run recalculates from the same fixed opening balances, so the database balances remain the same even if you run the same input ten times.

**When this is not enough.** This is not a transaction or a production solution. File output and database writes are not packaged as an atomic operation—`check.sh` demonstrates this: when SQL fails midway, earlier statements have already taken effect, and a rerun is what restores the correct balances. A real system also needs a batch ID, input checksums, concurrency control, atomic output delivery, and operational alerts (see “Failure, Recovery, and Production Boundaries” below).

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Combine multiple COBOL programs, a Copybook, fixed-width files, and Embedded SQL into a batch project built by a script.
- Distinguish business rejections from system failures: overdrafts, unknown types, and unknown accounts go to the rejection file; file or SQL failures make the process return a nonzero code.
- Compare file-calculated results with a database snapshot by account number, handling updates, unchanged records, and inserts separately.
- Reconcile count invariants and verify rerun results: `記帳 + 拒否 = 取引` and `更新 + 変更なし + 挿入 = 口座`.
- Explain the recovery boundary between files and the database, including why this is **not** an atomic commit.

Limits: this is an educational, one-way synchronization project, and SQLite is used only for a reproducible demonstration. It has no distributed transaction, batch ID, input checksum, concurrency control, or operational alerting. Replaying input recalculates from fixed opening balances, so it does not add transactions again. See below for the controls needed to make it production-ready.

## Runtime Environment

- Linux + GnuCOBOL 3.2.x (`cobc`), GCC, and `sqlite3`.
- **Precompiler and runtime library:** GixSQL 1.0.20b (the same toolchain as Lesson 29). If it is not installed, run `../29_embedded-sql/install-toolchain.sh` in the **Lesson 29 directory** first. This lesson uses `../29_embedded-sql/build/toolchain/usr` by default; override it with `GIXSQL_ROOT`.
- Build and run artifacts go under this lesson’s `build/` directory (overridable with `BUILD_DIR`), which is ignored by the repository.
- Prerequisites: complete Lessons 20 and 23–31; know `cobc`, Bash, SQLite, `CALL`, `COPY`, and Embedded SQL. Estimated time: 3–4 hours.

## Project Inputs and Business Rules

The program reads two line-sequential files. Each record has a fixed width and no delimiters:

| File | Width | Field positions | Rules |
|---|---:|---|---|
| `accounts.txt` | 27 characters | 1–10 account number; 11–18 customer number; 19–27 balance in cents | Account numbers must be unique; at most 20 accounts; balance must be numeric |
| `transactions.txt` | 20 characters | 1–10 account number; 11 transaction type; 12–20 amount in cents | `D` deposits; `C` withdrawals; amount must be numeric |

Amounts are transmitted as integer cents. For example, `000012550` represents 125.50. The program converts amounts to `S9(7)V99 COMP-3` and displays two decimal places with an edited field in the results.

Processing rules:

1. Load the entire account master into an in-memory table first. Duplicate accounts, more than 20 accounts, or an invalid master balance are batch failures.
2. Each transaction must find an account in the master. `D` adds to the balance; `C` deducts only when the balance is sufficient.
3. Nonnumeric transaction amounts, unknown accounts, overdrafts, and unknown types are business rejections. Write them to `rejected.txt`; the batch may still finish successfully.
4. Write accepted transactions to `accepted.txt`. Begin database synchronization only if file processing has no system errors.
5. For each master account, query `ACCOUNT_SNAPSHOT` by account number. If both the customer number and balance match, classify it as `UNCHANGED`; if the row exists but either value differs, classify it as `UPDATED`; if the query returns SQLCODE 100, insert it and classify it as `INSERTED`.

This is an educational one-way synchronization: calculate the final balance from the file account master and this run’s transactions, then write it to the database snapshot. Replaying input recalculates from the same fixed master balances, so it does not add the same transaction to the database balance again.

## Build and Run

You need Linux, GnuCOBOL (`cobc`), GCC, SQLite (`sqlite3`), and the GixSQL 1.0.20b precompiler, SQLite driver, and runtime library verified in Lesson 29. If they are not installed, run `../29_embedded-sql/install-toolchain.sh` in the Lesson 29 directory first. The default path is `../29_embedded-sql/build/toolchain/usr`. Set `GIXSQL_ROOT` for a custom installation.

```sh
../29_embedded-sql/install-toolchain.sh
./build.sh check
./build.sh build
./build.sh run
./build.sh run-existing
```

- `check` preprocesses SQL with `gixpp`, then asks `cobc` to check the driver, file module, and SQL module.
- `build` compiles the two subprograms and links `lesson_32`.
- `run` recreates `build/lesson32.db`, applies `schema.sql`, copies the input fixtures to `build/run/`, then runs the program.
- `run-existing` keeps the database, resets only the input files in the run directory, and runs again to check replay behavior against the existing database state.
- `./check.sh` uses a temporary directory to run the normal, rejection, update/unchanged/insert, SQL error, recovery, and missing-input-file scenarios.
- `./build.sh clean` removes this lesson’s generated files under `build/`.

After changing data under `fixtures/`, run `./build.sh run`; it copies the new fixtures and recreates the database. `run-existing` also copies the fixtures, but keeps the database for replay checks. `build/run/` is for inspecting generated files; the next script run recreates that directory. Generated files are excluded by `.gitignore`.

## Standard Run Output

Standard output from `./build.sh run`:

```text
POSTED TX=001 ACCOUNT=A000000001 TYPE=D BALANCE=0001125.50
POSTED TX=002 ACCOUNT=A000000001 TYPE=C BALANCE=0001100.25
REJECTED TX=003 ACCOUNT=A000000003 REASON=INSUFFICIENT
REJECTED TX=004 ACCOUNT=A000000005 REASON=BAD_TYPE
REJECTED TX=005 ACCOUNT=A000000009 REASON=NO_ACCOUNT
接続=成功
SYNC UPDATED ACCOUNT=A000000001 BALANCE=0001100.25
SYNC UNCHANGED ACCOUNT=A000000003 BALANCE=0000002.00
SYNC UNCHANGED ACCOUNT=A000000005 BALANCE=0000250.75
切断=成功
集計 口座=03 取引=005 記帳=002 拒否=003 更新=001 変更なし=002 挿入=000
```
**Output legend (actual label → meaning):** `POSTED` = a transaction was posted (`TX` sequence, `ACCOUNT` number, `TYPE`, and `BALANCE` after posting); `REJECTED` = a business rejection, with `REASON` of `INSUFFICIENT` (insufficient funds) / `BAD_TYPE` (unknown type) / `NO_ACCOUNT` (no such account in the master); `接続=成功` / `切断=成功` = database connection / disconnection succeeded; `SYNC UPDATED` / `SYNC UNCHANGED` / `SYNC INSERTED` = database synchronization result (updated / unchanged / inserted); `集計 口座/取引/記帳/拒否/更新/変更なし/挿入` = account / transaction / posted / rejected / updated / unchanged / inserted counts.

In some environments, the GixSQL runtime writes a libxml version warning to standard error. It is not part of the program’s standard output; `check.sh` compares stdout only.

Generated files are in `build/run/`: `accepted.txt` has two successfully posted transactions, `rejected.txt` has three business rejections, `account-report.txt` has three database synchronization results, and `batch.log` records the batch start, transaction decisions, database connection, and synchronization end in order. The final balance for account A000000001 in the SQLite `ACCOUNT_SNAPSHOT` table is 1100.25.

On the second `./build.sh run-existing`, account balances remain unchanged and the summary becomes:

```text
集計 口座=03 取引=005 記帳=002 拒否=003 更新=000 変更なし=003 挿入=000
```

If A000000005 is missing from the database, the first synchronization prints `SYNC INSERTED`; after rerunning, that same account becomes `UNCHANGED`.

## How to Read the Source

The source uses traditional fixed format. The table below describes each program’s responsibilities by declaration and paragraph; adjacent `MOVE` / `COMPUTE` / `IF` / `WRITE` statements move fields, convert amounts, make branch decisions, and persist data, respectively.

### `lesson.cob`: Main Program

- The program declaration area defines the program name and includes `BATCH-INTERFACE.CPY`. `WS-ACCOUNT-TABLE` is a shared table with 20 fixed rows; `WS-BATCH-COUNTS` holds transaction and database synchronization counts; `WS-CHECK-COUNT` is a temporary value used for checks.
- The main flow uses `INITIALIZE` to clear the table and counters, then explicitly sets the failure flag to `N`. `CALL ... BY REFERENCE` passes the same data block to `LOADPOST32`; `SYNCDB32` is called only if the shared failure flag is not `Y`. It then checks counts, prints a summary, and sets the process return code.
- The summary paragraph prints a fixed-format summary. Edited `PIC 99` / `PIC 999` counters display leading zeroes.
- The failure handling paragraph maps system failures to `RETURN-CODE` 1. Business rejections do not change the failure flag, so the process can return 0.
- The final checks paragraph checks two invariants: `POSTED + REJECTED = TX`; when synchronization succeeds, `UPDATED + UNCHANGED + INSERTED = ACCOUNTS`. A mismatch reports an error and fails the process.
- Program comments record the file contract, module responsibilities, count invariants, table lookup cost, and recovery boundary; the main program ends with an explicit end statement.

### `load_post_32.cob`: File Validation and Transaction Posting

- The file declarations define five line-sequential files: two inputs, accepted output, rejected output, and the shared batch log. Each `FILE STATUS` has its own `PIC XX` field.
- The working data area declares the transaction parsing Copybook, file statuses, EOF/open flags, lookup index, amounts, and output buffers. The two groups in `LINKAGE SECTION` match the main program’s layout; the subprogram receives the caller’s data through `PROCEDURE DIVISION USING`.
- `1000-OPEN-FILES` opens files in order. Each successful open sets a flag so only opened resources are closed later. If a failure occurs, it does not continue opening the remaining files.
- `1100-LOAD-ACCOUNTS` reads the master one record at a time and sets a flag at EOF; valid records are passed to `1110-STORE-ACCOUNT`.
- `1110-STORE-ACCOUNT` checks the 20-row capacity first, then moves the 10-character account number, 8-character customer number, and 9-digit amount in cents into the table. It validates the balance with `IS NUMERIC`, then converts it to implied-decimal format with `NUMVAL(...) / 100`. A loop checks whether the new account number is a duplicate; a duplicate is an invalid system input and sets the shared failure flag.
- `2000-POST-TRANSACTIONS` reads the transaction file and passes each valid record to `2100-POST-ONE`.
- `2100-POST-ONE` increments the transaction sequence, splits the account number, type, and amount text from fixed positions, then searches the account table linearly with `PERFORM VARYING`. It validates the amount before converting it to packed decimal. A missing account, invalid amount, or business rule rejection sets `WS-REASON`. With no rejection reason, it calls `2300-WRITE-POSTED`; otherwise it calls `2400-WRITE-REJECTED`. It then copies the decision for that transaction into the log buffer.
- `2200-APPLY-TRANSACTION` dispatches on type with `EVALUATE`. `D` adds to the balance; `C` compares the amount with the balance and deducts only if it will not overdraw; other types are marked `BAD_TYPE`.
- `2300-WRITE-POSTED` and `2400-WRITE-REJECTED` each increment their corresponding count, format the account, sequence, resulting balance, or rejection reason into an 80-character buffer, display it, and write it to the corresponding output file. A write failure sets the system failure flag.
- `8000-CLOSE-FILES` closes files according to their open flags and checks each status. Before closing, the log gets `EVENT=POSTING_COMPLETE` appended.
- `8200-WRITE-LOG` writes the 100-character log buffer and promotes any write error to a system failure.

### `sync_db_32.cob`: Embedded SQL and Synchronization Report

- The file declarations define the report and log files. The working data area also declares GixSQL host variables, database connection state, synchronization status, and SQLCA.
- `LINKAGE SECTION` again declares account table and batch count layouts matching the caller. Keep the field order because `CALL ... BY REFERENCE` passes the entire block by position. A trailing reserved byte is for GixSQL: preprocessing emits the final linkage item as a comment; removing the reserved item makes `WS-FAILED` undefined and compilation fails.
- `MAIN-SYNC` opens the report and appends to the batch log; it connects to the database only if the files opened successfully. The database and files are closed separately, and `9000-DISCONNECT` runs if the connection succeeded.
- `1000-CONNECT-DATABASE` reads `DATASRC`, user, and password from the environment and executes GixSQL `CONNECT`. The run script passes the SQLite path through the environment; the program source contains no machine path or password.
- `2000-SYNC-TABLE` processes the accounts in the in-memory table one by one and stops processing later accounts on failure.
- `2100-SYNC-ACCOUNT` copies the current account fields into separate host variables, then executes `SELECT ... INTO`. SQLCODE 0 compares the customer number and balance; 100 means no matching row and branches to insertion; any other SQLCODE marks a failure. It writes to the report and log only after successful classification.
- `2200-UPDATE-ACCOUNT` updates the customer number and balance using account number as the `WHERE` key; it increments `UPDATED` only when SQLCODE is 0.
- `2300-INSERT-ACCOUNT` inserts an account that is missing from the database and increments `INSERTED`.
- `2400-REPORT-SYNC` writes the decision, account number, and final balance to the report file and batch log.
- `8100-WRITE-LOG` checks the status of each log write. `9000-DISCONNECT` closes the GixSQL connection; SQL or disconnect failures end the process with status 1. A comment marks the cursor footer boundary generated by the GixSQL preprocessor.

Java/Python programs often represent an account table as a list of objects, a dictionary, or a DataFrame, treat `CALL` as a function call, and treat `FILE STATUS` as an explicit I/O exception branch. Here, data layout is defined by `PIC` and level numbers, `LINKAGE SECTION` receives the caller’s memory, and the program explicitly checks file and SQL status. Do not assume that a COBOL record is equivalent to an arbitrary language object, or mistake shared modifications through `BY REFERENCE` for a value copy.

## Failure, Recovery, and Production Boundaries

`check.sh` injects an actual UPDATE error with a SQLite trigger and confirms that SQLSTATE is reported and the program returns 1. After removing the trigger, a rerun replays the files and restores the same final database balances. A missing account master also returns 1 and prevents database synchronization.

This example does not wrap file output and database writes in a distributed transaction, and it does not claim the whole batch is atomic. SQL updates for earlier accounts may already have taken effect before a later account fails. Rerunning can reconcile the balances from the complete input, but does not roll back accepted/rejected files already written. Production systems also need batch IDs, input snapshots and checksums, audit retention, an explicit database transaction commit policy, partial-failure recovery procedures, concurrency control, and operational alerts. This exercise cannot replace those designs.

GixSQL/SQLite runs actual Embedded SQL in this lesson. `sqlite3` creates and checks the database; the COBOL module connects through GixSQL and executes `SELECT` / `UPDATE` / `INSERT`. SQLite makes the lesson reproducible, but does not represent the concurrency, locking, transaction, or SQL dialect behavior of Oracle/PostgreSQL.

## Modification Exercises (With Answers)

1. Add a 1.00 deposit for account A000000003 to `fixtures/transactions.txt`. The balance after processing should change from 2.00 to 3.00; on the first run, the account should be classified as `UPDATED`, not `UNCHANGED`.
2. Delete account A000000005 from `schema.sql`, then run `./build.sh run`. Confirm that the account follows the SQLCODE 100 insert branch and is counted as `INSERTED`; after `./build.sh run-existing`, it should become `UNCHANGED`.

The answers cover only these two exercises; see [`answer.md`](./answer.md). For detailed steps, see [`exercise.md`](./exercise.md).

## Further Exploration (No Answer)

Add a batch date to the account master and prevent the program from processing a master and transaction file with different dates. Add an optimistic concurrency check to SQL synchronization so two batches cannot silently overwrite the same account. Design a recoverable batch status table that distinguishes “files complete,” “database committed,” and “report archived,” and explain the rerun rule for each failure point.

No answer is provided.

## Walk Through a Real Workflow

Connect this step to a real overnight schedule:

1. **0:40** The core system exports the day’s transactions to a fixed-width file (Lessons 15 and 17) and exports an account master snapshot.
2. **1:00** The scheduler starts this lesson’s `lesson_32`; `build.sh` has already compiled and linked the two subprograms (Lessons 24 and 28).
3. **1:00–1:20** The file-posting subprogram reads the master and validates each transaction: accepted transactions go to `accepted.txt`, rejections to `rejected.txt` (Lessons 16 and 26), and every decision is written to `batch.log` (Lesson 27).
4. **1:20** The database synchronization subprogram connects to the snapshot database (Lesson 29) and compares accounts one by one: it runs `UPDATE` when values differ and `INSERT` when the account is absent (the cursor/single-row query approach from Lesson 30).
5. **1:25** Print the summary, write `BATCH_END`, and close files and the connection.
6. **Next morning:** Reconciliation checks the counts, operations checks the rejection details, and downstream takes the accepted file. Someone calls to ask, “Why didn’t this one arrive?” You open `rejected.txt` and see `NO_ACCOUNT`—there is the answer.

## What Would Happen If This Code Entered Production

- **Who schedules it:** an end-of-day batch scheduler, after “transaction file ready” and “account master export complete.”
- **Who reads the output:** reconciliation reads the counts and `account-report.txt` (to reiterate, this is an educational report filename); operations reads rejection details; the on-call operator first checks the exit code.
- **Who gets called when something breaks:** file open or SQL failure → nonzero exit code → scheduler alert. Note the boundary shown by `check.sh`: if SQL fails midway, earlier updates are already in the database; **a rerun** restores the correct balances, rather than an automatic rollback.
- **How the next system connects:** a downstream posting program takes the accepted file; query systems read `ACCOUNT_SNAPSHOT` in the database.
- **The most likely first-month incidents:** (1) matching against an unsorted master (silently wrong results); (2) upstream changes field widths but only the main program is recompiled (old object files still use the old layout); (3) assuming “it ran successfully” means “it is ready to deliver,” without checking counts and result-file row totals.
- **What is still needed for production:** batch IDs and idempotency keys, input checksums, explicit database transaction boundaries and commit policy, concurrency control, atomic output delivery, failure rerun procedures, log retention and redaction, and operational alerts. This lesson implements none of these and **should not** be deployed as-is.

There is no place here for the old style of vague “enterprise practice supplement” prose: every item above has a counterpart in this lesson’s scripts, fixtures, and `check.sh` scenarios.

End-of-day bank account posting validates core-system transaction files against accounts and totals balances, then synchronizes balances and creates discrepancy reports and audit logs. Corporate loan repayments, insurance premium collection, and securities settlement use similar file validation and master-data reconciliation patterns. A real batch needs explicit business dates, idempotency keys, duplicate-file policy, amount precision, database transaction scope, locking strategy, clearing deadlines, an exception queue, and operational audit. These controls must be designed around the institution’s accounting and recovery rules.

## References

- [Lesson 20: Matching Sorted Files](../20_file-matching/README.md)
- [Lesson 26: Error Handling](../26_error-handling/README.md)
- [Lesson 28: Modular Batch Project](../28_modular-batch-project/README.md)
- [Lesson 29: GixSQL Embedded SQL Environment](../29_embedded-sql/README.md)
- [Lesson 30: SQL Cursor](../30_sql-cursors/README.md)
- [Lesson 31: File and Database Snapshot Synchronization](../31_data-synchronization/README.md)
- [GixSQL README](https://github.com/mridoni/gixsql/blob/main/README.md)
- [GnuCOBOL Programmer’s Guide](https://gnucobol.sourceforge.io/HTML/gnucobpg.html)
