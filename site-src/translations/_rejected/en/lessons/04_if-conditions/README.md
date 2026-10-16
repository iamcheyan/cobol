---
_translated_from: lessons/04_if-conditions/README.md
_translated_by: site-src/translation agent
---

# Lesson 04 — IF Conditions: Separate Accept from Reject for a Transaction

A transaction comes in and the program must give it a verdict on the spot: through, or not through; and if not, which rule rejected it. This lesson pins a sample transaction inside the program and applies three levels of nested `IF` to decide, in order, "amount must be positive → amount must not exceed the per-transaction limit → account status must be valid", and reports only the **first** failure rule that matches.

## The Business Setting

It's 4:50 p.m. on a Friday and the branch is about to close. A customer hands a transfer slip to the teller; almost at the same moment, someone on the mobile app taps "confirm transfer." Both of these actions become the same thing inside the system: a transaction waiting to be validated. The program must give the result on the spot. Letting it through is the easy case; the trouble starts the moment the verdict is "reject."

A reject is never the end of the story. The teller's screen will not just say "rejected"; the customer will definitely ask "why." The answer is always one of two kinds: either the **amount itself is non-compliant** (not positive, or over the per-transaction limit) — in which case the money never moved, the teller explains on the spot, and the customer rewrites the slip — or the **account status is wrong** (frozen, closed) — in which case this business should never have been handled at the teller in the first place, and has to be escalated to manual verification. Two different "rejects" — one you can finish on the spot, one that needs the customer to come back another day — and the only thing that distinguishes them is which reason the program reports.

The easiest thing to get wrong is **order**. Flip the judgment order, and a transaction that is both over the limit and frozen might get reported as "amount over limit", which makes the teller say to the customer "just make the amount smaller and try again" — and it is still rejected. The customer makes a wasted trip and the branch has to explain a second time. So this lesson does not only ask you to "separate accept from reject"; it also asks you to be able to explain **why only the first matched reason is reported, and who set that order**.

Another rule that's easiest to be vague about: is the per-transaction limit "reject when it's 1000.00" or "reject when it's over 1000.00"? The requirement usually reads something like "per-transaction amount must not exceed 1000 yuan," a single sentence with two possible readings. In the program `>` and `>=` differ by one character, and the endpoint lands on different sides. This kind of ambiguity doesn't make the program error, but it lets two systems each write their own logic and have mismatched ledgers at month-end. This lesson treats the endpoint as something that must be written explicitly and verified.

(This is a teaching scenario: the institution, amounts, and timestamps were made up to explain the rules; they are not real data from any real institution.)

## Why Learn This Now

You might be thinking: "Conditions? I've been writing `if` for years."

The problem is that what you've written before was mostly "run once and done" scripts. The scenario here is different: **a COBOL program runs top to bottom with no place to "stop and ask".** In lesson [02](../02_data-types/README.md) you learned how to use `PIC` to describe the account number, status, and amount; in lesson [03](../03_move-compute/README.md) you learned how to compute a result from them; but up to this point the program just runs from top to bottom.

Look back at that Friday-afternoon transaction: amount `-5.00`, account still frozen. Without conditions, the program keeps going — still "computes," still prints a "processing complete" line. It doesn't reject, and won't tell you where the problem is. In business terms that is worse than a crash: the job looks green, but the ledger is wrong.

Put it in language you already know: the account status field in real data can hold anything, so the program must decide which way to go based on the data, instead of having a human pre-sort the data and feed it as separate files.

The tools COBOL gives you are relational conditions and `IF` / `ELSE` / `END-IF`. It sounds like other languages, but two traps must be walked on in this lesson: which `ELSE` belongs to which `IF` is decided by **scope**, not indentation; **the nesting order is the priority order of rejection reasons.** Every subsequent branching lesson reuses these two points — lesson [05](../05_evaluate/README.md) classifies by transaction type; lesson [08](../08_control-flow-practice/README.md) tallies accept / reject across many transactions; the foundation is laid here.

