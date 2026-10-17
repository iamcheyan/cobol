---
_translated_from: lessons/07_paragraphs/README.md
_translated_by: site-src/translation agent
---

# Lesson 07 — Named Paragraphs: Breaking the Main Batch Flow into Named Stages

## The Business Setting

At 1:10 a.m. on Friday, the city commercial bank's end-of-day batch is running (educational scenario; institutions, amounts, and times are fabricated). Three years ago, this job had only a hundred lines; today it has grown to nine hundred: initialization, posting, summarization, and printing are all crammed into `PROCEDURE DIVISION`, interspersed with two emergency patches applied back in the day.

At 2:03 a.m., an upstream engineer calls asking: "Why is tonight's balance summary all zeros?" The on-duty newcomer, Xiao Lin, checks the logs, but sees a picture of peace — no errors, no exceptions, exit code `0`. The scheduler marked the job successful long ago, and several downstream jobs depending on it ran to completion as usual.

Only during daylight reconciliation is the problem uncovered: a zeroing step was moved after posting, wiping the newly computed balance right back to zero. No money was lost, but the ledger numbers were completely wrong, and the system never uttered a peep.

This is precisely what paragraph names are meant to solve. It is not an aesthetic preference for "clean code", but leaving trail markers for operations staff and successors: when something breaks in the middle of the night, you need to point to a line in the log and say "this was printed by `2000-PROCESS`". Even more critical than localization is **order** — once the sequence of initialization, processing, and summarization is reversed, the program still runs to completion and still returns 0; the mistake only surfaces during next-day reconciliation.

## Why Learn This Now

In the previous lesson, you already learned how to run the same logic N times. Now look back at the program you wrote: all statements are laid out flat from top to bottom inside `PROCEDURE DIVISION`.

At thirty or forty lines, that is fine — you can scan it in one glance. But batch programs do not stop at forty lines: a block for reading files, a block for validating amounts, a block for posting, a block for summary tallies — hundreds of lines are the norm. When you get called out of bed, what you want to know most is "which section is broken", not re-reading from line one.

You might think: can't I just label them with comments?

Comments are good, but they cannot be executed. Writing `PERFORM 1000-INITIALIZE` in the main flow tells the reader at a glance that this step is initialization; a comment saying "initialization starts below" offers no guarantee three months later that it still matches reality. Even worse is ordering — comments will not enforce that "initialization must run before posting."

What `PERFORM paragraph-name` does is place "what this section is called" and "when it is invoked" together in the main flow, plain for everyone to see.

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** Named paragraphs: giving a block of logic a name inside `PROCEDURE DIVISION` (such as `1000-INITIALIZE`), and writing `PERFORM 1000-INITIALIZE` elsewhere when you want to execute it. The name starts in Area A, and statements start in Area B as usual. When the last statement in that section finishes, control returns automatically to the line following `PERFORM` — it is a "jump over, execute, and return", not launching a new program.

**What business problem it solves.**

