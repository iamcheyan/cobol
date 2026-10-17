---
_translated_from: lessons/05_evaluate/README.md
_translated_by: site-src/translation agent
---

# Lesson 05 — EVALUATE: Classifying Transaction Codes into Explicit Processing Branches

When a transaction arrives, you must first know "what it is" before you can decide what to do with it. This lesson teaches that step: using `EVALUATE` to dispatch multiple values of the same field into their respective processing branches, while ensuring "unrecognized values" have an explicit way out. This classification approach is reused by subscript in the loops of [Lesson 06](../06_perform-loops/README.md) and aggregated into multi-transaction counts in Lesson 08.

## The Business Setting

First, consider a concrete scene (institutions, times, and scale are educational demonstrations, not data from any real institution).

In a bank's overnight batch run, processing starts at 2:00 a.m. for transactions generated across teller windows and apps throughout the day. In the transaction file provided by upstream core systems, each transaction contains only a single character explaining what it is: `D` for deposit, `W` for withdrawal, `T` for transfer. How you interpret the values of this field is not up to you — it is determined by upstream business units; whether new values are added and when, on the batch processing side you can only follow along.

Originally, this logic was strung together with `IF` statements: an `IF` checking `D`, an `ELSE IF` checking `W`, and a final `ELSE` catching everything else. It worked fine the day it was written, but modifying it later was a nightmare. First the business department added `F` (fee), and someone found a spot to wedge in a block; the next year brought `R` (reversal), and someone else tucked another layer into the nest. When auditors or troubleshooting engineers asked "which transaction codes are currently unhandled?" — nobody dared point to that code and answer. What that `ELSE` actually caught after three stacked layers was something even the original author had to re-read from top to bottom.

And in financial systems, one bottom line is non-negotiable: **unrecognized input must never be quietly processed as a normal transaction.** If an unknown transaction type is casually booked into an account as a deposit, it is far more dangerous than the program throwing an error immediately — nobody notices the mistake right away, and by the time reconciliation catches it, it is already too late.

What you need, therefore, is not "a few more `IF` statements", but a dispatching structure that can be inspected completely at a glance and explicitly answers "where did the rest go?"

## Why Learn This Now

In [Lesson 04](../04_if-conditions/README.md), you already learned how to use `IF` / `ELSE` / `END-IF` for two tasks: accepting or rejecting a transaction by amount range, and deciding whether to proceed based on account status. But the targets of those evaluations — one numeric range, one single status — had only two possible outcomes.

You might think: with more values, isn't it just writing a few more `ELSE IF` clauses?

Look at what that looks like first. Expressing `D`/`W`/`T` plus a fallback using chained `IF` statements looks roughly like this:

```cobol
IF WS-TRANSACTION-CODE = "D"
    ...
ELSE IF WS-TRANSACTION-CODE = "W"
    ...
ELSE IF WS-TRANSACTION-CODE = "T"
    ...
ELSE
    ...   *> 到这一步，兜的是"其他所有码"还是"我漏写的那个"，说不清
END-IF
```

It runs, but it introduces three distinct awkward problems:

1. **The subject must be rewritten every time.** The same `WS-TRANSACTION-CODE` is compared three times in this block; if the field is renamed in the future, you have to change it everywhere.
2. **Adding a new code requires deciding where to wedge it in.** Placing it in an outer versus an inner layer directly impacts which `IF` the subsequent `ELSE` associates with. As covered in Lesson 04, `ELSE` binds only to the nearest unclosed `IF` — as nesting deepens, this rule starts to bite.
3. **Most critically, the fallback is ambiguous.** The final `ELSE` ostensibly catches "everything other than the three known codes", but you cannot answer "which codes remain unhandled" by looking at this place alone. Someone adding a branch might insert it in the wrong place, requiring the reader to trace from top to bottom. Auditors do not want "I think everything is covered"; they want a checklist they can count at a glance.

`EVALUATE` is designed to solve point 3: the subject is written once, known values are laid out side by side, and the fallback clause is stated explicitly in the open. **"Which codes are explicitly acknowledged, and which path the rest take" is visible at a glance.**