## What This Knowledge Point Is, and What Problem It Solves

**What this knowledge point is.** One sentence: let the program **choose its own path based on the data**. Two things do this — *relational conditions* (`=`, `<`, `>`, `<=`, `>=`, comparing two values to yield true or false) and *`IF` / `ELSE` / `END-IF`* (the true path goes one way, the false path the other, with `END-IF` marking the end). Compared with lesson [03](../03_move-compute/README.md)'s arithmetic, it's a different ability: it no longer only asks "how much?", but asks "does it qualify?"

**What business problem it solves.** Validation is half about "judging correctly" and half about "explaining clearly." Teller, support, and reconciliation all see only one verdict plus one reason: amount over limit, status invalid, or passed. If the reason is wrong, everyone downstream will make the wrong call. `IF` plus nesting is where you **write the business priority into the code** — who is checked first, who is checked later; it's visible in the source, and when something happens you can point at that line and explain it.

**When it still isn't enough (misuse is more expensive).** Don't use conditionals to substitute for input validation. If upstream's amount field happens to contain letters, or the encoding is wrong, `IF` just makes a decision that *looks* correct on bad data — it won't notice the data itself is broken; that kind of check has to wait for later lessons. Also don't forget: a reject in this lesson is only a **business verdict**; the exit code is still `0`. Treating a business rejection as a system failure and alerting on it is another common accident, which lesson [26](../26_error-handling/README.md) handles specifically.

## Capabilities and Limits After Completing This Lesson

After this lesson you will be able to:

- Compare numeric and character fields with `=`, `<`, `>`, `<=`, `>=`, and explain which side of the boundary ends up in accept and which in reject.
- Use `IF` / `ELSE` / `END-IF` to write an explicit accept and reject path for each condition, without guessing `ELSE` binding by indentation or periods.
- Nest three levels of judgments in a fixed priority order, and explain why this outputs only **one** rejection reason, and how three flat `IF`s would match multiple rules simultaneously.
- Pre-compute and verify boundary samples: `0.00`, `-0.01`, `0.01`, `1000.00`, `1000.01`, plus judgment when the status is not `A`.
- Distinguish business rejection from system failure: in this lesson, every reject path still leaves the exit code at `0`.

Limits: this lesson does not read from terminal, file or database; the sample values are written in `VALUE` clauses of `WORKING-STORAGE`; there is only one transaction, no balance change, no counts or totals; no rounding or arithmetic overflow handling (lesson [03](../03_move-compute/README.md) hinted at this, lesson [26](../26_error-handling/README.md) handles it systematically); no transaction-type classification (lesson [05](../05_evaluate/README.md)) or multi-transaction batch (lesson [08](../08_control-flow-practice/README.md)). This lesson also does not implement account authorization, concurrency control, duplicate-request detection, or persistence — none of those are what this lesson is meant to prove.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not pass `-std=cobol85`), source files in fixed format.
- Linux terminal; no database, additional tools, or third-party libraries needed.
- Commands run inside the lesson directory `lessons/04_if-conditions/`; since the source path written is `lesson.cob`, running from another directory requires adjusting the path yourself.

## Knowledge Walkthrough

### Relational conditions: values are compared, not what's displayed

The five operators `=`, `<`, `>`, `<=`, `>=` are familiar; `THEN` is an optional word, with or without it is the same. Two details are worth remembering.

First, when two numeric operands are compared, COBOL compares by **actual algebraic value**, independent of how many digits the `PIC` declared, whether it carries a sign, or what `USAGE` is. `+0000125.50` and `125.50` are the same thing.

Second, character fields compare character by character over the character set, with the shorter side padded with spaces on the right. So `"A"` and `"a"` are two different characters — this matters especially when handling account statuses.

This lesson uses three relational conditions:

```cobol
WS-TRANSACTION-AMOUNT <= ZERO
WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
WS-ACCOUNT-STATUS = "A"
```

