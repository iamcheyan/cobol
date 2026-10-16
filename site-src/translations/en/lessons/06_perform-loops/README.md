---
_translated_from: lessons/06_perform-loops/README.md
_translated_by: site-src/translation agent
---

# Lesson 06 — PERFORM Repeated Processing: Run the Same Logic Across One Hundred and Twenty Thousand Records

## The Business Setting

At 0:30 in the morning, the city commercial bank's end-of-day batch starts running. The transactions generated during the day at the teller windows and on the mobile banking app have been exported as a file and dropped in a shared directory.

Your mentor tells you one sentence, just remember it: **"How many there actually are, you only find out at seven in the evening when the summary runs."**

What that sentence means is: when you write code, you cannot assume "just three records." It might be 120 records, it might be 120,000, and one day there might be none at all — and your program has to run the same way in every case.

So what are you going to do? Copy the "process one transaction" code one hundred and twenty thousand times?

Nobody does that in real life. The pattern for batch processing is: **write "how to process one record" once, then let the machine run it N times**. What this lesson teaches is exactly that "run N times" syntax.

While we are at it, let me mention a real-world high-incident area. The bugs that loops cause in banks almost all get stuck at the boundary:

- Does the upper-bound record count or not? If you write "less than the upper bound," the last record is processed forever less, and the ledger is short one record;
- One day when there is not a single one, will the program still obediently run one round and read a record that does not exist?
- Does the index start from 1 or from 0? Upstream numbers from 1, and you start from 0, so the very first record is misaligned from the start.

These three are not syntax issues — they are **business issues**. This lesson will explain them through.

## Why Learn This Now

In the previous lesson you could already use `IF` to judge "this record should be accepted or rejected." But that only handled one record: the code ran from top to bottom once, and that was it.

There is no such thing as "one record" in bank batch processing. A transaction file has at the low end hundreds of entries, at the high end hundreds of thousands, and the program must be able to walk through the whole file without knowing the exact count in advance. That is the purpose of "repetition" — and the tool COBOL gives you is called `PERFORM VARYING`.

You may say you already know `for` loops. Right, the idea is similar, but there are two places where you need to overwrite your intuition:

1. **It enters the loop body without checking the condition.** COBOL's `UNTIL` is "look once before each round begins," and when the condition is true it simply does not enter at all. So when "there is not a single record" it honestly does not run even once — which is exactly what we want.
2. **The boundary is something you must calculate clearly.** If you write the loop as "exit when index greater than the upper bound," then the upper-bound record will be processed honestly; if you write "greater than or equal to," the last record is lost forever. Places where a single cent matters — those are exactly the spots a code reviewer will stare at.

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** A loop with a counter: give the index a starting point (`FROM`), a step size (`BY`), an exit condition (`UNTIL`), and then repeat the loop body until the condition holds. The index, the step, and the condition together decide "how many rounds actually run."

**What business problem it solves.** It separates "how to handle one record" from "how many records to handle." The business code only cares about "how one record is processed"; the count is left to the loop. That way:

- Upstream gives 3 records today and 120,000 tomorrow, and not a single character of the program code needs to change;
- The reviewer can see in one place whether "the boundary is inclusive or exclusive," without hunting for it across a dozen sites;
- When something goes wrong, add one counter and you can answer "how many records were actually processed" — that is the first sentence of reconciliation.

