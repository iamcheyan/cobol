---
_translated_from: lessons/15_sequential-file-read/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 15 Exercise: Read a Text File Sequentially

Perform every exercise in a temporary directory using a copy. The repository’s [`transactions.txt`](./transactions.txt) is a shared fixture; do not edit it in place or leave runtime artifacts in the lesson directory. Prepare a one-time runtime environment:

```sh
cd lessons/15_sequential-file-read
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -x -Wall -o "$scratch_dir/lesson_15" lesson.cob
cp transactions.txt "$scratch_dir/"
```

Start both modification exercises from this clean fixture copy. Remove `$scratch_dir` when finished to reset the environment.

## Modification Exercises (Answers in [`answer.md`](./answer.md))

### 1. Append a Fifth Record (Line Order and EOF)

- Baseline: original fixture copy, 4 lines and 195 bytes (visible characters total 43+53+42+53 = 191, plus 4 newline characters).
- Where to change and constraints: change only the copy in the temporary directory; do not touch `lesson.cob` or the repository fixture. Keep the new line at 100 characters or fewer:

  ```sh
  printf 'DAY-20261013|TXN-000005|D|0001234567|10.00\n' >> "$scratch_dir/transactions.txt"
  ```

- Recompile and run: only input data changed, so **no recompilation is needed**. Run:

  ```sh
  ( cd "$scratch_dir" && ./lesson_15 ); echo $?
  ```

- Complete expected difference: standard output gains one line, `レコード=DAY-20261013|TXN-000005|D|0001234567|10.00`; `EOF=はい レコード数=` changes from `04` to `05`; the `オープン=OK` and `クローズ=OK` lines are unchanged; exit code remains `0`.
- Reason: a line-sequential file splits records by line. The appended line is returned by the next successful `READ` and increments the count; EOF is reached on the following `READ`.

### 2. Empty File (Empty-Input Boundary)

- Baseline: a copy of the same original fixture.
- Where to change and constraints: empty the copy; leave source unchanged:

  ```sh
  : > "$scratch_dir/transactions.txt"
  ```

- Recompile and run: recompilation is unnecessary. Run:

  ```sh
  ( cd "$scratch_dir" && ./lesson_15 ); echo $?
  ```

- Complete expected difference: there are no `レコード=` lines. Only three lines remain: `オープン=OK`, `EOF=はい レコード数=00`, and `クローズ=OK`; exit code is `0`.
- Reason: an empty file can still be opened successfully. The first `READ` immediately takes the `AT END` branch, so no record is read and no error status occurs.

## Apply What You Learned (No Answer Provided)

Create a three-line customer-support event file and choose your own data and verification method. Include one line of exactly 100 characters and one of 101 characters.

1. Use `wc -c` to record the file’s byte count. Before running the program, write down your predicted number of `レコード=` lines and `レコード数`.
2. Copy the file to the runtime directory as `transactions.txt`, then read it with the program built for this lesson. Compare your prediction with the actual output and explain how each record was delimited.
3. Explain how you independently checked the byte count, line lengths, and record count, and how your conclusion would change if the 101-character line were shortened to 100.

Use only the read method covered in this lesson: do not modify source code, parse fields, or write to a database. No answer is provided.