The first `<= ZERO` is true for zero and negatives; the second `>` is true only when the amount **strictly exceeds** the limit; the third is a character comparison — `a`, blank, and `I` all do not equal `A`.

The easiest trap here is: **which side of the boundary ends up where is fully decided by the operator.** `<=` puts `0.00` in the reject side; `>` keeps `1000.00` on the accept side. If you casually change `<=` to `<`, then `0.00` is let through; change `>` to `>=`, and a transaction exactly at `1000.00` gets rejected. So boundary values cannot be reviewed in isolation — they must be considered together with the operator, which is exactly the most typical form of "ambiguous requirement, systems each their own" mentioned earlier.

Status comparison is exact. `WS-ACCOUNT-STATUS` is an `X` type; `a` (lowercase), blank, and `I` all do not equal `A` and fall into the reject branch. If you really want both cases to pass, that's a convention at the interface layer and must be written explicitly — COBOL will not auto-normalize for you.

### IF / ELSE / END-IF and scope binding

`IF` executes the following statement when the condition is true; `ELSE` handles the false case; `END-IF` explicitly marks where this conditional ends.

Beginners often think indentation decides which `IF` an `ELSE` belongs to — COBOL does not look at indentation. The compiler's only rule is: **an `ELSE` belongs to the nearest `IF` that has not yet been closed.** No matter how pretty your indentation is, the compiler won't appreciate it.

In this lesson all three `IF`s come with `END-IF`, and they close from innermost to outermost, layer by layer. The benefit is that which `ELSE` belongs to which is visible at a glance in the source — no counting spaces, no guessing by periods.

A nastier one: **the period is not just "end of sentence" — it terminates the entire sentence, which also closes the scopes of any not-yet-closed statements.** Across this lesson, there is exactly one period in total: the final `STOP RUN.` The four initial `DISPLAY`s have **no** periods between them; they are statements arranged in the same sentence, executed in writing order. If you casually add a period in the middle, statements that originally belonged to an `IF` body might fall outside the condition — and the compiler may not even error.

### Nesting order decides which rejection reason gets reported

The order in which the three rules are nested is the priority order of rejection reasons:

```text
amount <= 0             -> AMOUNT_NOT_POSITIVE     (outermost, checked first)
  else amount > limit    -> AMOUNT_OVER_LIMIT
     else status = "A"   -> ACCEPTED
        else             -> ACCOUNT_INACTIVE        (innermost, checked last)
```

When the **first failure condition** is true, the program outputs its reason, and execution ends there — the deeper checks never run. So that transaction with amount `-5.00` and status `I` will only report `AMOUNT_NOT_POSITIVE`; it won't also tell you the status is problematic.

This directly answers "why must we nest?" If the three checks were written as flat `IF`s, two failure conditions would each match once, the program would output two contradictory reasons, and the person reading the log wouldn't know which to believe. In business, "what to say first" is a rule set by product and accounting, not arranged casually by the programmer — change the order, and the external explanation changes with it.

### Differences from Java / Python

For branching, Java uses `if` / `else if`, Python uses `if` / `elif` / `else` — the idea is the same. Two differences: COBOL uses `END-IF` to explicitly mark the statement's end; `ELSE` binds to "the nearest not-yet-closed `IF`", not by indentation. You still need to confirm types before comparing: account status is text, amount is signed decimal.

COBOL also supports `AND` / `OR` to compose compound conditions; this lesson deliberately doesn't use them. The reason is that nesting lets each rule's priority stand directly in the source — perfect for getting the feel of "which layer to check first." Compound conditions come later, when you read that grammar.

### On the language of output text

The repository has a convention: source comments and README explanations are written in Chinese, but **business text printed by the program at runtime remains in Japanese.** Fortunately you don't have to guess — everything the verdict needs is on the standard-output `key=value` lines; the two key values are `判定=` and `理由=`, with the Chinese mapping in the next section.

