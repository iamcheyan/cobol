---
_translated_from: lessons/08_control-flow-practice/README.md
_translated_by: site-src/translation agent
---

# Lesson 08 — Integrated Practice: Assembling Seven Lessons of Components into a Miniature Transaction Batch

Over the first seven lessons you have accumulated a collection of components: data items, `MOVE`/`COMPUTE`, `IF`, `EVALUATE`, `PERFORM` loops, and named paragraphs. This lesson introduces no new components; it does only one thing — connects them into a processing chain that "takes a transaction in, evaluates it, posts it, and logs it", while making that chain report "how many total, how many accepted, how many rejected" on its own. Balances in real batch systems roll forward transaction by transaction in just this way, so "whether the connection is correct and auditable" is the dividing line between code that can be delivered and code that cannot.

## The Business Setting

At 1:00 a.m., the end-of-day batch begins. Transactions generated across counters and mobile apps during the day have already been ordered sequentially by upstream systems, waiting to be posted transaction by transaction overnight. What the program needs to do sounds deceptively simple: walk from top to bottom, adjust balances for postable items, record reasons for non-postable items, and report final totals.

Yet ordering is completely unforgiving. Transaction 003 is a withdrawal slip for 1500.00; whether it can be fulfilled depends on whether transactions 001 and 002 were accepted — balances roll forward cumulatively, they are not looked up statically. That is why this lesson cannot look at "just one transaction" like earlier lessons: **the outcome of the previous transaction is the prerequisite for the next.**

In my experience with overnight batch incidents, rarely is a single statement written wrong. Far more common is this: the job finishes, and the total count in the log is off by one from the detail items — but nobody can pinpoint which transaction was dropped. That is why an experienced team lead asks only one question before going live: **"Is every single transaction accounted for?"** If you can answer him on the spot with two numbers — "5 processed = 2 accepted + 3 rejected" — the batch passes; if you cannot, you have to dig from the beginning.

Institutions, amounts, and times in the scenario below are educational demo materials, not data from any real institution. This lesson also does not yet take file input; the five transactions are hardcoded inside the program (real files start in [Lesson 15](../15_sequential-file-read/README.md)).

## Why Learn This Now

You might think: I've written `IF`, I've written `EVALUATE`, I've run `PERFORM`; can't I just piece together five transactions following previous lessons? Isn't this lesson pure review?

No. Exercises in earlier lessons each had you focus on a single slice of logic: evaluating an amount, classifying a transaction code, running three loop cycles. A real batch affords no such luxury — it is a continuous chain where **the execution result of one transaction alters the prerequisites of the next**.

To take a concrete example: whether withdrawal 003 can pass depends on what the balance is when it runs; and that balance was computed by transactions 001 and 002. If you move the "is balance sufficient" check after "deduct balance", or if any rejection path accidentally updates the balance, the outcomes of transactions 003, 004, and 005 will all warp together. The compiler will not stop you from doing this, and a five-sample test might not make it obvious — but it will cause customers arriving at counter opening at 9:00 a.m. to see wrong balances.

There is another, subtler trap: as branches multiply, counter updates are easily missed or double-counted. Balance updates and tally updates must occur in pairs along the exact same path — add to accepted count when accepted, add to rejected count when rejected, with each transaction falling into exactly one side. If it falls into neither or both, the program throws no error, but month-end reconciliation will be unable to explain the numbers.

Therefore, this lesson uses five fixed sample cases to expose the four most common traps when "connecting everything together": execution ordering, rejections leaving state untouched, one outcome per transaction, and final tally closure.

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** Simply put, this lesson introduces no new syntax. It asks you to connect six things you already know: storing state in fields (opening balance, current balance, transaction code, amount, three counters), modifying balances with `COMPUTE`, evaluating sign and balance sufficiency with `IF`, identifying transaction codes with `EVALUATE`, iterating transaction by transaction with `PERFORM VARYING`, and organizing stages into initialization/processing/summary blocks with named paragraphs. Once assembled, you attach a statement of proof — the **counting invariant**: `処理件数 = 承認件数 + 拒否件数`.

**What business problem it solves.** It upgrades "every statement is correct" to "the whole reconciles":

- **Execution order**: Balances accumulate sequentially, so ordering is itself a business rule that cannot be rearranged casually.
- **State isolation**: Rejection paths increment only the rejection counter and never touch balances — a failed transaction must not corrupt subsequent calculations.
- **Uniqueness of destination**: Each transaction must be recorded in either accepted or rejected counts, neither omitted nor duplicated.
- **Auditability**: Three counters lock the results together at the end, verifiable by anyone with a pocket calculator.

