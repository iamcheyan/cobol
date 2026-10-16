---
_translated_from: lessons/03_move-compute/README.md
_translated_by: site-src/translation agent
---

# Lesson 03 — MOVE and COMPUTE: Truncation and Rounding in Monetary Arithmetic

## The Business Setting

On interest-posting night, the interest batch has to finish computing and writing the period interest for 120,000 deposit accounts before 8 a.m.; the teller counters open at 9, and customers tap their balances on the App — those numbers must be right.

Every line of interest in this batch is computed as "balance × rate", and the result almost always drags along a long tail of decimals, while balances are only kept to cents. So each line needs an on-the-spot decision: do we lop off the extra decimal places outright, or carry them up according to a rule? Lop-off is called truncation; carry-up is called rounding.

In the demonstration sample the exact interest is `15.0650`; truncate to get `15.06`, round to get `15.07`. You may think: one cent. But with 120,000 lines, if every line tilts the same way, they add up to anything but small change; and worse, the closing balance is built by adding this interest — that one-cent gap carries straight into the balance.

What actually calls people out of bed at night is the next morning's reconciliation. The core system recomputes under its own conventions, and the two balances do not match — even by a single cent, the reconciliation team cannot shrug it off as "close enough"; the whole batch is held, and someone has to track down which line that one cent landed on. So "which field holds the result, how many decimals it keeps" is not a math exercise; it is the deciding factor in whether this batch leaves on time. (The scenario is pedagogical; the amounts and batch day were chosen to clarify the problem, not real data from any institution.)

## Why Learn This Now

In lesson 02 you already wrote `PIC` for balances and interest rates; field widths and precisions are right there in the source. But those fields only got their initial value printed once by `DISPLAY`, and nobody touched them from start to finish — real accounts are not printed, they are computed.

Three small things block you now: how to move a value into another field; how to write an amount expression with add, subtract, and multiply; and what to do with the extra decimal places when the result has more decimals than the receiving field. The last one directly decides how the closing balance is written, and it is the easiest place to crash in a bank's reconciliation.

You might think: a value move, a multiplication — in another language those are just `a = b` and `a = b * c`, no? The trap is here. In Java or Python, assigning a `BigDecimal` to another variable doesn't change the value; in COBOL, the receiving field carries an explicit decimal scale, and the moment you move into it, the value is reshaped to that scale. So **the act of "moving a value" can change an amount, with no warning from the program.** If you don't write the rule explicitly, no one will ask "this business, truncate or round?"

This lesson stops here: only sequential assignment and arithmetic statements — no conditions (lesson 04), no loops (lesson 06) — so we first pin down the "receiving-field scale decides the result" rule, and only later add conditions and loops to the money chain on a solid base.

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** You have two new abilities. `MOVE` copies a value into another field, and the destination's `PIC` decides what shape it becomes there; `COMPUTE` evaluates the right-hand add/subtract/multiply expression and then puts the result into the left-hand receiving field, with its scale again decided by the receiving field. Two new terms only: the receiving field's scale decides decimal places; `ROUNDED` decides what to do with the surplus decimal places.

**What business problem it solves.** It lets the chain of balances, interest, and fees be written as a program instead of someone with a calculator tapping each line; more critically, it leaves the "how many decimals to keep, which way to round" business rule in the code, reviewable and editable. Change one initial value and the result recalculates automatically; the rule does not vanish from the code.

**When you shouldn't use it, or what a misuse looks like.** The picking rule for amounts cannot be left to "default behavior." Not writing `ROUNDED` means truncation, which is this toolchain's default — that is not the same as every business's convention; pick the wrong day and the batch will be off by one cent from the accounting rule. Also, when the receiving field's integer positions can't hold the result, the program does not warn (there is an actual test below) — so the capacity of the amount field must be sized to the business upper bound, not to the order of magnitude of the line in front of you.

## Capabilities and Limits After Completing This Lesson

After finishing this lesson you will be able to:

- Use `MOVE` to move a value into another numeric field, and explain how the receiving field's decimal places decide what is kept (here `15.0650` → `15.06`).
- Use `COMPUTE` to write an amount expression involving add, subtract, and multiply, and verify every intermediate value against standard output.
- Distinguish "truncation" (no `ROUNDED`) from "round according to the receiving field" (`ROUNDED`), and explain why the same interest yields `15.06` and `15.07`.
- Explain how the two rules let the closing balances differ by `0.01`, and point out that one of these rules must be chosen by the business / accounting convention.
- State what happens when an amount field does not have enough digits, and explain why the samples in this lesson do not trigger that boundary.

