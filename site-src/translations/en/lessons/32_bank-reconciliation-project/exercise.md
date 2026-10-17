---
_translated_from: lessons/32_bank-reconciliation-project/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 32 Exercise: Extend Account Posting and Database Synchronization

## Modification Exercises (See `answer.md` for Suggested Answers)

First run `./build.sh run` to create the database and executable. Each record in `transactions.txt` is 20 characters: a 10-character account number, a 1-character type, and a 9-digit amount in cents. After each change, run `./build.sh run` again; it recreates the database and loads the original snapshot from `schema.sql`.

1. Add a 1.00 deposit for account `A000000003` at the end of `fixtures/transactions.txt`. Verify that the transaction is accepted, the calculated master balance changes from 2.00 to 3.00, and database synchronization classifies the account as `UPDATED`. Check the accepted file, report file, summary, and SQLite row.
2. Delete account `A000000005` from the initial `ACCOUNT_SNAPSHOT` rows in `schema.sql`. After rerunning, the account should still be in the file master. Verify that SELECT returns SQLCODE 100, the program inserts the account, and reports it as `INSERTED`. Then run `./build.sh run-existing` and verify that the account becomes `UNCHANGED`.

## Further Exploration (No Answer)

Add a business date to both the account master and transaction file. Reject transactions with a mismatched date and prevent them from changing account balances. Then design and implement a batch control table that records a batch ID, input file checksums, start/end times, and processing status. Explain how to rerun safely with the same batch ID after an SQL update fails midway.

No answer is provided.