- **The main flow turns into a readable checklist.** Previously, you had to read nine hundred lines to understand what the batch did; now reading those few lines in the main paragraph is enough.
- **Logs and code match up.** Each stage logs its own marker, allowing you to see directly which step broke when an incident occurs (the `段階=...` in this lesson's output serves this purpose).
- **Order dependencies are exposed in the open.** The three words initialization, processing, and summarization inherently express sequence; a code reviewer scanning the main paragraph can immediately ask: "Is this order correct?"

**When not to use it.** Paragraphs exist only within the current program unit; they are not independent subprograms. When another batch needs the same amount rules, what you want is `CALL` (Lesson 24), not copying and pasting the paragraph. There is also an easy-to-miss trap: paragraphs share the same `WORKING-STORAGE`, without the scoping isolation of function arguments — Exercise 2 in this lesson will have you step into this pitfall firsthand.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you will be able to:

- Define named paragraphs in `PROCEDURE DIVISION`, starting paragraph names in Area A.
- Execute paragraphs using `PERFORM paragraph-name`, and explain when control returns to the statement following `PERFORM`.
- Deconstruct the main batch flow into initialization, processing, and final summary stages, and arrange their invocation sequence in the main paragraph.
- Explain why paragraphs share the current program's `WORKING-STORAGE`, and why swapping invocation order alters the final balance.
- Articulate why in-program `PERFORM` and the `CALL` subprograms learned later are not the same thing.

Limits: This lesson uses only hardcoded amounts in source code, without reading files, command line arguments, or databases, nor does it use `CALL` to invoke independent subprograms. Cross-program interfaces and parameter contracts expand in Lessons 23–25 (Copybooks, `CALL`, `USING`), and record-level error handling expands in Lesson 26.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (without `-std=cobol85`), source file in fixed format.
- Linux terminal; this lesson does not depend on databases or additional tools.
- Syntax checking and compilation generate an executable under `build/`, which can be deleted and recreated.

## How Paragraphs and PERFORM Are Actually Used

Paragraph names are written in `PROCEDURE DIVISION`, and this repository's fixed-format convention requires them to start flush in Area A. `PERFORM 1000-INITIALIZE` executes statements in that paragraph; reaching the next paragraph or the end of the procedure range returns control to the statement after `PERFORM`.

Here is a detail that easily confuses beginners: paragraphs share the current program's `WORKING-STORAGE`. `PERFORM` does not create a new program, nor does it duplicate data. Thus a balance computed in `2000-PROCESS` is directly readable by `9000-FINALIZE` — this is a handy feature in this lesson, but also the source of the trap in Exercise 2.

This example places `0000-MAIN` first. The program begins at the main paragraph, sequentially PERFORMing initialization, computation, and summarization; `STOP RUN.` is placed before subsequent paragraph definitions, terminating normal sequential execution so the main flow does not "fall into" the paragraph definitions below. Each of the three invoked paragraphs performs only one task.

Paragraph names are a team convention, not business logic. The GnuCOBOL manual permits procedure names composed of letters, digits, hyphens, and underscores, such as `0100-Read-Transaction`; names cannot begin or end with a hyphen or underscore.

### Non-Example → Good Example: Same Balance, Two Ways of Writing

Non-example — order reversed, program stays silent:

```cobol
       0000-MAIN.
           PERFORM 2000-PROCESS
           PERFORM 1000-INITIALIZE
           PERFORM 9000-FINALIZE
           STOP RUN.
```

Good example — placing zeroing at the very front:

```cobol
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
           STOP RUN.
```

Both code snippets compile, both run to completion, both exit with code `0`, and the compiler will not warn you about a thing. The difference is solely in the output: the last line of the non-example is `最終残高=0000000.00`, because the money was wiped clean by the initialization that ran afterwards. This is why business misuses are more expensive than syntax errors — the compiler catches syntax errors that same night, while ordering errors wait for next-day reconciliation.

## Complete Example

For complete source code, see [`lesson.cob`](./lesson.cob), written in fixed format.

The amounts in the example are hardcoded demo data: opening balance `1000.00`, deposit `125.50`, withdrawal `40.10`, with the processing paragraph calculating a closing balance of `1085.40`.

| Paragraph | Responsibility | Key Statements |
|---|---|---|
| `0000-MAIN` | Invokes the three stages in sequence; reports batch completion upon return | `PERFORM ...`, `DISPLAY`, `STOP RUN` |
| `1000-INITIALIZE` | Clears closing balance field to zero | `MOVE ZERO TO ...` |
| `2000-PROCESS` | Computes closing balance and displays it | `COMPUTE ...`, `DISPLAY` |
| `9000-FINALIZE` | Displays final stage and final balance | `DISPLAY` |

Each name used by `PERFORM` corresponds to a paragraph definition. The main flow first initializes, then computes, and finally summarizes; therefore `9000-FINALIZE` can read the value written into the shared balance field by `2000-PROCESS`.

## Step-by-Step Execution Walkthrough

1. The program arrives at the first paragraph `0000-MAIN`.
2. `PERFORM 1000-INITIALIZE` outputs `段階=INITIALIZE` and sets closing balance to zero; control returns to the main flow upon paragraph completion.
3. `PERFORM 2000-PROCESS` outputs `段階=PROCESS`, computes `1000.00 + 125.50 - 40.10 = 1085.40`, outputs `0001085.40`, and returns to the main flow.
4. `PERFORM 9000-FINALIZE` outputs `段階=FINALIZE` and the read shared field `最終残高=0001085.40`, then returns to the main flow.
5. The main flow outputs `バッチ=COMPLETE` and executes `STOP RUN.`. No execution flow falls into the subsequent paragraph definitions.

A brief note on periods: a period terminates a COBOL sentence as well as any unclosed statement scopes. This example places a period on the last statement of each invoked paragraph, with the main paragraph's period placed after `STOP RUN`.

## Run and Observe

This lesson reads no terminal, file, or database inputs, producing identical results whether executed in this directory or any other. The following explains execution from this lesson directory.

**Input:** None. The three amounts are in-program fixed data, originating entirely from `VALUE` clauses in `WORKING-STORAGE`.

**Commands and roles:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                  # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_07 lesson.cob    # 编译并生成可执行文件
./build/lesson_07                              # 运行程序，输出写到标准输出
echo $?                                        # 查看退出码
rm -rf build                                   # 清理生成的可执行文件
```

**Expected results:**

| Observed Item | Expected Value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compilation diagnostics |
| Standard output | 6 lines, see code block below; stage sequence is INITIALIZE → PROCESS → FINALIZE |
| Process exit code | `0` |

```text
段階=INITIALIZE
段階=PROCESS
期末残高=0001085.40
段階=FINALIZE
最終残高=0001085.40
バッチ=COMPLETE
```

**Output field mappings (Japanese output → meaning):** `段階` = current stage; `期末残高` = closing balance computed by processing paragraph; `最終残高` = balance read during final stage; `バッチ=COMPLETE` = batch complete. The balance field is `PIC 9(7)V99`; `1085.40` is padded with zeros across 7 integer digits to display as `0001085.40`, with the assumed decimal point omitted in display.

**Observed environment details (unverified):** When running the executable in this workspace, standard error outputs `Warning: program compiled against libxml 212 using older 209`. This is a library version warning from the runtime environment, not business output of this program; the triggering component has not been identified, so this merely notes the phenomenon without deducing cause. Program output is on standard output, with an exit code of 0.

## Modification Exercise

Perform each of the two modifications starting from the original [`lesson.cob`](./lesson.cob) without combining them.

1. Modify amounts: change `WS-OPENING-BALANCE` to `2000.00` and `WS-DEPOSIT` to `250.00` (leaving `WS-WITHDRAWAL` at `40.10`), recompile and run. The new closing balance should be `0002209.90`.
2. Modify order: in `0000-MAIN`, move `PERFORM 2000-PROCESS` before `PERFORM 1000-INITIALIZE`, leaving remaining statements unchanged. Note stage markers and the final balance — it should be `0000000.00` — and explain why the value written by the processing paragraph is overwritten by initialization running afterwards.

This second problem is a live demonstration that "business misuse is more expensive than syntax errors": compilation reports no errors, runtime exit code is still 0, yet the money is gone. After each modification, run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_07 lesson.cob
./build/lesson_07
```

For full problem details, see [`exercise.md`](./exercise.md); for reference answers, see [`answer.md`](./answer.md).

## "Apply It Elsewhere" Exercise

Deconstruct the same small batch into four named paragraphs: read sample, validate transaction code, calculate balance, output summary. Arrange a reasonable invocation sequence for the main paragraph and print markers at each stage; then swap two paragraphs that have data dependencies and record the output difference. Still use only fixed values without introducing files, tables, or `CALL`. See [`exercise.md`](./exercise.md) for problem details; no reference answer is provided for this exercise.

## Walking Through a Real Workflow

Placing this small batch back into the overnight processing chain:

1. **12:40 a.m.**: Upstream exports the day's transactions into a file placed in a shared directory (reading files yourself starts in Lesson 15).
2. **1:00 a.m.**: The scheduler pulls up your job. It starts by zeroing accumulators and preparing outputs — this is where `1000-INITIALIZE` sits.
3. In between, it processes transaction by transaction, computing one line at a time — paragraphs like `2000-PROCESS`.
4. **Wrap-up**: `9000-FINALIZE` prints total transaction count and total amount into logs (Lesson 27 covers in detail what logs should record). These figures are reconciled against upstream the next day.
5. **Handover**: Computed results are handed downstream: writing result files starts in Lesson 16, writing databases starts in Lesson 29.

Therefore, those `PERFORM` lines in the main paragraph are not decoration; they form the table of contents for the entire chain. Whenever you read a batch program hundreds of lines long in the future, look for the main paragraph first, and see who it calls in what order.

## What Happens if This Code Goes to Production

- **Who schedules it**: The overnight batch scheduler, typically sequenced after "file readiness checks". It looks only at exit codes, not your screen.
- **Who reads its output**: The on-duty operator checks stage markers in the logs first, then inspects amounts. If balances are wrong, investigation must start that night.
- **Who gets called when something breaks**: Whoever runs this job. Whether you can pinpoint which section broke in ten seconds depends on whether paragraph names were chosen well.
- **How the next system connects**: Results are written to files for downstream consumption (Lesson 16), or written to a database (Lesson 29 onward).
- **Most common first-month incidents**: Adding initialization after processing — or temporarily inserting a zeroing statement to "fix" an issue. The program reports no errors, exit code is `0`, the scheduler shows success, and the error stays hidden until next-day reconciliation. Exercise 2 lets you experience this collision in a safe environment first.
- **What it hasn't done yet**: This lesson divides work only within a single program. Cross-program interfaces belong to `CALL`; do not mistake internal paragraphs for independent subprograms. When you truly need parameter contracts and independent calls, see Lessons 24 and 25.

To be explicit: this lesson demonstrates that "giving procedures names" makes the main flow readable and makes the consequences of invocation order observable. It does not implement production-grade logging, error classification, or resource cleanup — what codes to exit with or what files to leave behind after batch failure are covered in Lesson 26.

## References

- [GnuCOBOL Programmer’s Guide: PROCEDURE DIVISION Sections and Paragraphs](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-Sections-and-Paragraphs)
- [GnuCOBOL Programmer’s Guide: Procedural PERFORM](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Procedural-PERFORM)
- Repository Course Home: [README.md](../../README.md)