Limits: this lesson does not introduce `IF` / `EVALUATE` (lessons 04, 05), loops (lesson 06), paragraphs (lesson 07), file input (lesson 15), or error handling statements (lesson 26). All balances and rates are program-internal demonstration constants, not real account data, and they do not represent any bank's interest scheme; the program has no overflow check implemented.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not pass `-std=cobol85`), source files in fixed format.
- Linux terminal; this lesson does not depend on a database, additional tools, or third-party libraries.
- The program does not read or write data files; it only produces an executable in `build/`.
- Public conventions are in [Course Navigation](../README.md); this lesson's place in the dependency chain is in [the 32-lesson directory](../DIRECTORY.md).

## Breaking Open the Knowledge Points

### MOVE: What gets carried over is not "the same number" but a value reshaped to the destination field's PIC

`MOVE source TO target` copies `source`'s value into `target`, without changing `source` and without doing any computation. But the destination field carries its own `PIC` scale: `WS-INTEREST-RAW` is `9(5)V9999` (four decimals), `WS-INTEREST-MOVE` is `9(5)V99` (two decimals); when you `MOVE` between them, the extra two decimals are discarded — yielding `15.06` — and the source field is still `15.0650`.

People coming from Java or Python are most likely to assume here: assigning a `BigDecimal` to another variable usually doesn't change the value; COBOL's receiving field has an explicit decimal scale, and the conversion happens during the move, so "moving a value" alone can change the amount. Production code therefore has to write the field scales and business units clearly before and after the move; the reader cannot guess them from code alone.

### COMPUTE: Evaluate the right side first, then store into the receiving field's scale

`COMPUTE target = expression` evaluates the right-hand expression first and then stores the result into the left-hand data item; the receiving field's `PIC` again decides how many decimals are kept. This example first computes the post-transaction balance:

```cobol
COMPUTE WS-PRE-INTEREST-BALANCE =
    WS-OPENING-BALANCE + WS-DEPOSIT
        - WS-WITHDRAWAL - WS-SERVICE-FEE
```

Then it computes the interest `WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE`, writing the intermediate value into the four-decimal `WS-INTEREST-RAW`. All inputs, intermediate values, and receiving fields are declared with explicit decimal `PIC`s, so each step is verifiable in the source — no floating-point approximation.

One more thing — don't cut corners: these values must come from fields, not be hard-coded as `DISPLAY` literals. Hard-coding can only repeat the result once; change the initial value and you have to recompute by hand, and the business rule disappears from the source. With `COMPUTE` the rule stays in code, and changing the initial automatically yields the new result (this lesson's exercise is built exactly this way).

### Truncate or round: same interest, two business rules

In GnuCOBOL, when the receiving field lacks decimal places, **not** writing `ROUNDED` is equivalent to `ROUNDED MODE IS TRUNCATION` (truncate; for non-negative amounts in this lesson, that means dropping surplus decimal places); **writing** `ROUNDED` without a mode is equivalent to `NEAREST-AWAY-FROM-ZERO` (round to nearest, halves away from zero). The exact interest in this example is `15.0650`:

| Form | Result | Notes |
|---|---|---|
| `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE` | `15.06` | receiving field is two-decimal; drops the 3rd and 4th digit |
| `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW` | `15.06` | no `ROUNDED`, same truncation rule |
| `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW` | `15.07` | 3rd digit is `5`, round up to nearest |

`ROUNDED` sits after the receiving field and before the `=`:

```cobol
COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW
```

Which one to pick is not a programming preference; it is the business and accounting rule: the truncated and rounded values make the closing balance differ by `0.01`, and currency, product, and interest-accrual policies can each pick differently. Don't treat GnuCOBOL's default mode as the universal rule — that's something to align with the accounting and product people.

### When the field can't hold it, the program doesn't say a word

