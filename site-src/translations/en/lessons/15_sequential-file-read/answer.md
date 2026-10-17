---
_translated_from: lessons/15_sequential-file-read/answer.md
_translated_by: site-src/translation agent
---
# Lesson 15 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in [`exercise.md`](./exercise.md); no answer is provided for Apply What You Learned. Both exercises use the same temporary runtime directory, which can be reset and reused:

```sh
cd lessons/15_sequential-file-read
scratch_dir=$(mktemp -d)
trap 'rm -rf "$scratch_dir"' EXIT
cobc -x -Wall -o "$scratch_dir/lesson_15" lesson.cob
cp transactions.txt "$scratch_dir/"
```

## 1. Append a Fifth Record

```sh
printf 'DAY-20261013|TXN-000005|D|0001234567|10.00\n' >> "$scratch_dir/transactions.txt"
wc -lc "$scratch_dir/transactions.txt"        # 5 lines, 238 bytes = 195 + 42 + 1
( cd "$scratch_dir" && ./lesson_15 ); echo $? # exit code 0
```

Expected standard output (one added line and one count change):

```text
オープン=OK
レコード=DAY-20261013|TXN-000001|D|0001234567|125.50
レコード=DAY-20261013|TXN-000002|T|0001234567|0007654321|40.00
レコード=DAY-20261013|TXN-000003|D|0002468101|75.00
レコード=DAY-20261013|TXN-000004|T|0007654321|0009999999|20.00
レコード=DAY-20261013|TXN-000005|D|0001234567|10.00
EOF=はい レコード数=05
クローズ=OK
```

The count changes from `04` to `05`: the appended line is the fifth successfully read record; EOF is reached on the next `READ`.

Reset by copying `transactions.txt` over the temporary copy again, or create a new directory with `mktemp -d`. This program reads text only; it does not change balances or any account data because a line contains `D` or an amount.

## 2. Read an Empty File

```sh
: > "$scratch_dir/transactions.txt"
( cd "$scratch_dir" && ./lesson_15 ); echo $? # exit code 0
```

Expected standard output:

```text
オープン=OK
EOF=はい レコード数=00
クローズ=OK
```

The empty file opens successfully, so there is no `オープン=FAILED`. The first `READ` immediately takes the `AT END` branch: no `レコード=` line is printed, the count is `00`, and closing succeeds. For another outcome, you can additionally remove the fixture with `rm -f "$scratch_dir/transactions.txt"`; the program then prints `オープン=FAILED STATUS=35` and exits with code `1`. That case is described in the lesson README’s “Run and Observe” section and is outside the requested exercise answers.