## What This Knowledge Point Is, and What Problem It Solves

**What it is.** In plain terms: `EVALUATE` is a selection construct for "one field, multiple values, with each value taking its own section." After writing the subject once, each subsequent `WHEN` lists a candidate value, concluding with `WHEN OTHER`.

**What business problem it solves.** The code space provided by upstream will never give you a closed, permanent list. Today it is `D`/`W`/`T`, next month the business team adds `F`, and six months later a code you have never seen before suddenly shows up — perhaps upstream launched a new business line and forgot to notify you, or the file was corrupted and dirty characters slipped in. You cannot enumerate "all possible values" in advance, so what is needed is not "memorizing today's codes", but a structure that explicitly declares "where the rest go." This is what this lesson teaches: known codes each have an explicit processing category, while unknown codes uniformly route to pending manual review rather than marching down the normal processing path.

**When not to use it, and what happens when misused.** Two common misuses carry business costs far higher than syntax errors.

First is treating it as an all-purpose condition evaluator. The strength of `EVALUATE` is "one field matched against a list of exact values." If you need to evaluate amount ranges or combinatorial conditions across multiple fields, forcing them into this construct makes code convoluted. GnuCOBOL supports `EVALUATE TRUE` with conditional expressions, but that is an advanced pattern; this lesson first covers the simple form of subject against exact constants.

Second is treating `WHEN OTHER` as a trash bin. Its responsibility in this lesson is singular: catch values outside the contract and label them unknown. Do not casually shove "null checks", "format checks", or "case normalization" into it — doing so makes it impossible to distinguish "valid but unknown codes" from "outright corrupted data", throwing away the exact clue most needed during troubleshooting.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you will be able to:

- Use `EVALUATE <field>` with multiple `WHEN "<value>"` clauses to branch multiple exact values of the same character field.
- Use `WHEN OTHER` to catch values unlisted in the contract, preventing them from passing silently.
- Run the program and inspect the classification and action labels produced for `D`, `W`, and `T` respectively.
- Explain why lowercase `d`, spaces, and other characters all enter `WHEN OTHER` (character comparisons are exact matches).
- Explain why this lesson outputs only classification and action labels without executing any account posting.

Limits: This lesson does not read files, perform arithmetic, update balances, or write log or rejection files; no case normalization is performed, nor are there specialized validation branches for null or format errors — they simply fall into `WHEN OTHER`. File reading begins in [Lesson 15](../15_sequential-file-read/README.md), writing rejection outputs begins in Lesson 16, and separating business rejections from system failures begins in Lesson 26.

## Runtime Environment

- GnuCOBOL 3.2.0, using the default dialect (without `-std=cobol85`), source file in fixed format; compiler and target platform behavior based on actual verification.
- Linux terminal; this lesson does not depend on databases, extra tools, or third-party libraries.
- Inputs are entirely in-program constants in `WORKING-STORAGE`, with no input fixtures; running produces an executable only under `build/`.

## Knowledge Explanation

### How EVALUATE Is Written

Upstream batch systems provide single-character transaction codes per interface contracts; the program must map each known code to its corresponding processing category in a single place, while giving unhandled codes an explicit destination. The syntax is "one subject against multiple constants":

```cobol
EVALUATE WS-TRANSACTION-CODE
    WHEN "D"
        DISPLAY "分類=DEPOSIT"
    WHEN "W"
        DISPLAY "分類=WITHDRAWAL"
    WHEN OTHER
        DISPLAY "分類=UNKNOWN"
END-EVALUATE
```

- The subject is `WS-TRANSACTION-CODE`, evaluating only one field at a time — this is where it saves effort over chained `IF`s.
- Each `WHEN` supplies a candidate value for the field; the program executes the first matching branch, and reaching `END-EVALUATE` terminates this selection block.
- `WHEN OTHER` executes when no explicit `WHEN` matches, serving as the fallback path in this lesson.

### Non-Example → Good Example

