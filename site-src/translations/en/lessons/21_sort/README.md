---
_translated_from: lessons/21_sort/README.md
_translated_by: site-src/translation agent
---
# Lesson 21: Sorting an Account Master — Turning Unordered Input into Ordered Output

Lesson 20’s sequential matching assumes that both inputs are sorted by account number. Upstream master files often are not. This lesson uses `SORT` to order four unsorted account records: the input procedure reads and `RELEASE`s each record, and the output procedure retrieves them in account-number order with `RETURN`. The resulting record stream is ready for the matching scan.

## The Business Setting

A little after 2 a.m., the reconciliation job reaches its second step: processing the account master together with the day’s transactions. The transaction file is orderly; the transaction system appends entries in occurrence order. The master is less predictable. The core system’s export job does not sort it; it writes rows in whatever order they happen to be scanned from the data pages.

Operations drops the file in a shared directory and says, “That’s the file. You’ll have to handle it.”

Feeding it directly to Lesson 20’s matching scan will not produce an error. The merge scan assumes both sides are in ascending key order. When that assumption is false, it can classify existing accounts as having no counterpart. The `口座のみ` and `取引のみ` categories grow with differences that do not exist. The program finishes normally with exit code `0`; the reconciliation clerk sees a discrepancy report the next morning and starts investigating records that were never truly mismatched.

The necessary step is to sort the file before matching it. This lesson teaches that preparation stage.

(The times, counts, and scenario are invented for teaching and do not describe a real institution.)

## Why Learn This Now

The previous lessons taught you to read and write files and to advance two or more streams independently (Lessons 15–19). Lesson 20 introduced a key-based merge scan that classifies records as matched, master-only, or transaction-only. That algorithm has a prerequisite: **both streams must be ordered**. Upstream systems do not necessarily promise that their exports are already sorted.

You could read records into memory and sort them yourself. That works for a few hundred records, but for tens of thousands you must hold the entire input and deal with memory limits. You also inherit the details of the sorting algorithm, performance, equal keys, and larger volumes—none of which are part of the business rule.

COBOL packages this work in `SORT`. You specify the key and where records come from and go; the runtime handles the ordering.

## What This Concept Is and the Problem It Solves

**What it is.** `SORT` provides a pipeline: read records, order them by key, and return them in order. You provide a sort key, an input procedure, and an output procedure. The input procedure sends records to the sort work file with `RELEASE`; the output procedure retrieves sorted records with `RETURN`. Each returned record is ready for ordinary processing.

**The business problem it solves.** It separates arranging records from using them. The upstream order does not matter: records enter the sort and leave in the required order. Reconciliation, matching, merge scans, and cross-file comparisons all depend on ordered data. Sorting should be implemented correctly in one place.

**The result is not a file.** The program creates no output file. Its result is an ordered record stream: the output procedure retrieves and processes one record at a time (this lesson displays each one). In a complete batch, the stream can feed Lesson 20’s matching scan directly. Writing sorted results to a file is covered in Lesson 22.

**Do not assume an order for duplicate keys.** `SORT` promises ascending key order. The standard does not specify which of two records with equal keys comes first, so a program must not depend on a particular order. To make the order deterministic, declare a second key—for example, sort equal account numbers by descending balance. The fixture’s account numbers are unique, so this behavior cannot be observed here; it remains unverified.

**When not to use it.** Small tables already in memory, or records that need repeated conditional searches, belong to Lessons 11–13 (`OCCURS` and `SEARCH`). If both streams are already ordered and only need merging, Lesson 20’s direct scan is sufficient. This lesson deliberately uses both procedures because the key declaration, `RELEASE`/`RETURN` boundaries, and counts are the point. `USING`/`GIVING` would hide those details and are not allowed in the exercises.

## Capabilities and Limits After This Lesson

After completing this lesson, you can:

- Declare a sort work file (`SELECT ... ASSIGN TO DISK` and `SD`) and specify an ascending key.
- Open the input and read and `RELEASE` records one at a time in an `INPUT PROCEDURE`.
- Use `RETURN` to retrieve sorted records in an `OUTPUT PROCEDURE`, ending with `AT END`.
- Use `SORT-RETURN` to distinguish sort success from failure and verify `input record count = output record count`.
- Explain why application code must not `OPEN` or `CLOSE` the sort work file, and how sorted output can become Lesson 20’s matching input.

