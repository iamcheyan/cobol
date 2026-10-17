---
_translated_from: lessons/21_sort/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 21 Exercise: SORT and Input Procedures

This exercise uses only material covered in Lessons 15–21: sequential-file `SELECT` / `OPEN` / `READ` / `CLOSE`, `FILE STATUS`, `AT END`, `SORT` with `RELEASE` / `RETURN`, `PERFORM`, and `DISPLAY`.

## Modification Exercises (sample answers are in `answer.md`)

For both exercises, modify only **fixture copies in a temporary directory**. Do not modify the repository's `accounts-unsorted.txt`. First prepare a temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts-unsorted.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_21 lesson.cob
```

1. Swap the first two lines in the copy. Run `./lesson_21`, confirm that the output is still sorted in ascending account-number order, and compare the input and output record counts.
2. Starting from a copy of the original fixture, append a 27-character record with account number `A000000006`, customer number `C0001006`, and balance digits `000000001`. After running the program, confirm that the new record is on the last line and that both the input and output counts are `005`.

Constraints: Do not modify `lesson.cob`; the appended line must be 27 characters long.

Save the complete standard output from each run, and identify which procedure executes `RELEASE` and which executes `RETURN`, as well as where each `AT END` appears. See `answer.md` for sample answers.

## Further Exploration (no answer provided)

Add a second field to the sort key: sort by account number in ascending order, then by balance in descending order for the same account. Prepare at least two records with the same account number and different balances. Record the modified `SORT ... ON ASCENDING KEY ...` declaration and the complete output, and explain whether the relative order of records with equal keys can be relied on when only one sort key is declared, and why observing a few sets of data is not enough to draw a conclusion.

Submit the source code, compile and run commands, actual output, and exit code. Do not first load all records using `OCCURS`, and do not use `USING` / `GIVING` to bypass the two procedures in this lesson.