**When to be watchful, and what happens when misused.** Do not confuse "five sample cases ran cleanly" with "accounting logic is correct." Running samples cleanly proves only that this specific input path worked; boundaries might still be wrong — for instance, when a withdrawal amount is **exactly equal** to the balance, does it pass or fail? This lesson's exercises will have you run this scenario yourself. Nor should you treat counters as decorations: their purpose is to let someone verify "no transactions were dropped" in one sentence; having counters displayed without anyone checking their relationship is more dangerous than having none at all, because it creates a false sense of security.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you will be able to:

- Use `WORKING-STORAGE` fields to store opening balance, current balance, transaction code, signed amount, and three tally counters.
- Use `PERFORM VARYING` to sequentially process five fixed samples, clearly articulating loop start and end boundaries.
- Use `EVALUATE` to select deposit, withdrawal, or unknown code paths by transaction code, using nested `IF` statements to validate positive amounts and available balance.
- Trace transaction by transaction how each affects shared balance and tallies, using the counting invariant `処理件数 = 承認件数 + 拒否件数` to verify no transactions were dropped.
- Organize initialization, sample loading, transaction processing, and reporting into callable named paragraphs.

Limits: Sample data is written directly in `2100-LOAD-SAMPLE`; the program does not read terminals, files, or databases; it has no persisted state, and repeated runs yield identical results. File state, auditing, concurrency, and restart strategies required by production accounting are outside this lesson's scope; see Lesson 15 onward and [Lesson 26](../26_error-handling/README.md).

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (without `-std=cobol85`), source file in fixed format.
- Linux terminal; this lesson does not depend on databases or additional tools.
- No input fixtures, no output data files; compilation artifacts are written to `build/` and can be deleted and recreated directly.

## Five Sample Transactions and Decision Rules

The program starts from `1000.00` and processes five fixed transactions by sample index:

| Number | Code | Amount | Processing Rule | Balance Change |
|---|---|---:|---|---:|
| 001 | `D` | 125.50 | Positive deposit, accepted | 1000.00 → 1125.50 |
| 002 | `W` | 40.10 | Positive withdrawal with sufficient balance, accepted | 1125.50 → 1085.40 |
| 003 | `W` | 1500.00 | Amount exceeds current balance, rejected | Unchanged |
| 004 | `D` | -5.00 | Deposit amount is not positive, rejected | Unchanged |
| 005 | `X` | 25.00 | Unknown code, rejected | Unchanged |

Each of the three rejections has its own distinct reason (insufficient funds, non-positive amount, unrecognized code), appearing in the output as three distinct reason codes — **rejections must also explain why**, otherwise those auditing the run can only guess.

Counting invariant: `処理件数 = 承認件数 + 拒否件数`, which in this lesson is `5 = 2 + 3`.

To reiterate boundaries: this batch is designed to practice control flow; the five samples are fixed data inside the program (demonstration data), not real transactions read from an external file. The program also does not implement persistence, audit, concurrency, or restart rules required by production accounting.

## Who Manages What in the Program

For complete source code, see [`lesson.cob`](./lesson.cob). It uses independent fields to store opening balance, current balance, transaction code, signed amount with leading separate sign, sample index, and three tally counters. Amounts uniformly carry two decimal places; storage and calculation behavior reflect verification on this platform's GnuCOBOL.

| Paragraph | Responsibility | Key Statements |
|---|---|---|
| `0000-MAIN` | Invokes initialization, batch processing, and reporting in order | `PERFORM`, `STOP RUN` |
| `1000-INITIALIZE` | Sets current balance and clears counters | `MOVE` |
| `2000-PROCESS-BATCH` | Loops from 1 to the last sample, loading and processing each transaction | `PERFORM VARYING`, paragraph `PERFORM` |
| `2100-LOAD-SAMPLE` | Maps index to transaction code and amount | `EVALUATE`, `MOVE` |
| `2200-CLASSIFY-AND-POST` | Validates transaction by code, updating balance or rejection tally | `EVALUATE`, nested `IF`, `COMPUTE` |
| `9000-REPORT` | Outputs processed count, outcome counts, and final balance | `DISPLAY` |

These six paragraphs **share the exact same set of `WORKING-STORAGE` fields** — this is why they can work as a relay, and also where caution is required: if any section modifies the balance, all subsequent paragraphs see the updated value. When processing each transaction, the outer loop invokes the loading paragraph first, then invokes the classification and posting paragraph, and finally increments the processed counter. When a paragraph invoked by `PERFORM` finishes, control returns to the call site, and the loop proceeds to the next transaction.