Scope: this lesson sorts and displays data. It does **not** create a sorted output file, total amounts, or perform matching. The fixture has unique account numbers, so equal-key order is not observed. Sort-key rules, duplicate-key policy, and batch handling after sort failures are interface agreements; formal error routing is covered in Lesson 26.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source is fixed format.
- Linux terminal; no database or extra tools are required.
- `SELECT` uses a relative file name, so run from this lesson directory. Syntax checking and compilation place the executable in `build/`.

## Record Layout and Data Flow

![SORT pipeline from input procedure through ordering to output procedure](assets/sort-data-flow.svg)

[`accounts-unsorted.txt`](./accounts-unsorted.txt) contains four unsorted records, each 27 characters:

| Field | `PIC` | Length |
|---|---|---:|
| Account number | `X(10)` | 10 |
| Customer number | `X(8)` | 8 |
| Balance | `9(7)V99` | 9 |

The implied decimal point `V` takes no character, so the visible record width is 10 + 8 + 9 = 27. This is the same master layout used in Lessons 17 and 20.

The program declares `SELECT SORT-WORK ASSIGN TO DISK` and `SD SORT-WORK`. The first declares a sort work file; the second describes its records. Note that it uses `SD`, not the `FD` used for ordinary input and output files.

The `SORT` statement manages this file. **Do not `OPEN` or `CLOSE` it in application code.** The input procedure sends records with `RELEASE`; the output procedure retrieves them with `RETURN`.

## The Three Sorting Stages

1. `SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER` specifies the key and enters the two procedures.
2. Input procedure `1000-LOAD-INPUT` opens the line-sequential input, reads one record at a time, moves each 27-character record into the `SD` record, and `RELEASE`s it. File status `10` means normal end of file.
3. GnuCOBOL orders the released records by `SD-ACCOUNT-NUMBER`.
4. Output procedure `2000-RETURN-SORTED` repeatedly calls `RETURN` and displays each record. `AT END` means there are no more records.
5. The main paragraph checks `SORT-RETURN` and displays input/output counts. An input-read or sort failure produces a nonzero exit code.

Count invariant: `input record count = output record count`. Here it is `004 = 004`: all four records were released and returned, so none were lost or invented. In batch work, this is one of the first numbers to check.

## Assumptions and Boundaries

| Assumption | Guaranteed by | Checked here? |
|---|---|---|
| Each input line follows the 27-character layout | Fixture/upstream | No; a different width causes fields to be read incorrectly |
| Account numbers are equal-width and include leading zeroes | Fixture design | No; equal-width text order matches account-number order |
| Account numbers are unique | Fixture | No; duplicate keys are not handled |
| Order among records with equal keys | No agreement | **Unverified**: there are no duplicates in the fixture. Add another sort key to guarantee a tie-break (see the extension exercise). |

The final row matters: no one has guaranteed this behavior on your behalf. Without duplicate-key data, you cannot observe it. This is why “try a few files and see” is not a sound test strategy.

Again, the `SORT` statement manages the sort work file. Application code neither opens/closes nor reads/writes it directly. The input file is opened and closed in the input procedure; output goes only to the terminal. No sorted-result file is created.

## Run and Observe

**Input:** `accounts-unsorted.txt` in this lesson directory (four unsorted records). The program opens a relative path, so first change to this directory.

