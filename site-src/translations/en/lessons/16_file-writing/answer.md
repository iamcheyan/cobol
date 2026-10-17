---
_translated_from: lessons/16_file-writing/answer.md
_translated_by: site-src/translation agent
---
# Lesson 16 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in [`exercise.md`](./exercise.md); it does not answer Apply What You Learned. All output, byte counts, and return codes below were observed in this workspace with GnuCOBOL 3.2.0. The runtime directory was the lesson’s `build/` directory.

## 1. Make the Fourth Entry an Accepted Result

### Changes

Starting from the original `lesson.cob`, change only these two lines in `1000-LOAD-RESULTS`:

```cobol
           MOVE "A" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|A"
               TO WS-RESULT-TEXT(4)
```

`PIC`, the `FD` record width, the `OCCURS 4 TIMES` upper bound, the loop limit, the other three records, and all `DISPLAY` text remain unchanged.

Commands:

```sh
mkdir -p build
cp lesson.cob build/
cobc -fsyntax-only build/lesson.cob
cobc -x -Wall -o build/lesson_16 build/lesson.cob
(cd build && ./lesson_16)
echo $?
wc -lc build/accepted.txt build/rejected.txt
```

The syntax check, compilation, and program exit codes are all `0`; compilation produces no diagnostics.

### Complete Output After the Change

```text
オープン=受理 成功
オープン=拒否 成功
書込=受理 取引=000001
書込=受理 取引=000002
書込=拒否 取引=000003
書込=受理 取引=000004
クローズ=受理 成功
クローズ=拒否 成功
SUMMARY 受理=03 拒否=01
```

Only two lines differ from the original:

| Line | Original | After the change | Reason |
|---|---|---|---|
| 6 | `書込=拒否 取引=000004` | `書込=受理 取引=000004` | The destination marker becomes `A`, so `EVALUATE` selects the accepted-file branch. |
| 9 | `SUMMARY 受理=02 拒否=02` | `SUMMARY 受理=03 拒否=01` | One more record is written to the accepted file and one fewer to the rejected file. |

The other 7 lines are byte-for-byte unchanged.

### Output Files After the Change

`accepted.txt` (3 lines, 108 bytes)

```text
TXN-000001|0001234567|D|000125.50|A
TXN-000002|0007654321|T|000040.00|A
TXN-000004|0009999999|T|000020.00|A
```

`rejected.txt` (1 line, 36 bytes)

```text
TXN-000003|0002468101|X|000000.00|R
```

Independent check: each line has 35 characters and its final character is not a space, so it occupies `35 + 1 = 36` bytes. Therefore `3 × 36 = 108` and `1 × 36 = 36`. Together the files contain 4 lines, matching the four table entries, and `03 + 01 = 04`.

### Answers to the Questions

**1. Why must the record text change along with the destination marker?**

They are independent fields. `WS-RESULT-DESTINATION(4)` is used by `EVALUATE` only to choose the file; `WS-RESULT-TEXT(4)` supplies the 35 characters written to the file. The program contains no statement that compares the two values.

Observed result when only the destination marker is changed (the record text still ends in `R`): `accepted.txt` contains 3 lines and 108 bytes, and the third line is:

```text
TXN-000004|0009999999|T|000020.00|R
```

In other words, **the accepted file contains a record marked as rejected**. The program does not report an error: `cobc` returns `0`, the program exits with code `0`, and `SUMMARY 受理=03 拒否=01` is identical to the case where both values are changed. The program does not validate that a record’s final marker agrees with its destination file; the person who supplies the sample data is responsible for consistency.

**2. What determines the order of the three lines in `accepted.txt`?**

The processing order of `PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1 UNTIL WS-RESULT-NUMBER > 4` determines it—the load order of the result table (entries one, two, and four). The file is written sequentially, so earlier writes appear first. The filesystem does not reorder the contents, and `EVALUATE` only chooses the destination file; it does not change the order.

**3. What happens if the fourth destination marker is `X` (neither `A` nor `R`)?**

Observed after changing `WS-RESULT-DESTINATION(4)` to `"X"` and leaving everything else unchanged:

