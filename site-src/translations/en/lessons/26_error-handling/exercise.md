---
_translated_from: lessons/26_error-handling/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 26 Exercise: Error Classification and Recovery

This exercise uses only topics from Lessons 15–25: sequential file I/O, `FILE STATUS`, `AT END`, paragraph decomposition, `CALL`/`USING`, and `RETURN-CODE`. Work in the `build/` directory; do not modify the repository fixture or `lesson.cob`.

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_26 lesson.cob
cp transactions.txt build/                       # 夹具只读，测试一律用副本
```

## Modification Exercise (Answer in `answer.md`)

**Baseline:** the original `transactions.txt` just copied into `build/` (5 lines, 62 bytes; the two result files are overwritten by `OPEN OUTPUT`, so every run starts from this copy).

**Change and constraints:** modify only line 2 of `build/transactions.txt`, changing

```text
A00002|00X50
```

to

```text
A00002|00150
```

Leave the other four lines and all byte widths unchanged (this line remains 12 bytes). Do not modify `lesson.cob`.

**Commands:**

```sh
(cd build && ./lesson_26); echo "rc=$?"
cat build/accepted.txt
cat build/rejected.txt
wc -l -c build/accepted.txt build/rejected.txt
```

**Deliver:** the complete standard output, all contents of both result files and their line/byte counts, the process return code, and an explanation of why the line changes from rejected to accepted, why the rejection count decreases while the return code remains 0, and which line of `accepted.txt` should contain `A00002`.

See [`answer.md`](./answer.md) for a reference answer.

## Transfer Exercise (No Answer)

Choose a similar scenario: write `claims.cob` for an insurance company’s daily claims batch. Each line in `claims.txt` is 14 bytes, laid out as **claim number X(6) + `|` + type X(1) + `|` + amount X(5)** (amounts are in cents). The only valid types are `M` (medical) and `A` (accident). Complete the following:

1. Design the accepted and rejected record layouts (width and field order), put them in a program header comment, and state where each field comes from.
2. Choose a validation order, but distinguish width errors, unknown types, nonnumeric amounts, and zero amounts. Treat all of these as business rejections and continue reading. Keep a missing input, an output that cannot be opened, and a non-EOF read error as system failures that return code 1.
3. Create a fixture with at least 5 lines covering a valid record, unknown type, zero amount, nonnumeric amount, and a line with the wrong width. Give the invariant (`input = accepted + rejected`), the line and byte counts for both result files, and explain how you independently calculated the figures.
4. Make the **parent directory** of the accepted output nonexistent: change `ASSIGN` in `SELECT ACCEPTED-OUTPUT` to `"nodir/accepted.txt"` while `nodir/` does not exist. Run the program, record the `FILE STATUS`, system-error flag in the summary, and process return code, then compare the result with the “business rejection” in step 2.
5. Explain why, if writing the reject file itself fails, the program cannot keep counting later records as successfully processed.

No answer is provided. Do not use `AT END` in place of a status check after `READ`, and do not return a success status after an output failure. Do not introduce syntax not yet covered in this lesson. Deliver the source, compile and run commands, actual output, contents of both result files, the statistics above, and a list of failure types you **could not verify**.