## Complete Example Source

The full source is [`lesson.cob`](./lesson.cob), written in fixed format (column 7 indicator, Area A from column 8, Area B from column 12, program text not past column 72).

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "口座状態=" WS-ACCOUNT-STATUS
           DISPLAY "取引金額=" WS-TRANSACTION-AMOUNT
           DISPLAY "上限金額=" WS-MAXIMUM-AMOUNT
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "判定=REJECTED"
               DISPLAY "理由=AMOUNT_NOT_POSITIVE"
           ELSE
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "判定=REJECTED"
                   DISPLAY "理由=AMOUNT_OVER_LIMIT"
               ELSE
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "判定=ACCEPTED"
                       DISPLAY "理由=WITHIN_RULES"
                   ELSE
                       DISPLAY "判定=REJECTED"
                       DISPLAY "理由=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
           STOP RUN.
```

The above omits comment lines in the source. The source's comments only explain the rules and contract (amount must be positive, limit includes endpoint, only the first failure reason is reported), not the `DISPLAY` text line by line.

## Data and Rules

This lesson gives you no input: the sample transaction is fully pinned inside the program, **no external input**, no input fixtures or result files. Exactly these four values participate in the verdict:

| Field | `PIC` / storage bytes | Initial value | Role |
|---|---|---|---|
| `WS-TRANSACTION-REFERENCE` | `X(12)` / 12 bytes | `TXN-00000001` | transaction identifier, only echoed, not part of the verdict |
| `WS-ACCOUNT-STATUS` | `X(1)` / 1 byte | `A` | account status; only `A` is treated as valid in this lesson |
| `WS-TRANSACTION-AMOUNT` | `S9(7)V99`, `SIGN IS LEADING SEPARATE CHARACTER` / 10 bytes | `125.50` | signed amount, judged from the lower-bound side |
| `WS-MAXIMUM-AMOUNT` | `9(7)V99` / 9 bytes | `1000.00` | per-transaction amount limit, inclusive of the endpoint |

The amount field's 10 bytes = 1 separate leading sign character + 7 integer digits + 2 decimal digits; `V` is the implied decimal point, **does not occupy storage**, and is only rendered by position when `DISPLAY` runs. So storage is 10 bytes, but what you see on screen — `+0000125.50` — is 11 characters. The byte counts above were measured by `FUNCTION LENGTH` on this machine and can be used as a baseline for later lessons' record layouts. This lesson does not have a currency field; by demonstration convention amounts are in yuan with two decimals, with no exchange rate or rounding.

Rules and boundary policies:

| Rule | Implemented as | Policy |
|---|---|---|
| Amount must be positive | `WS-TRANSACTION-AMOUNT <= ZERO` -> reject | zero and negative amounts are both rejected; `0.01` onward is accepted |
| Per-transaction limit | `WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT` -> reject | limit **includes the endpoint**; equal to `1000.00` is accepted, `1000.01` onward is rejected |
| Account status | `WS-ACCOUNT-STATUS = "A"` to be accepted | only the exact `A` is valid; `I`, `a`, blank and other characters all get the same reason |

The conditions the code actually checks are the three above. **Not** checked: transaction reference's format and uniqueness (this lesson only echoes it), the specific meaning of the status code (the program doesn't distinguish what `I` represents), the source of the amount limit (it is a demonstration constant). Caveat: `WS-MAXIMUM-AMOUNT` and the three sample values are teaching demonstration data; they do not represent any real business policy or regulatory limit.

## Where Boundary Values Branch

First remember: every reject here is a business reject, the exit code is still `0`, and the program has no system-failure branch at all. Every row in the table below was actually compiled and run on this machine:

| Amount | Status | Where the branch happens | `判定=` | `理由=` |
|---|---|---|---|---|
| `125.50` (original initial value) | `A` | all three conditions pass | `ACCEPTED` | `WITHIN_RULES` |
| `0.00` | `A` | layer 1 is true | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| `-0.01` | `A` | layer 1 is true | `REJECTED` | `AMOUNT_NOT_POSITIVE` |
| `0.01` | `A` | just above the lower bound; `<= ZERO` is false | `ACCEPTED` | `WITHIN_RULES` |
| `1000.00` | `A` | layer 2 is false (endpoint is included) | `ACCEPTED` | `WITHIN_RULES` |
| `1000.01` | `A` | layer 2 is true | `REJECTED` | `AMOUNT_OVER_LIMIT` |
| `125.50` | `I` | layer 3 is false | `REJECTED` | `ACCOUNT_INACTIVE` |
| `-5.00` | `I` | layer 1 is true, layer 3 **did not run** | `REJECTED` | `AMOUNT_NOT_POSITIVE` |

Who decides which branch:

| Observation target | Comparison that decides it | Result |
|---|---|---|
| Lower bound | `AMOUNT <= ZERO` | `0.00` and negatives rejected; `0.01` onward accepted |
| Upper limit | `AMOUNT > MAXIMUM` | only strictly greater is rejected; equal to `1000.00` is included |
| Status | `STATUS = "A"` | exact `A` only; `a`, blank, `I` all rejected |
| Which reason gets reported | the three-level nesting order | only the first matched failure rule |

## Source Reading Path

Read in the order of the data, faster than going line by line:

1. Start with those four fields in `WORKING-STORAGE`: status is `X(1)` text, amount is signed numeric — the later comparison behavior differs, and that's the root.
2. Then the four `DISPLAY`s after `PROCEDURE DIVISION`: first echo the input values that participate in the verdict, so you can compare inputs against the verdict. Note there are no periods between them; they are statements in the same sentence.
3. The outermost `IF WS-TRANSACTION-AMOUNT <= ZERO`: its `ELSE` only covers "amount is positive", so when the amount is wrong, the limit and status are not even checked.
4. Layer 2 `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT`: notice it uses strictly greater than, so the endpoint is included.
5. Layer 3 `IF WS-ACCOUNT-STATUS = "A"`: the innermost `ELSE` is the status rejection.
6. The three `END-IF`s close from innermost outward, with `STOP RUN.` at the end. The whole code has only this one period.

## Run and Observe

**Input:** none. All four values come from `VALUE` clauses in `lesson.cob`; nothing is read from keyboard, file, or database, so the verdict will **reproduce deterministically** — different from lesson [15](../15_sequential-file-read/README.md) onward.

**Commands and their roles:**

```sh
mkdir -p build                                   # create the output directory first; otherwise -o will fail
cobc -fsyntax-only lesson.cob                    # syntax check only; no executable produced
cobc -x -Wall -o build/lesson_04 lesson.cob      # compile and produce the executable
./build/lesson_04                                # run the program; the verdict is written to standard output
echo $?                                          # check the previous command's exit code
rm -rf build                                     # clean the build artifacts
```

Each command proves something different: `-fsyntax-only` only shows the source passes syntactic parsing, without producing or running a program; `-x` requires producing the executable, `-o` specifies the output path, and return code `0` with no diagnostics is the signal compile passed; running the executable is the only way to observe the verdict; `rm -rf build` just deletes the build artifacts, since this lesson produces no business data files, so cleanup loses nothing.

**Expected results (original initial values):**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0` |
| `cobc -x -Wall` exit code | `0`, no compile diagnostics |
| Standard output | the 6 lines below |
| Process exit code (`echo $?`) | `0` |
| Produced files | only `build/lesson_04` |

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000125.50
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