```text
オープン=受理 成功
オープン=拒否 成功
書込=受理 取引=000001
書込=受理 取引=000002
書込=拒否 取引=000003
書込=FAILED REASON=UNKNOWN_DESTINATION
クローズ=受理 成功
クローズ=拒否 成功
SUMMARY 受理=02 拒否=01
```

| Observation | Observed value |
|---|---|
| Branch taken | `WHEN OTHER`, prints `書込=FAILED REASON=UNKNOWN_DESTINATION` |
| `accepted.txt` | 2 lines, 72 bytes (only entries one and two) |
| `rejected.txt` | 1 line, 36 bytes (only entry three) |
| `SUMMARY` | `受理=02 拒否=01` |
| Exit code | `1` |

The fourth entry goes to neither file, so **the two counts add up to only 3, fewer than the 4 table entries**. This breaks the count invariant and serves as the signal this lesson is designed to expose: `WHEN OTHER` sets an error flag without writing or incrementing a count. At the end, `IF WS-WRITE-ERROR = "Y"` sets the exit code to 1, so the job fails instead of appearing successful with a missing record. Since the fourth entry is last, the early exit from `UNTIL ... OR WS-WRITE-ERROR = "Y"` has no further effect. If the error occurred on the first entry, the remaining three would not be written; this lesson does not roll back partial output.

## 2. Check Overwrite Behavior and Reruns

### Operation and Observation

Use the original, unmodified `lesson.cob`. Put a line containing `OLD` in both output files before the run:

```sh
mkdir -p build
cp lesson.cob build/
cobc -x -Wall -o build/lesson_16 build/lesson.cob
printf 'OLD\n' > build/accepted.txt
printf 'OLD\n' > build/rejected.txt
wc -c build/accepted.txt build/rejected.txt   # 4 bytes each
(cd build && ./lesson_16)
echo $?                                         # 0
wc -lc build/accepted.txt build/rejected.txt    # 2 lines, 72 bytes each
cat build/accepted.txt build/rejected.txt
```

| Observation | Before run | After run |
|---|---|---|
| `accepted.txt` | 4 bytes, contents `OLD` | 72 bytes, contents are the two sample accepted records only |
| `rejected.txt` | 4 bytes, contents `OLD` | 72 bytes, contents are the two sample rejected records only |
| Standard output | — | 9 lines, byte-for-byte the same as the normal path |
| Exit code | — | `0` |

Comparison of two consecutive runs: standard output is byte-for-byte identical both times, and each file remains 72 bytes rather than growing to 144 bytes.

### Answers to the Questions

**1. Why is `OLD` gone? Which program statement causes it?**

`OPEN OUTPUT 受理-FILE` and `OPEN OUTPUT 拒否-FILE` create the files or recreate them empty. If a file already exists, it is truncated to length 0 before writing starts at the beginning. This is not “delete then create” (the path still refers to the same file), and the program does not need to check whether the file exists first.

**2. If you expected two runs to accumulate to 144 bytes, what is the actual size?**

Each file remains 72 bytes. Every run’s `OPEN OUTPUT` truncates and recreates the file contents; the second run overwrites the same four sample records instead of appending them. This rerun result is stable only as long as the program writes the same number of records each time. It follows from overwrite semantics and the fixed table upper bound, not from an idempotency check. If a future run wrote only three records, an old fourth record would not automatically be removed; this lesson does not clean up partial output.

**3. What happens if `accepted.txt` is a directory before the run?**

Observed after `mkdir accepted.txt`:

```text
オープン=受理 失敗 状態=37
```

The exit code is `1`, and `rejected.txt` is not created. The program stops in the first `IF WS-受理-STATUS NOT = "00"` branch, which executes `MOVE 1 TO RETURN-CODE` and `STOP RUN`; no records are written. Status code `37` is in GnuCOBOL’s permission-denied class. On this machine, the same status was observed for a directory as the target, a read-only file (`0444`), and a non-writable directory. This demonstrates that an open failure is detected and returns 1; it does not establish that every disk-write failure in production will be detected promptly (see the README’s “Evidence Sources and Verification Scope”).