The earlier `IF / ELSE IF / ELSE` block is the non-example: it runs, but cannot answer "which codes remain unhandled", and adding a code forces you to worry about where to insert it.

Rewriting with `EVALUATE` (good example):

```cobol
EVALUATE WS-TRANSACTION-CODE
    WHEN "D"   ...
    WHEN "W"   ...
    WHEN "T"   ...
    WHEN OTHER ...   *> 契约之外的码，全在这
END-EVALUATE
```

Two benefits are immediately obvious: the subject is written once, eliminating repetitive comparisons of the same field across every condition; known values and fallback values are laid out side by side, making "which codes are explicitly acknowledged, and which path the rest take" plain to see. Adding a new transaction code requires only inserting a `WHEN` between `WHEN "T"` and `WHEN OTHER`, without touching the scope of any `ELSE`. Lesson 04 emphasized that `ELSE` binds to the nearest unclosed `IF`; `EVALUATE` bounds scope explicitly with `END-EVALUATE`, avoiding such nesting pitfalls altogether.

### Character Comparison Is Exact and Does Not Accept "Close Enough"

`WS-TRANSACTION-CODE` is a `PIC X` text field, and `WHEN "D"` compares characters directly: lowercase `d` does not equal uppercase `D`, and spaces, numbers, and other characters do not equal `D`/`W`/`T`. All such values enter `WHEN OTHER` and are labeled `UNKNOWN`. The interface convention in this example specifies uppercase `D`, `W`, and `T`.

In a real batch, this can trigger actual incidents: if upstream switches to lowercase codes one day, entire batches of valid transactions will be labeled unknown. To accept case variants or aliases, the contract must define them explicitly and the program must normalize them; you cannot quietly expand the meaning of a character. This lesson does not perform that normalization layer — an intentionally preserved boundary.

### Language of the Output Text

Repository convention: source comments and README explanations use Chinese, while business text printed by running programs follows Japanese conventions. In this lesson, `取引参照番号` means "transaction reference number", `取引コード` means "transaction code", `分類` means "classification", and `処理` means "action label" (e.g., `処理=ADD_TO_ACCOUNT` means "action suggestion=credit account"). When assessing program behavior, rely on actual output and the explanations in this section.

## Complete Example Source

[`lesson.cob`](./lesson.cob) uses the fixed constant `D` to demonstrate the deposit branch: it first displays the transaction reference number and code, then outputs a classification label and an action label.

```cobol
      * 合法取引コード D/W/T 由接口契约定义；本课把它当作输入前提，不在程序内校验取值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
       PROCEDURE DIVISION.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE.
           DISPLAY "取引コード=" WS-TRANSACTION-CODE.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
      * 契约外取值统一归入待人工核对；本课只输出分类标签，不做任何过账。
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
           STOP RUN.
```

### Data Fields

| Field | PIC / Initial Value | Meaning |
|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / `TXN-00000001` | Transaction reference text, does not participate in arithmetic |
| `WS-TRANSACTION-CODE` | `X(1)` / `D` | Single-character transaction code, taking contract-permitted `D`/`W`/`T` |

### Step-by-Step Procedure Walkthrough

1. `IDENTIFICATION DIVISION` and `PROGRAM-ID` name the program; `WORKING-STORAGE SECTION` uses `VALUE` to assign fixed reference and transaction codes; the program has no other inputs.
2. The first `DISPLAY` outputs the transaction reference (`X(12)` text, not participating in arithmetic), and the second outputs the transaction code, facilitating verification of the current fixed sample.
3. `EVALUATE WS-TRANSACTION-CODE` opens multi-way selection, with that single-character code as the subject.
4. `WHEN "D"` outputs `分類=DEPOSIT` and `処理=ADD_TO_ACCOUNT`; `WHEN "W"` outputs withdrawal labels, and `WHEN "T"` outputs transfer labels. Each branch outputs only two static labels.
5. `WHEN OTHER` outputs `分類=UNKNOWN` and `処理=REJECT_FOR_REVIEW`, covering all values outside `D`/`W`/`T`.
6. `END-EVALUATE` explicitly closes the selection scope, and `STOP RUN.` ends the program.