[Output line meanings: `取引参照番号` = transaction reference, `口座状態` = account status, `取引金額` = transaction amount, `上限金額` = limit amount, `判定` = verdict, `理由` = reason.]

**Standard error:** at runtime stderr will show `Warning: program compiled against libxml 212 using older 209`. This is the environmental libxml version warning and not the program's business output; judge business output by standard output and exit code, do not count an environmental warning on stderr as a program error.

### Boundary verification

Run additional cases by changing `WS-TRANSACTION-AMOUNT` and `WS-ACCOUNT-STATUS` values in `lesson.cob`, recompile, and confirm the verdict matches the table in the previous section. Each modification should be one of:

- change `WS-TRANSACTION-AMOUNT` to a boundary value (`0.00`, `0.01`, `1000.00`, `1000.01`, `-0.01`),
- change `WS-ACCOUNT-STATUS` to anything except `A` (e.g. `I`, lowercase `a`, blank).

After verification, revert the source to the original initial values (`125.50` / `A`).

## Modification Exercise (with answer)

Change `WS-TRANSACTION-AMOUNT` from `125.50` to `1000.00`, with no changes to any `PIC` or other initial values. Re-check, compile, and run; the only verdict line should change from `ACCEPTED` to either `ACCEPTED` (still accepted, since the endpoint is included) or another verdict depending on the rule. The full prompt and constraint are in [`exercise.md`](./exercise.md); the reference answer and manual verification are in [`answer.md`](./answer.md).

