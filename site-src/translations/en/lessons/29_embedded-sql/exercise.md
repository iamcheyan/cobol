---
_translated_from: lessons/29_embedded-sql/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 29 Exercise: Host Variables and SQL Status

This exercise uses only material from lesson 29: GixSQL precompilation, `EXEC SQL ... END-EXEC`, host variables, `SQLCODE` branches, and `CONNECT` / `CONNECT RESET`.

## Modification exercises (sample answers in `answer.md`)

First run `./build.sh run` and save the baseline output. After each change to `lesson.cob`, run the same command again. The script rebuilds the database so the previous result cannot affect this exercise:

```sh
./build.sh run
echo $?
```

1. Change the account number in the first query from `A000000001` to `A000000002`. Check the customer ID and balance, and explain how `SELECT ... INTO` moves database columns into COBOL fields.
2. Start from the original source and change the account number in the second query from `A99999999X` to `A000000002`. Compare which `SQLCODE` branch each query takes and how the standard output differs.

Constraints: do not change `schema.sql` or `build.sh`; start each run with a clean database and record the exit code. See `answer.md` for sample answers.

## Apply the idea (no answer provided)

Add an opening date and account status to `ACCOUNT_SNAPSHOT`, then query an `ACTIVE` account using host variables. Define how “account does not exist” and “SQL execution failed” should appear in standard output, logs, and the exit code. Explain why the database path and credentials should be supplied by the deployment environment.

Submit `schema.sql`, `lesson.cob`, the run command, and the actual output and exit code for all three cases: found, not found, and SQL failure. No answer is provided.