Classification and action labels are static text printed via `DISPLAY`; the program performs no deposits, withdrawals, or transfers, and modifies no balances.

## Run and Observe

This lesson reads no keyboard, file, command line argument, or database input, and generates no data files, producing identical results whether executed in this directory or any other. The following explains execution from this lesson directory.

**Input:** No external input. Every line observed comes from in-program constants and `DISPLAY` literals in `lesson.cob`, not file or database data.

**Commands and roles:**

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # 只做语法检查，不生成可执行文件
cobc -x -Wall -o build/lesson_05 lesson.cob      # 编译并生成可执行文件
./build/lesson_05                                # 运行程序，业务输出写到标准输出
echo $?                                          # 查看上一条命令的退出码
rm -rf build                                     # 清理生成的可执行文件
```

`-fsyntax-only` verifies only the syntax path without generating or running a program, and cannot substitute for compilation and runtime observation; `-x` instructs GnuCOBOL to generate an executable program, with `-o` specifying the output path; `rm -rf build` deletes only the executable generated by this lesson without touching source code.

**Expected results:**

| Observed Item | Expected Value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x` exit code | `0`, no compilation diagnostics |
| Standard output (stdout) | See four lines below |
| Process exit code (`echo $?`) | `0` |
| Generated files | `build/lesson_05` only |

Standard output:

```text
取引参照番号=TXN-00000001
取引コード=D
分類=DEPOSIT
処理=ADD_TO_ACCOUNT
```

**To see branching with your own eyes:** Change the initial value in `01 WS-TRANSACTION-CODE PIC X VALUE "D".` in `lesson.cob` to `W`, `T`, `X`, and `d` respectively and run each once. You will observe: `W` → `分類=WITHDRAWAL` / `処理=SUBTRACT_FROM_ACCOUNT`, `T` → `分類=TRANSFER` / `処理=PROCESS_BOTH_ACCOUNTS`, while both `X` and `d` fall into `WHEN OTHER` → `分類=UNKNOWN` / `処理=REJECT_FOR_REVIEW`. In all four cases the exit code is `0`. **The fact that `d` takes the unknown path is the most direct evidence of "exact comparison."** Be sure to restore the initial value back to `D` afterwards, avoiding leaving uncommitted changes quietly in the file.

**Observed environment details:** When executing `./build/lesson_05` in this workspace, standard error outputs `Warning: program compiled against libxml 212 using older 209`. This is a library version mismatch warning from the runtime environment, not business output of this program, and the triggering component has not been identified. Normal output is written to standard output, with an exit code of 0.

## Modification Exercise

Starting from the original [`lesson.cob`](./lesson.cob), add a `WHEN "F"` branch for a new transaction code `F` (fee) added to the interface, and change the sample code to `F` for observation: insert a branch outputting `分類=FEE` / `処理=CHARGE_FEE` inside `EVALUATE` after the `WHEN "T"` branch and before `WHEN OTHER`, while changing the initial value of `WS-TRANSACTION-CODE` from `VALUE "D"` to `VALUE "F"`. Constraints are: do not alter outputs of `D`/`W`/`T` branches, do not alter the semantics or output of `WHEN OTHER`, and maintain fixed format. For complete requirements, expected diffs, and rationale, see [`exercise.md`](./exercise.md); for reference answers, see [`answer.md`](./answer.md).

This problem is a miniature exercise in "upstream adding an `F`": you will experience firsthand that "adding a new code = inserting just one `WHEN`", and then verify that the fallback path remains undamaged.

## "Apply It Elsewhere" Exercise

Classify payment methods for a batch record: `C` cash, `B` bank transfer, `K` check; codes outside the contract uniformly route to pending manual review. Using only fields, `EVALUATE`, `WHEN`, `WHEN OTHER`, `DISPLAY`, and `STOP RUN` covered in this lesson, map codes with `EVALUATE` and output categories and recommended actions. See [`exercise.md`](./exercise.md) for the problem statement; no reference answer is provided for this exercise.

