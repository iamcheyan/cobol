# Lesson 20 Exercises: Sequential Key Matching

This section uses only material covered in Lessons 15–20: sequential-file `SELECT`/`OPEN`/`READ`/`CLOSE`, `FILE STATUS`, `AT END`, `EVALUATE TRUE`, `IF`, paragraphs, and `PERFORM`.

## Modification Exercises (Reference Answers in `answer.md`)

Make both changes only to **fixture copies in a temporary directory**; do not modify the repository's `accounts.txt` or `transactions.txt`. First prepare the temporary directory:

```sh
scratch=$(mktemp -d)
cp lesson.cob accounts.txt transactions.txt "$scratch/"
cd "$scratch"
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o lesson_20 lesson.cob
```

1. Delete the entire line for account number `A000000004` from the copy of `transactions.txt`. Run `./lesson_20`, check the comparison between master key `A000000003` and the current transaction key, and record the three counts: `照合件数` / `口座のみ` / `取引のみ`.
2. Starting from the original fixtures, change the key `A000000004` in the copy of the transaction file to `A000000003` and change the amount to `000005000` (it must remain 20 characters, and the file must remain sorted in ascending order). Run the program and confirm that this transaction matches master record `A000000003` and that both streams advance.

Constraint: do not change `lesson.cob`; every line must retain its correct length and the account keys must remain in order.

After each change, record the three category counts, exit code, and complete output, and explain which branch advanced the master stream, the transaction stream, or both. Then check the count invariants: `照合件数 + 口座のみ` must equal the number of master records, and `照合件数 + 取引のみ` must equal the number of transaction records. See `answer.md` for reference answers.

## Take It Further (No Answer Provided)

Add a duplicate account key to each input and add a record that violates ascending order to each input. Extend the program to detect duplicate keys and descending keys, state the rejection policy you choose, and create fixtures to verify matching, unmatched, duplicate, and unsorted cases.

Submit the source, compile and run commands, actual output and exit code for each fixture, and an explanation of which count invariants you used to confirm that no records were missed. No answer is provided: do not load both complete files into an `OCCURS` table or call `SORT`.