## Apply It Elsewhere (no answer)

Design another judgment for a different scenario, e.g. by transaction type. Decide on the priority of rules yourself, document which rule is checked first, and write at least three levels of nested `IF`s. Use only the constructs of this lesson: independent field declarations, `VALUE`, `IF` / `ELSE` / `END-IF`, relational conditions, `DISPLAY`, `STOP RUN`. Submit the source, the chosen rule order and your justification, the compile/run commands, the actual output for several boundary cases, and an explanation of which layer fires for each case.

## Walking Through a Real Workflow

If you put this judgment logic into the real flow, it looks like:

1. **Friday afternoon**, the teller's client or the app submits a transfer request to the queue; the front office routes it to the validation step.
2. **Validation step.** It pulls the amount, the account's current status, and the per-transaction limit from the master; this lesson's `IF` chain decides accept or reject, and which reason to give when rejected.
3. **If accepted**, the ledger-writing step would proceed (not in this lesson). If rejected, the original channel receives the verdict; the teller sees one reason line and explains it on the spot, while the app shows the user a message — both rely on this lesson's "only one reason" guarantee.
4. **The same structure** is reused in lesson [08](../08_control-flow-practice/README.md) for tallying over multiple transactions, and in lesson [26](../26_error-handling/README.md) for the difference between business reject and system failure.

## What Happens if This Code Goes to Production

- **Who schedules it**: in a real teller / app flow, the validation step is invoked by the request handling service — not by the nightly scheduler. But the same logic appears in the nightly batch, where each transaction is fed through validation row by row.
- **Who reads its output**: ops looks at logs (rejection rate, which reason dominates), tellers rely on the displayed reason; if the reason is misclassified, every downstream handler blames the wrong thing.
- **The accident most likely to occur in the first month**: writing the three checks as flat `IF`s, so a transaction with both over-limit amount and frozen status produces two contradictory reject reasons, leaving the operator unable to decide; or interpreting "does not exceed 1000" as `>=` instead of `>`, so a 1000-yuan transaction starts being rejected.

This lesson only proves that **"the same transaction, after different operator choices or rule orders, gives different verdicts — only one reason is reported, and that reason follows the priority order"**. It has not actually accepted or rejected anything: it works on a single in-program transaction with deterministic initial values, has no input file, no logging, and exits with code 0 on every path. Validation in the real world also has to handle whether the data itself is trustworthy — the next layer of error handling and the file/DB input path gets that in lessons [15](../15_sequential-file-read/README.md) and [26](../26_error-handling/README.md).

## References

- [GnuCOBOL Programmer's Guide: Conditional Expressions](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#Conditional-Expressions)
- [GnuCOBOL Programmer's Guide: IF statement](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#IF)
- Course home in the repository: [README.md](../../README.md)