**When it is still not enough.** When you need "keyed lookup" or "a small in-memory table," brute-forcing it with a loop is slow and clumsy (that is lessons 11–13's job, `OCCURS`/`SEARCH`); when you need to iterate over a database result set, you use a cursor rather than this counted loop (lesson 30).

## Capabilities and Limits After Completing This Lesson

After finishing this lesson you can:

- Write `PERFORM VARYING <索引> FROM <起点> BY <步长> UNTIL <退出条件> ... END-PERFORM`, and explain clearly what each part is responsible for.
- Calculate how many rounds a loop segment runs, and explain how the starting point, the step size, and the exit condition each affect the round count.
- Explain clearly why "exit only when the index is greater than the upper bound" causes the upper-bound record itself to be processed.
- Change the upper bound to `0`, `1`, `3`, `4` respectively and run each once, observing how the output and the count change in the four cases of zero records, one record, normal, and "outside the sample range."
- Use `END-PERFORM` to mark off the loop range, and report the actual number of processed records after the loop ends.

Limits: this lesson's "transactions" are only three, and they are fixed samples written inside the program — in a real batch they come from a file (from lesson 15 onwards). The loop's upper bound is a field, and the program will not validate "whether data for this upper bound actually exists" — that pitfall this lesson will deliberately step on to show you. In-memory tables (`OCCURS`) are in lesson 11; file reading is in lesson 15.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not pass `-std=cobol85`), source files in fixed format.
- A Linux terminal; this lesson does not depend on a database or additional tools.
- Syntax check and compilation generate executables inside `build/`; you may remove and rebuild at any time.

## How the Loop Is Actually Written

```cobol
PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
    UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
    ...loop body...
END-PERFORM
```

Going piece by piece, line by line:

- `FROM 1`: the index starts at 1 from the moment it enters. Note this is **set by the loop itself**, and has nothing to do with the initial value you wrote in `DATA DIVISION`.
- `BY 1`: after each round the index increments by 1. To skip two at a time (for example, processing only odd-numbered records), write `BY 2`.
- `UNTIL 索引 > 上限`: the check is made before each round begins. Once the condition holds, this round is skipped and the loop ends.
- The operator used is **strictly greater than**, so when "index == upper bound" the condition is still false, and this round runs as usual. That is where "the upper-bound record will also be processed" comes from.
- `END-PERFORM` brackets the loop range. Do not casually write a period inside the loop body — a period will close a larger statement range prematurely, and that kind of bug is very annoying to track.

## Sample Program: Three Fixed Transactions

The full source is [`lesson.cob`](./lesson.cob), written in fixed format.

One thing needs to be said up front here: **this lesson has not yet taught tables** (that is lesson 11), so "the 1st record, the 2nd record, the 3rd record" is for the moment hard-picked by sequence number using `EVALUATE`:

| Sequence | Symbol | Amount |
|---:|---|---:|
| 1 | `D`（存款） | 125.50 |
| 2 | `W`（取款） | 040.10 |
| 3 | `T`（转账） | 075.00 |

This is only scaffolding — once lesson 11 gives us the `OCCURS` table, the same loop will be rewritten to look up by sequence number in the table, and that is the real batch writing style.

The division of labor among the three fields in the program:

| Field | PIC / initial value | What it is for |
|---|---|---|
| `WS-LAST-SAMPLE` | `9` / `3` | the sequence number of the last record, **inclusive** of this number |
| `WS-SAMPLE-INDEX` | `9` / `0` | the loop's counter; set to 1 by `FROM 1` at the moment of entry |
| `WS-PROCESSED-COUNT` | `9(3)` / `0` | increments by 1 after each round; after the loop ends it equals "how many records were actually processed" |

One last reminder about the numeric side: this upper bound only governs "how many rounds to run"; **it does not check whether the data actually exists**. If you change the upper bound to 4, the loop still runs its fourth round, and `EVALUATE`'s `WHEN OTHER` prints `例=UNMAPPED` — a sample that does not exist. In a real system, "configuration out of sync with data" is exactly the kind of problem you catch with logs and counters.

## Step-by-Step View of How It Runs

1. `WORKING-STORAGE` first sets the "last sequence number" and the "processed count" properly. The index does not need to be touched — `FROM 1` will set it.
2. First print one line showing the current upper bound, so you have something to compare against.
3. `PERFORM VARYING` begins: set the index → check `UNTIL` → if the condition is false, enter the loop body.
4. Inside the loop body, `EVALUATE WS-SAMPLE-INDEX` picks out the corresponding symbol and amount by the current sequence number and prints them.
5. One round ends; `COMPUTE` increments the processed count by 1.
6. After the loop ends, print the processed count. When the upper bound is 0, the first check is already "1 > 0" holds, the loop body never runs even once, and the count stays at `000`.
7. `STOP RUN.` ends normally.

## Run and Observe

This lesson does not read keyboard, file, or database, so it produces the same result no matter which directory you run it in.

