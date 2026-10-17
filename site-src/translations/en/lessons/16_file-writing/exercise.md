---
_translated_from: lessons/16_file-writing/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 16 Exercise: Write Routed Results—Routing, Overwrite, and Reruns

This lesson uses only material from Lesson 16 and prerequisite lessons: `SELECT` / `FD` / `FILE STATUS` / `OPEN OUTPUT` / `WRITE ... FROM` / `CLOSE` (this lesson), `OCCURS` tables (Lesson [11](../11_occurs-tables/README.md)), `EVALUATE` (Lesson [05](../05_evaluate/README.md)), paragraphs and `PERFORM` (Lesson [07](../07_paragraphs/README.md)), `DISPLAY`, `MOVE`, and `STOP RUN`.

> **Runtime location:** The program writes `accepted.txt` and `rejected.txt` in the **current directory at runtime**. The lesson directory’s files with those names are not protected by `.gitignore`. Use the lesson’s `build/` directory as the working directory for every exercise: the executable and both output files will be placed there, and `build/` is ignored by the repository. Finish by running `rm -rf build` to clean everything up.

## Modification Exercises (Reference Answers in `answer.md`)

### 1. Make the Fourth Entry an Accepted Result

#### Baseline

Start from this lesson’s original [`lesson.cob`](./lesson.cob), unchanged in the working tree. For example, copy it before editing so the baseline can be rerun: `cp lesson.cob /tmp/lesson_16_ex1.cob`.

#### Change and Constraints

Change only these two statements in `1000-LOAD-RESULTS`:

```cobol
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4)
```

Change the destination marker to `"A"` and also change the last character of the record text to `A`.

Constraints:

- Do not change the destination markers or text of the other three records.
- Do not change `PIC`, the `FD` record width, the `OCCURS 4 TIMES` upper bound, or the loop limit `UNTIL WS-RESULT-NUMBER > 4`.
- Do not change any `DISPLAY` text. Do not add output files, input files, logs, or databases.

#### Commands

```sh
mkdir -p build                                          # working directory
cp lesson.cob build/                                    # edit the copy in build/; leave the lesson file alone
cobc -fsyntax-only build/lesson.cob                     # syntax check
cobc -x -Wall -o build/lesson_16 build/lesson.cob       # compile
(cd build && ./lesson_16)                               # run in build/ so outputs land there
echo $?                                                 # exit code
wc -lc build/accepted.txt build/rejected.txt            # line and byte counts
cat build/accepted.txt build/rejected.txt               # contents of both files
```

#### Expected Difference

Standard output remains 9 lines, with **only two changed lines**:

| Line | Original | After the change |
|---|---|---|
| 6 | `書込=拒否 取引=000004` | `書込=受理 取引=000004` |
| 9 | `SUMMARY 受理=02 拒否=02` | `SUMMARY 受理=03 拒否=01` |

The other 7 lines (the first 5 and the 2 `クローズ=` lines) remain byte-for-byte identical. Complete output after the change:

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

The two files:

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

Syntax check, compilation, and program exit codes are all `0`. Independent check: each line has 35 characters and its last character is non-space, so each line occupies 36 bytes. Thus `3 × 36 = 108` and `1 × 36 = 36`. Together the files contain 4 lines, matching the four entries; `03 + 01 = 04`.

#### Questions to Answer

1. Why must the record text change along with the destination marker? If only the destination marker changes, what line appears in `accepted.txt`? Does the program report an error?
2. What determines the order of the three lines in `accepted.txt` after the change? Is it the filesystem, `EVALUATE`, or something else?
3. What happens if the fourth entry’s destination marker is changed to `X`, which is neither `A` nor `R`? What are the standard output, both file contents and byte counts, `SUMMARY`, and exit code?

For each question, record the actual output and the relevant source code. See [`answer.md`](./answer.md) for the reference answers.

### 2. Check Overwrite Behavior and Reruns

#### Baseline

Use the original, unmodified [`lesson.cob`](./lesson.cob). Put a prior line in each output file inside `build/` before running:

```sh
mkdir -p build
cp lesson.cob build/
cobc -fsyntax-only build/lesson.cob
cobc -x -Wall -o build/lesson_16 build/lesson.cob
printf 'OLD\n' > build/accepted.txt
printf 'OLD\n' > build/rejected.txt
wc -c build/accepted.txt build/rejected.txt     # byte counts before the run
(cd build && ./lesson_16)                       # run
echo $?
wc -lc build/accepted.txt build/rejected.txt    # lines and bytes after the run
cat build/accepted.txt build/rejected.txt        # contents
```

#### Constraints

Do not delete or edit files in the lesson directory. Do not run the program there. No source change is needed.

#### Expected Difference

| Observation | Before run | After run |
|---|---|---|
| `accepted.txt` | 4 bytes, contents `OLD` | 72 bytes, contents are only the 2 sample accepted records |
| `rejected.txt` | 4 bytes, contents `OLD` | 72 bytes, contents are only the 2 sample rejected records |
| Standard output | — | the same 9 lines as the normal path |
| Exit code | — | `0` |

#### Questions to Answer

1. Why is `OLD` gone? Which program statement causes this?
2. If you expected two runs to “accumulate” to 144 bytes, what will the actual size be, and why?
3. If you make `accepted.txt` a **directory** before the run with `mkdir accepted.txt`, what does the program print, what is its exit code, and is any file created?

For each question, record actual output, exit code, and byte counts. See [`answer.md`](./answer.md) for the reference answers.

## Apply What You Learned (No Answer Provided)

Add a third route for results that need manual review: add a third destination marker (for example, `H`) to the result table, declare a new output file (for example, `review.txt`), add a `WHEN` branch to `EVALUATE`, and add a write count and summary entry.

Requirements:

- Choose the new file name and record width. State two reasons: which directory a relative name is written to, and which field or `PIC` determines the record width.
- Choose which sample records to mark `H`, and keep the marker at the end of each record’s text consistent with its route marker.
- Explain your checks: line and byte counts for all three files, whether the three counts add up to the number of table entries, and whether every line’s final marker matches the file it is in.
- Cover at least one boundary by deliberately making one record’s final text marker disagree with its destination marker. Report whether the program detects the mismatch and explain who is responsible for this outcome.
- Record compile commands, actual output, file byte counts, exit code, and your calculations.

Constraints: use only syntax from this lesson and prerequisites—`SELECT` / `ASSIGN` / `ORGANIZATION` / `FILE STATUS`, `FD`, `OPEN OUTPUT` / `WRITE ... FROM` / `CLOSE`, `EVALUATE`, `OCCURS` tables, paragraphs and `PERFORM`, `MOVE`, and `DISPLAY`. Do not introduce input files, append mode, temporary-file renames, databases, or subprograms.

Deliver the source, complete contents and byte counts of the two or three output files, commands, actual output and exit code, and an explanation of who is responsible when a marker and destination disagree. No answer is provided.