## Walking Through a Real Workflow

Suppose upstream indeed sends a notification: starting next month, an additional transaction code `F` (fee) will be introduced. From receiving the notification to going live, your steps look roughly like this:

1. **Update the contract first, not the code.** Have business and upstream document the value and meaning of `F` clearly: does it post to accounts, does it apply fee schedules, and is it mutually exclusive with `D`/`W`/`T`? Without a settled contract, writing code is just guessing.
2. **Insert a branch.** In `EVALUATE`, add `WHEN "F"` after `WHEN "T"` and before `WHEN OTHER`, outputting the new classification and action labels. This is what the modification exercise does.
3. **Switch sample to the new code and run.** Change the initial value to `F`, recompile and run, verifying `取引コード=F`, `分類=FEE`, `処理=CHARGE_FEE`, with an exit code of `0`.
4. **Verify the fallback.** Change initial values to `X` and `d` and run each once, confirming they still land in `UNKNOWN` / `REJECT_FOR_REVIEW`. **Only when the added branch does not disturb the fallback has this step truly been verified.** Finally, revert initial value back to `D`.
5. **Synchronize lesson companion materials.** Fixtures (here in-program constants), `exercise.md`, `answer.md`, and expected outputs in README must be updated together, not just the program — discrepancies between problem statements and expected answers will trap whoever maintains it next.
6. **Hand over downstream.** Turning action labels into real actions takes several more lessons: looping over multiple transactions by index is [Lesson 06](../06_perform-loops/README.md), aggregating acceptance/rejection counts is [Lesson 08](../08_control-flow-practice/README.md), writing rejection details to file is [Lesson 16](../16_file-writing/README.md), separating business rejections from system failures is [Lesson 26](../26_error-handling/README.md), and logging with batch IDs and original codes is [Lesson 27](../27_logging/README.md).

## What Happens if This Code Goes to Production

- **Who schedules it:** The overnight batch scheduler triggers it according to plan, recognizing only executable paths and exit codes — in this lesson all branches exit with `0`, so the scheduler cannot tell whether a transaction was labeled unknown.
- **Who reads its output:** Troubleshooting and operations teams read standard output. The lines `分類=UNKNOWN` / `処理=REJECT_FOR_REVIEW` are where they start tracing "why this transaction wasn't posted."
- **Where unknown codes ultimately go:** In this lesson, they are merely two `DISPLAY`ed labels, **not** actually queued for manual review or written to a rejection file. Turning them into real actions requires waiting for Lesson 16 (writing rejection details) and Lesson 26 (separating business rejections from system failures).
- **Who gets called when something breaks:** The most dangerous outcome is not an error, but **the absence of an error**. If unknown codes are silently processed down the normal path, nobody may be alerted until reconciliation finds balances out of sync. Thus the rule "unknown codes must take a visible fallback path" is far more critical than it looks.
- **How the next system connects:** Downstream logic (loops and tallies in Lessons 06 and 08) relies on classification labels produced here for dispatching; if labels change, downstream accounting criteria change with them.
- **Most common first-month incidents:** First, upstream adds a code without notification, causing entire batches to land in `UNKNOWN`; second, upstream switches to lowercase one day, causing valid transactions to be uniformly flagged unknown — neither can be prevented by this lesson alone, requiring contracts and logging.

To be explicit: this lesson does not read files, perform arithmetic, update balances, or write logs or rejection files; action labels are purely `DISPLAY`ed text. It does not implement real posting, rejection, or audit workflows, and claims no production, audit, or regulatory guarantees. Fully assembling that processing chain requires progressing through several subsequent lessons (see the previous section).

## References

- [GnuCOBOL Programmer’s Guide: EVALUATE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#EVALUATE)
- [GnuCOBOL Manual: EVALUATE TRUE and WHEN OTHER Examples](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- Repository Course Directory: [DIRECTORY.md](../DIRECTORY.md)