Decimal digits get dropped — integer digits get dropped too. A standalone probe on this machine observed (the probe is not part of [`lesson.cob`](./lesson.cob); it only uses this lesson's `PIC`, `COMPUTE`, `DISPLAY`):

```sh
mkdir -p /tmp/l03probe && cd /tmp/l03probe
cat > probe.cob <<'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROBE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BAL PIC 9(7)V99 VALUE 1234567.89.
       01 WS-RATE PIC 9(1)V9(4) VALUE 0.9000.
       01 WS-INT PIC 9(5)V99 VALUE 55.55.
       PROCEDURE DIVISION.
           COMPUTE WS-INT = WS-BAL * WS-RATE.
           DISPLAY "利息=" WS-INT.
           STOP RUN.
EOF
cobc -x -o probe probe.cob && ./probe
```

`1234567.89 × 0.9000 = 1111111.101`, stored into `PIC 9(5)V99` actually prints `利息=11111.10`, and the exit code is `0`: the high-order digits are silently dropped; the program neither aborts nor reports an error. A "compute error" itself never becomes an error signal, so the capacity of amount fields, overflow checks, and reporting methods have to be made explicit by the program. `ON SIZE ERROR` can catch this kind of condition, but it is error handling and is left for lesson 26.

## Complete Example Source

The full source is [`lesson.cob`](./lesson.cob), written in fixed format. It only uses `MOVE`, `COMPUTE`, `DISPLAY`, and `STOP RUN`. The key balance and interest statements were excerpted above; the remaining statements are explained in the source reading path below.

## Source Reading Path

### Data declarations

| Field | PIC / initial value | Use and scale |
|---|---|---|
| `WS-OPENING-BALANCE` | `9(7)V99` / `1000.00` | opening balance, in yuan, two decimals |
| `WS-DEPOSIT` | `9(7)V99` / `250.55` | deposit this period |
| `WS-WITHDRAWAL` | `9(7)V99` / `40.10` | withdrawal this period |
| `WS-SERVICE-FEE` | `9(5)V99` / `5.25` | service fee; 5 integer digits, smaller capacity than the balance field |
| `WS-PERIOD-RATE` | `9(1)V9(4)` / `0.0125` | demonstration rate 1.25%, four decimals; no day-count rule |
| `WS-PRE-INTEREST-BALANCE` | `9(7)V99` / `ZERO` | balance after transactions, before interest |
| `WS-INTEREST-RAW` | `9(5)V9999` / `ZERO` | intermediate interest value; deliberately keeps four decimals |
| `WS-INTEREST-MOVE` | `9(5)V99` / `ZERO` | two-decimal result after `MOVE` |
| `WS-INTEREST-TRUNC` | `9(5)V99` / `ZERO` | result without `ROUNDED` |
| `WS-INTEREST-ROUNDED` | `9(5)V99` / `ZERO` | result with `ROUNDED` |
| `WS-CLOSING-BALANCE` | `9(7)V99` / `ZERO` | closing balance under this lesson's posting rule (with rounded interest) |

### Execution order and state changes

1. The first `COMPUTE`: `1000.00 + 250.55 − 40.10 − 5.25`, writes `1205.20` into `WS-PRE-INTEREST-BALANCE`.
2. The second `COMPUTE`: `1205.20 × 0.0125 = 15.065`, receiving field is `9(5)V9999`, output is `15.0650`.
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`: receiving field has only two decimals, no rounding, yields `15.06`; `WS-INTEREST-RAW` is still `15.0650`.
4. `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW`: no `ROUNDED`, also yields `15.06`.
5. `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW`: default `NEAREST-AWAY-FROM-ZERO`, yields `15.07`.
6. `COMPUTE WS-CLOSING-BALANCE = WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED`: under this lesson's rule, `1205.20 + 15.07 = 1220.27`.
7. Eleven `DISPLAY` statements output label and value in source order; `STOP RUN` ends normally.

Steps 2–5 all stem from the same `WS-INTEREST-RAW`, so the differences among the three two-decimal results come only from the receiving field, not from repeated computation. `DISPLAY` itself does not change any field.

## Run and Observe

### Where to execute

The program does not read files, command line arguments, or a database, and running it inside this lesson's directory or from any directory produces the same result. The commands below assume this lesson's directory; `lesson.cob` and `build/lesson_03` are relative to the current directory, so first `cd lessons/03_move-compute` and then execute.

### Input

No standard input, no file, no database input. All data comes from the `VALUE`s of `01`-level fields in `lesson.cob`:

- Amount fields are `PIC 9(7)V99` or `9(5)V99`, unit is yuan, implied two decimals, smallest posting unit 0.01.
- The rate field is `PIC 9(1)V9(4)`; `0.0125` means 1.25%, with no day-count rule, multiplied once on the pre-interest balance.
- There is no validation for negative values, blanks, or insufficient digits — those boundaries are owned by `IF` (lesson 04), file and validation (lesson 15 onward), and error handling (lesson 26).

### What each of the four commands proves

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob                    # check: parse syntax only, no executable
cobc -x -Wall -o build/lesson_03 lesson.cob      # build: produce executable, -Wall turns on compile warnings
./build/lesson_03                                # run: run the program, stdout is the business result
echo $?                                          # check the previous run command's exit code
rm -rf build                                     # clean: delete this lesson's build artifacts
```

`-fsyntax-only` passing only proves the syntactic path is fine; behavior must be confirmed by compiling and running. `-Wall` lets the compiler report issues such as literal widths exceeding receiving fields early; this lesson's source has no such warning.

### Expected stdout, stderr, and exit code

| Output line | Value | Where it comes from |
|---|---|---|
| `期首残高=0001000.00` | 1000.00 | initial value, padded to `9(7)V99` |
| `預入額=0000250.55` | 250.55 | initial value |
| `払戻額=0000040.10` | 40.10 | initial value |
| `手数料=00005.25` | 5.25 | initial value, padded to `9(5)V99` |
| `期間利率=0.0125` | 0.0125 | initial value, formatted as `9(1)V9(4)` |
| `利息加算前残高=0001205.20` | 1205.20 | 1000.00 + 250.55 − 40.10 − 5.25 |
| `利息（4桁）=00015.0650` | 15.0650 | 1205.20 × 0.0125, receiving `9(5)V9999` |
| `MOVE後利息（2桁）=00015.06` | 15.06 | 15.0650 truncated to two decimals |
| `COMPUTE切捨て利息=00015.06` | 15.06 | no `ROUNDED`, same truncation rule |
| `COMPUTE四捨五入利息=00015.07` | 15.07 | `ROUNDED`, the 3rd digit is `5`, round up |
| `期末残高=0001220.27` | 1220.27 | 1205.20 + 15.07 |

- `cobc -fsyntax-only` exit code `0`, no diagnostics; `cobc -x` exit code `0`, no compile diagnostics; program exit code `0`.
- Standard output is 11 lines, matching the table above, with no extra blank lines.
- Output text follows the repository's Japanese convention: `期首残高` = opening balance, `預入額` = deposit, `払戻額` = withdrawal, `手数料` = service fee, `期間利率` = period rate, `利息加算前残高` = balance before interest, `利息（4桁）` = four-decimal interest, `MOVE後利息（2桁）` = interest after MOVE (two decimals), `COMPUTE切捨て利息` = truncated interest via COMPUTE, `COMPUTE四捨五入利息` = rounded interest via COMPUTE, `期末残高` = closing balance.
- Standard error (stderr) shows a separate system warning `Warning: program compiled against libxml 212 using older 209`, caused by a libxml version mismatch in this machine's runtime environment; it is not the program's business output. To judge whether this run is correct, look at standard output and the exit code — don't count an environmental warning on stderr as a program error.

### Evidence Sources

The table above was observed on 2026-10-16 in this workspace by actually executing `cobc -fsyntax-only lesson.cob`, `cobc -x -Wall -o build/lesson_03 lesson.cob`, and `./build/lesson_03` with GnuCOBOL 3.2.0; the three commands' exit codes were `0`, `0`, `0` in order; each amount can be hand-verified by the formula in the "how" column. All this lesson's data are program-internal constants; this one run is the program's full behavior. The output's `15.0650` and `1220.27` both fit comfortably within their receiving fields, so this output contains no digit-loss of the kind described in the previous section.

### Fixed-Format Reminder

The source is fixed format: column 7 is the indicator (with `*` for comments), Area A starts at column 8 (for `01`-level declarations and division names), Area B starts at column 12 (for `COMPUTE`, `MOVE`, `DISPLAY`, etc.); valid program text cannot pass column 72. There's a pitfall tested on this machine: GnuCOBOL 3.2.0 counts this column position by **byte**, not by character. Each Japanese literal character occupies 3 bytes, so a line that looks short in characters can still be truncated at byte 72, producing errors like "missing string closing quote." So when you change `DISPLAY` text, don't let that line graze column 72; this lesson's two longest `DISPLAY` lines (containing `MOVE後利息` and `COMPUTE切捨て利息`) are 62 bytes each, and the longest comment line is 71 bytes — none of them over the limit.

## Modification Exercise (with answer)

Change `WS-DEPOSIT`'s initial from `250.55` to `200.65`, and `WS-PERIOD-RATE`'s initial from `0.0125` to `0.0150`; then re-check, compile and run, and verify the pre-interest balance, the four-decimal interest, the `MOVE` result, the truncated and rounded `COMPUTE` results, and the closing balance. The full prompt, constraints, and expected diff are in [`exercise.md`](./exercise.md); the reference answer and the manual computations are in [`answer.md`](./answer.md).

## Apply It Elsewhere Exercise (no answer)

Design a "monthly interest accrual" entry for another deposit: pick your own opening balance, demonstration rate, four-decimal intermediate field, and two-decimal receiving field; demonstrate `MOVE`, `COMPUTE` without `ROUNDED`, and `COMPUTE` with `ROUNDED`; explain which rounding rule you chose and its business implications. Use only independent fields, `VALUE`, `MOVE`, `COMPUTE`, `DISPLAY`, and `STOP RUN`. Submit the source, the compile commands, the actual output, and the verification formula. The prompt is in [`exercise.md`](./exercise.md); no answer is provided.

## Walking Through a Real Workflow

If you put this money logic into the full chain, it looks like this:

1. **Interest-posting night, the scheduler pulls up the interest batch.** The batch pulls opening balances and rates from the account master (in real life those come from files or a database — here we use program-internal constants), feeds the balance and rate into this lesson's `MOVE` / `COMPUTE`, and computes the post-transaction balance, the interest, and the closing balance.
2. **Downstream first checks how the interest was decided.** The closing balance will be written back to the account master; the next day, the reconciliation program compares it against the core system's recomputation. Pick the wrong picking rule, and the two systems' balances are off by a single cent.
3. **The same batch of amounts will be used by later lessons.** Lesson 04 onwards adds conditions to these amounts — judging whether a transaction should be accepted or rejected. From lesson 15 the amounts are read from real transaction files, no longer constants. Lesson 26 unifies overflow and failure reporting. By lesson 32, the whole amount chain is reconciled against the account master.

To be clear, this lesson's segment is not yet a production-ready batch: it has no input file, no rejection logic, and no overflow check — putting it alone into a nightly run will only show where that one-cent gap appeared.

## What Happens if This Code Goes to Production

- **Who schedules it**: the interest-posting night's batch scheduler pulls up the interest, write-back, and reconciliation steps in their dependency order; it only honors the exit code, not the screen.
- **Who reads its output**: ops looks at standard output and standard error; accounting and reconciliation look at whether balances match. So "which lines are business results, which line is just an environmental warning" must be clearly distinguishable.
- **How the next system picks it up**: the computed closing balance is written back into the account master; the next day, reconciliation compares it line by line against the core system's convention — off by one cent and the whole batch hangs.
- **The accident most likely to occur in the first month**: treating "no `ROUNDED` means truncate" as the bank-wide convention, ending up one cent off the accounting rule; or sizing the amount field's integer positions to the line at hand, so larger balances silently lose high-order digits while the program reports success.

In a bank's batch, `MOVE` is common for field-to-field moves, layout transforms, and output prep; `COMPUTE` is common for balances, fees, interest, and control totals. They look simple but are the landing points for amount correctness: the receiving field's decimals decide rounding, its integer capacity decides overflow, and any mismatch with the business rule will desynchronize the balance from the business convention — the program may not even error. Before any real batch goes live, you must fix the field's currency, integer digits, decimal digits, maximum value, negative rule, rounding position, and overflow policy — and cross-check with independent calculation or control totals.

This lesson only proves that "the same interest under different rules gives different results, and the closing balance changes by `0.01`"; it has made no accept/reject decisions — branching starts in lesson 04, using the same amount fields to decide whether a transaction is accepted; file input starts in lesson 15, making amounts come from real transaction files instead of constants; overflow and failure reporting are unified in lesson 26; the entire amount chain is finally reconciled against the account master in lesson 32's project.

## References

- [GnuCOBOL Programmer's Guide: Arithmetic Expressions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Arithmetic-Expressions)
- [GnuCOBOL Programmer's Guide: COMPUTE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#COMPUTE)
- [GnuCOBOL Programmer's Guide: Simple MOVE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Simple-MOVE)
- [GnuCOBOL Programmer's Guide: ROUNDED](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ROUNDED)
- [GnuCOBOL Programmer's Guide: ON SIZE ERROR / NOT ON SIZE ERROR](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#ON-SIZE-ERROR-_002b-NOT-ON-SIZE-ERROR)
- Course home in the repository: [README.md](../../README.md)