A quick note on `WHEN OTHER` in `2100-LOAD-SAMPLE`: it catches cases where "index exceeds sample bounds." In this lesson the upper bound is 5 and the sample count is 5, so the fallback is never reached; but if someone alters the upper bound while forgetting to add sample data, it catches the error rather than letting the program calculate using residual values from the previous transaction — a trap you already explored in Lesson 06.

## Tracing It Step by Step

1. The main paragraph executes `1000-INITIALIZE`: sets current balance to opening balance, zeroes the three counters, and prints batch start and opening balance.
2. `PERFORM VARYING` increments the index from 1 to 5. The upper bound condition is written as `WS-SAMPLE-INDEX > WS-LAST-SAMPLE`, meaning index 5 is also processed (the "strictly greater" boundary from Lesson 06).
3. `2100-LOAD-SAMPLE` uses `EVALUATE` to load code and amount by index, printing the original record values.
4. `2200-CLASSIFY-AND-POST` branches by code: `D` for deposit, `W` for withdrawal, everything else into `WHEN OTHER`.
5. Deposits add to balance and increment accepted count only if the amount is greater than zero; non-positive amounts increment the rejection counter.
6. Withdrawals use two evaluation levels: first checking if amount is greater than zero, then checking if amount is less than or equal to current balance. Deductions occur only if both are satisfied — **exact equality is also permitted**, reducing balance to zero; otherwise it rejects for insufficient funds.
7. Unknown codes increment rejection count, recording the reason as `UNKNOWN_TRANSACTION_CODE`.
8. After processing each transaction, the outer loop increments the processed counter exactly once — inside the loop body, outside any branch — preventing omissions or double-counting.
9. After the loop completes, the main paragraph invokes `9000-REPORT`: two accepted, three rejected out of five transactions, with a final balance of `1085.40`.

Transaction processing order is part of the business rules: each accepted transaction alters available balance for subsequent withdrawals. Rejection paths do not modify balances.

## Run and Observe

The program reads no terminal, file, command line argument, or database input, and generates no data files, producing identical results in any directory. The following explains execution from this lesson directory.

**Input:** No external input. The five samples are in-program fixed data in `2100-LOAD-SAMPLE`.

**Commands and roles:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_08 lesson.cob    # 编译并生成可执行文件
./build/lesson_08                              # 运行程序，输出写到标准输出
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observed Item | Expected Value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compilation diagnostics |
| Standard output | 16 lines, see code block below |
| Process exit code | `0` |

```text
バッチ=START
期首残高=0001000.00
レコード=001 符号=D 金額=+00125.50
結果=ACCEPTED 理由=DEPOSIT
レコード=002 符号=W 金額=+00040.10
結果=ACCEPTED 理由=WITHDRAWAL
レコード=003 符号=W 金額=+01500.00
結果=REJECTED 理由=INSUFFICIENT_FUNDS
レコード=004 符号=D 金額=-00005.00
結果=REJECTED 理由=AMOUNT_NOT_POSITIVE
レコード=005 符号=X 金額=+00025.00
結果=REJECTED 理由=UNKNOWN_TRANSACTION_CODE
処理件数=005
承認件数=002
拒否件数=003
最終残高=0001085.40
```

**Do not just look at the last line; calculate it yourself:** `1000.00 + 125.50 = 1125.50`, `1125.50 - 40.10 = 1085.40`; the remaining three all enter rejection without touching a penny of the balance. Then check counts: 5 in, 5 out, `2 + 3 = 5`. Both steps can be computed on paper — if you cannot calculate this before going live, the logic has not been hooked up properly.

**Output field mappings (Japanese output → meaning):** `バッチ=START` = batch start; `期首残高` = opening balance; `レコード` = sample index; `符号` = transaction code; `金額` = transaction amount; `結果` = accepted/rejected; `理由` = decision reason code; `処理件数` / `承認件数` / `拒否件数` = processed / accepted / rejected counts; `最終残高` = final balance.

Leading zeros and signs on amounts come from field `PIC` and `SIGN IS LEADING SEPARATE CHARACTER` display formatting; `V` is merely an assumed decimal point location omitted during display. The balance field is `PIC 9(7)V99`, so `1085.40` displays as `0001085.40`.

**Unverified items (as noted previously):** When running the executable in this workspace, standard error outputs an extra line: `Warning: program compiled against libxml 212 using older 209`. This is a library version warning from the runtime environment, not business content printed by this program; **why unverified**: the triggering component has not been located, and verifying business results does not require it. Real output appears on standard output, with an exit code of `0`.

