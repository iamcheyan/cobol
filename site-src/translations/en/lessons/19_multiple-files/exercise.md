# Lesson 19 Exercises: Independent Input Streams and EOF

This section uses only material covered in Lessons 15–19: sequential-file `SELECT`/`OPEN`/`READ`/`CLOSE`, `FILE STATUS`, `AT END`, `PERFORM UNTIL`, `IF`, and `DISPLAY`.

## Modification Exercises (Reference Answers in `answer.md`)

Make both changes only to **fixture copies in a temporary directory**; do not modify the repository's `accounts.txt` or `transactions.txt`. First prepare the temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_19 lesson.cob
```

1. Delete the last two records from the copy of `transactions.txt`, leaving only the first two. Run `./lesson_19` and confirm that all three master records are still read while the transaction count is two.
2. Empty the copy of `accounts.txt` while keeping all four transactions. Run `./lesson_19` and confirm that the empty master file reaches EOF on the first `READ`, after which the transactions continue to be read one by one.

For each run, record the complete output, exit code, and the two independent counts. Constraint: do not clear or share an EOF flag just to “let the other file continue reading”; EOF, status, and count must remain independent for the two inputs. See `answer.md` for reference answers.

## Take It Further (No Answer Provided)

Add a third input stream for a customer master file alongside the account master and transaction files, and prepare fixtures containing 3, 2, and 1 records, respectively. Give each of the three files its own `FILE STATUS`, EOF flag, and count, and read them in round-robin fashion until all three streams have ended. Include an empty-file case in the fixtures, and explain how the program closes files already opened and returns a nonzero code if any input fails to OPEN or encounters a READ error.

Submit the source, compile and run commands, actual output and exit code for each fixture, and an explanation of how you confirmed that the three streams' EOF flags do not affect one another. Do not add cross-file matching or amount calculations. No answer is provided for this exercise.