**Input:** none. The three samples are hard-coded inside the program; how many rounds the loop runs is determined by the initial value of `WS-LAST-SAMPLE`.

**Commands and what each step does:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # syntax check only
cobc -x -Wall -o build/lesson_06 lesson.cob    # compile and produce the executable
./build/lesson_06                              # run; output goes to standard output
echo $?                                        # check the exit code
rm -rf build                                   # clean up the produced executable
```

**Expected results (upper bound is 3 by default):**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, with no compile diagnostics |
| Standard output | 5 lines, see the code block below |
| Process exit code | `0` |

```text
最終サンプル番号=3
例=001 符号=D 額=125.50
例=002 符号=W 額=040.10
例=003 符号=T 額=075.00
処理件数=003
```

**The Japanese words in the output:** `最終サンプル番号` is "the last sample number," `例` is "which sample," `符号` is the transaction symbol (`D` deposit, `W` withdrawal, `T` transfer), `額` is the amount, `処理件数` is the number of records actually processed.

**Environment details actually observed:** at runtime, standard error will show `Warning: program compiled against libxml 212 using older 209`; this is a runtime environment linked-library warning, not business content printed by the program. The actual output is on standard output, and the exit code is 0.

## Modification Exercise

Starting from the original [`lesson.cob`](./lesson.cob), change the initial value of `WS-LAST-SAMPLE` to `0`, `1`, `3`, `4` in turn; recompile and run each time; record: how many samples were displayed this run, what `WS-PROCESSED-COUNT` was, and whether the last round fell into `UNMAPPED`.

These four cases correspond exactly to zero records, one record, normal, and out-of-range — these are the few numbers that must be verified one by one before a real batch goes live. The full prompt and expectations are in [`exercise.md`](./exercise.md); the reference answer is in [`answer.md`](./answer.md).

## "Apply It Elsewhere" Exercise

Replace the fixed samples with four payment records, still using `PERFORM VARYING` to process them in sequence: each round outputs the sequence number, the category, and the amount, and finally reports how many records were processed in total; when the last sequence number is 0, not a single record may be processed. For now still use `EVALUATE` to fetch samples by sequence number; do not bring in tables or files early. The prompt is in [`exercise.md`](./exercise.md); no answer is provided for this question.

## Walking Through a Real Workflow

Putting it into that 0:30 a.m. batch:

1. The previous day's transactions get exported as a file and land in the shared directory (this step becomes "you read the file by hand" in lesson 15).
2. Your program opens the file, reads one record and processes it — "process one record" is exactly what the loop body in this lesson does, and "how many records to read" is decided by the file's own end, not by an upper bound you hard-coded.
3. After the run, print the total record count and write it into the log (lesson 27). The next day this number will be reconciled by someone against the upstream record count: **a mismatch means some records were dropped or processed twice**.

So that tiny `処理件数` in this lesson is not decoration — it is the first line of defense in real reconciliation.

## What Happens if This Code Goes to Production

- **Who schedules it**: the nightly batch scheduler, usually placed right after the "file-ready check."
- **Who reads its output**: the on-duty person first looks at the exit code, then at the record count. If the count is off, they have to investigate that very night.
- **How the next system picks it up**: the processed result will be written as a result file handed to the downstream system (lesson 16), or written into the database (from lesson 29 onwards).
- **The accident most likely to occur in the first month**: the boundary is wrong and the last record is dropped. This kind of bug cannot be seen on the ten-record test data, but it will certainly explode on the one-hundred-and-twenty-thousand-record night — that is why this lesson forces you to run the four cases 0/1/3/4 one by one.
- **What it has not yet done**: read files, validate records, handle read failures. If the upper bound is wrong it will only run one extra round printing `UNMAPPED`, and will not stop and raise an alarm on its own. These are added in lesson 15 and lesson 26.

## References

- [GnuCOBOL Programmer’s Guide：PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PERFORM)
- [GnuCOBOL Programmer’s Guide：Inline PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Inline-PERFORM)
- [GnuCOBOL Manual：PERFORM loop example](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- Course home in the repository: [README.md](../../README.md)