## Modification Exercise

Perform each of the two modifications starting from the original [`lesson.cob`](./lesson.cob) **without combining them**; inspect complete output each time rather than staring only at the final balance line.

1. Change `WS-OPENING-BALANCE` initial value from `1000.00` to `2000.00`, compile and run, recording `処理件数`, `承認件数`, `拒否件数`, and `最終残高`. After finishing, reflect: the only transaction that reversed was 003 — changing the opening balance altered available funds for subsequent withdrawals, a direct consequence of "sequential accumulation."
2. Change the withdrawal amount of sample 003 from `1500.00` to `1085.40`, compile and run, confirming whether "amount exactly equal to balance when reaching that transaction" accepts or rejects, noting final balance and both outcome counters. This is the boundary most worth running by hand in this lesson.

For full problem details and expectations, see [`exercise.md`](./exercise.md); for reference answers, see [`answer.md`](./answer.md).

## "Apply It Elsewhere" Exercise

Extend the batch to process a sixth fixed transaction: choose the transaction code and amount yourself, explain whether it should be accepted or rejected, and trace step-by-step balance changes and final three counters. Require at least one boundary where "withdrawal amount exactly equals current balance", and confirm that `処理件数` increments only by the number of transactions actually processed. Do not modify data while forgetting to update the final sample index and loading logic. Still use fixed samples without introducing files, tables, or databases. See [`exercise.md`](./exercise.md) for details; no reference answer is provided for this exercise.

## Walking Through a Real Workflow

Placing this lesson's chain into that 1:00 a.m. batch, here is how it connects before and after:

1. **Upstream delivers data.** This lesson's data is hardcoded inside the program; in a real batch it comes from files — [Lesson 15](../15_sequential-file-read/README.md) has you open and read files yourself for the first time, while [Lessons 17](../17_fixed-length-files/README.md)/[18](../18_csv-processing/README.md) handle fixed-length records and CSV.
2. **This lesson's link.** Evaluating transaction by transaction: adjusting balances for postable items, flagging non-postable items with reasons. The deliverable of this stage is "accept/reject + reason + three counters."
3. **Rejected items must be routed separately.** Writing rejection details to files is the job of [Lesson 16](../16_file-writing/README.md); customer service agents answering calls about "why didn't my transaction go through yesterday" query that file.
4. **Numbers must leave audit trails.** Recording batch start/end and rejection details in logs is covered in [Lesson 27](../27_logging/README.md); distinguishing "business rejections" from "system failures" (when to alarm versus when to merely reject a transaction) is covered in [Lesson 26](../26_error-handling/README.md).
5. **Final rollup.** Persisting balances and statuses into databases is covered from [Lesson 29](../29_embedded-sql/README.md) onward; chaining the entire overnight sequence into a reconcilable project is covered in [Lesson 32](../32_bank-reconciliation-project/README.md).

Along this chain, "counts not matching" must have a verifiable statement — in this lesson, that statement is `処理件数 = 承認件数 + 拒否件数`.

## What Happens if This Code Goes to Production

- **Who schedules it**: The overnight batch scheduler, typically placed after "file readiness checks" and before end-of-day rollups. It looks only at exit codes, not your screen.
- **Who reads its output**: Operators check exit codes first, then inspect the three counters. If numbers do not match, investigation begins that night rather than waiting for morning counter opening.
- **How the next system connects**: In a real system, this link decides where balances flow, directly informing subsequent reports and customer queries; this lesson only displays results on screen without handing off to downstream systems.
- **Most common first-month incidents**: Not syntax errors, but "wiring errors" — a rejection path touching balances, counters missed or double-counted, or swapped evaluation orders distorting subsequent transactions. Such errors might cause minor discrepancies in five samples, but across tens of thousands of records they create irreconcilable accounts.
- **What it hasn't done yet**: Reading files, validating records, writing result files, separating business rejections from system failures, persistence, and reruns. Nor does it have account authorization, concurrency control, or duplicate request detection. These are addressed starting in Lessons 15, 16, 26, and 29.

To be explicit: this lesson proves that "in-memory sequential rules are connected properly, counters close cleanly, and results can be reconciled by hand", **not** that "this is a validated accounting system."

## References

- [GnuCOBOL Programmer’s Guide: PROCEDURE DIVISION Sections and Paragraphs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-Sections-and-Paragraphs)
- [GnuCOBOL Programmer’s Guide: Procedural PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Procedural-PERFORM)
- [GnuCOBOL Programmer’s Guide: EVALUATE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#EVALUATE)
- Repository Course Home: [README.md](../../README.md)