**Commands and their purpose:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # syntax check only; creates no executable
cobc -x -Wall -o build/lesson_21 lesson.cob    # compile the executable
./build/lesson_21                              # read the fixture in the current directory
echo $?                                        # inspect the exit code
rm -rf build                                   # remove the generated executable
```

**Expected result:**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compiler diagnostics |
| Standard output | Five lines; four records in ascending account-number order |
| Process exit code | `0` |
| Business files created | None (the runtime manages the sort work file internally) |

```text
ソート済み 口座番号=A000000001 顧客番号=C0001001 残高=0001000.00
ソート済み 口座番号=A000000002 顧客番号=C0001002 残高=0000002.00
ソート済み 口座番号=A000000004 顧客番号=C0001004 残高=0000025.00
ソート済み 口座番号=A000000005 顧客番号=C0001005 残高=0000250.75
入力レコード数=004 出力レコード数=004
```

**Check the result independently:** the fixture account numbers are `A000000005`, `A000000001`, `A000000004`, and `A000000002` (unsorted). Output must be `A000000001`, `A000000002`, `A000000004`, `A000000005`. Sorting only changes order, so the input and output account-number sets must match. The `004 = 004` count confirms that no records were lost.

**Output labels (Japanese output → meaning):** `ソート済み` = sorted; `口座番号` = account number; `顧客番号` = customer number; `残高` = balance; `入力レコード数` / `出力レコード数` = input/output record count.

**Observed environment detail:** running the executable in this workspace prints `Warning: program compiled against libxml 212 using older 209` to standard error. This is a linked-library version warning, not program output; its triggering component has not been identified.

## Modification Exercises

Make both changes on fixture copies in a **temporary directory**. Do not modify the repository’s `accounts-unsorted.txt`:

1. Swap the first two lines in a copy. Run the program and confirm that output remains sorted by account number and the input/output counts are equal.
2. Start again from the original fixture and append a 27-character record to a copy: account number `A000000006`, customer number `C0001006`, balance digits `000000001`. Confirm it sorts last and the count becomes `005`.

See [`exercise.md`](./exercise.md) for the complete prompts and expected results, and [`answer.md`](./answer.md) for reference answers.

## Extension Exercise

Add a second sort key: account number ascending, then balance descending. Prepare at least two records with the same account number and different balances, observe the result, and explain whether the program depends on the relative order of equal-key records when only one key is declared. Record the modified `SORT` key declaration and complete output. Do not first load all records into `OCCURS`, and do not use `USING`/`GIVING` to bypass this lesson’s two procedures. See [`exercise.md`](./exercise.md); no answer is provided.

## Follow the Real Workflow

This lesson sits at the start of the reconciliation chain:

1. Upstream exports the account master and daily transactions without guaranteeing their order. Lesson 19 taught how to read two files concurrently.
2. **Here:** sort the master. The output procedure produces an ascending record stream.
3. Pass that ordered stream to Lesson 20’s matching scan and merge it with the equally ordered transactions to classify matched, master-only, and transaction-only records.
4. Validated matches flow onward to result-file writing, error routing, and ultimately the complete Lesson 32 reconciliation batch.

There is **no file** between steps 2 and 3. Sorted records flow one by one in memory. This lesson displays them; Lesson 22 combines sorting, matching, and writing results in one program. An unnecessary intermediate file would add naming, overwrite, and cleanup concerns.

## What Happens If This Code Goes into Production

- **Scheduler:** the overnight batch scheduler, after checking that inputs are ready and before the matching job.
- **Who reads the output:** the on-call operator first checks the exit code and whether `input record count` equals `output record count`. A mismatch needs investigation that night.
- **Who is called when it fails:** a nonzero `SORT-RETURN` or unequal counts alert operations/on-call, then development.
- **Downstream consumer:** the ordered record stream feeds the matching scan; Lesson 22 writes results to files.
- **Most likely first-month incident:** assuming upstream files are sorted. An undocumented ordering agreement can change when the export method changes. The program will not necessarily alert, and reconciliation discovers the difference the next day.

The limits are explicit: this lesson orders records but does not write result files, total amounts, classify rejects, or provide production-grade retries and recovery. Sort-key rules, duplicate-key policy, empty-file behavior, source-file status, and batch action after a sort failure must be agreed with upstream and downstream owners. Without those agreements, this is not ready to deploy as a reconciliation batch.

## References

- [GnuCOBOL Programmer’s Guide: File-Based SORT](https://superbol.eu/gnucobpg/chapter7.html#file-based-sort)
- [GnuCOBOL Programmer’s Guide: RELEASE](https://superbol.eu/gnucobpg/chapter7.html#release)
- [GnuCOBOL Programmer’s Guide: RETURN](https://superbol.eu/gnucobpg/chapter7.html#return)
- [GnuCOBOL Programmer’s Guide: SD file description](https://superbol.eu/gnucobpg/chapter6.html#fileasort-description)
- Course home: [README.md](../../README.md)
