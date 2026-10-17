---
_translated_from: lessons/25_using-parameters/README.md
_translated_by: site-src/translation agent
---

# Lesson 25: USING — How Are Parameters Passed, and Who Can Change Them?

## The Business Setting

Halfway through an interface review, someone from the team next door looks up and says:

> “We need to call your validation subprogram too. Input parameter: amount.”

Then they turn the page. Nobody asks whether the parameter is read-only or written back, or whether the subprogram can change the field the caller passed in. It is called “amount”—what else could there be to it?

You might think, “It only looks at an amount. What could go wrong?” Three months later, something does. A colleague adding logic to the subprogram changes the amount there. They think they changed their own local variable—but COBOL’s default is `BY REFERENCE`, so they changed the caller’s memory. The field in the main program changes too, while your code continues calculating the fee using the “original value.” These incidents are hard to trace: the place where the error occurs and the place where it shows up are several programs apart.

A more expensive failure comes from the two sides disagreeing. The caller uses one passing mode and the subprogram declares another, and **the compiler does not stop you**: compilation still exits with code `0`. At runtime, either the program immediately aborts with a signal—the overnight batch stops right there and the on-call phone rings—or, worse, it quietly prints a string of numbers nobody recognizes. The report finishes as usual, and nobody raises an alarm. This lesson runs both cases so you can see them.

This lesson has one job: make clear whether a parameter can change after a subprogram call, who is responsible for changing it, and who may only read it. That is the first thing to say when defining an interface, and also one of the easiest things for three people reviewing the same code to understand in three different ways.

(The passing-mode names, numbers, and output shown below are measured results from this lesson’s demonstration programs. They explain semantics and do not represent real data from any institution.)

## Why Learn This Now

In the previous lesson ([Lesson 24](../24_call-subprograms/README.md)), you moved amount validation into a standalone subprogram using `CALL`, `LINKAGE SECTION`, `PROCEDURE DIVISION USING`, and `GOBACK`. But one part was deliberately left unexplored: that lesson **used only one passing mode—the default**.

You might think: if the default works, why devote a whole lesson to it?

The catch is that Lesson 24’s result came back through the default mode: the subprogram changed the caller’s field, and the caller read the status back. That approach is not enough once you ask any of these questions:

- If a subprogram only needs to **read** an amount, how do I ensure it does not casually change my field?
- What if the parameter is not a display field such as `PIC 9(7)V99`, but a binary number (for example, an integer shared with code on the C side)? How should the interface be written?
- Is the value the subprogram sees actually the same thing as the value I see here?

These are questions about **data direction**: whether the parameter after `USING` is passed as an address or as a value, who is responsible for updating it, and when the caller can see a change. In Lesson 28, several subprograms and Copybooks will be brought together into a project that can be built repeatedly. Every parameter will need someone to state its read/write direction by then. If you leave it unspecified now, people will have to guess later.

This lesson demonstrates the cost of guessing wrong with actual runs (see “What Happens When the Passing Modes Disagree” below).

## What This Knowledge Point Is and What Problem It Solves

**What it is.** Each argument after `CALL ... USING` can be marked with a passing mode:

- `BY REFERENCE` — pass the field’s **storage address**. The subprogram has the caller’s memory itself, so a change also changes the caller’s field. This is also the default when no mode is written.
- `BY CONTENT` — pass a **temporary copy** of the contents. The subprogram can change the copy without changing the caller’s memory.
- `BY VALUE` — pass the **value itself**, not an address.

The three terms are not hard to memorize. The hard part is recognizing that they all answer the same question: **Is the thing in the subprogram’s hands the same thing as the one in the caller’s hands?**

**What business problem it solves.** Once a piece of logic is split into a module, “who is allowed to change this data?” becomes a question of responsibility. If the subprogram should update a balance in place, use `BY REFERENCE`. If it only needs to read an amount to decide whether it meets a rule, use `BY CONTENT` so that a future edit in the subprogram cannot quietly change the caller’s books with an incidental assignment. This is the first question to ask when handing off code, reviewing an interface, or investigating “where did the money go?”

**When not to use it this way.** `BY VALUE` is not suitable as a long-term interface contract: GnuCOBOL 3.2.0 in this lesson explicitly warns at compile time that it is not yet finalized (the exact warning appears below). This lesson treats it only as an observable semantic demonstration on the current toolchain, not as a production interface. When sharing a binary integer with another language, first verify it against the compiler version you have pinned. This lesson makes no promise of consistency across compilers or platforms.

## Capabilities and Limits After Completing This Lesson

After completing this lesson, you can:

- Pass the same `AMOUNT-ARGUMENT` to a subprogram in all three modes, observe caller fields of `11`, `20`, and `30` after the calls, and explain each value (the subprogram changed caller memory / changed only a copy / received only a value).
- Point out that `ADD-ONE`’s `PROCEDURE DIVISION USING` has no mode written and therefore means `BY REFERENCE`, while `REPORT-BINARY` declares `BY VALUE`; the two sides’ declarations must correspond.
- Use one Copybook so the caller (`WORKING-STORAGE`) and both subprograms (`LINKAGE`) share the same parameter declaration, and explain why the interface fails if the widths or signedness do not match.
- Read the self-check output and exit code: if all three checks pass, `集計 合格=003 不合格=000` and exit code `0`; if any check fails, `確認=失敗` and exit code `1`.
- Recall the exact GnuCOBOL 3.2.0 compile warning for `BY VALUE` and explain why it means “do not treat this as a stable contract.”

Limits: this lesson implements no business rules. It demonstrates only the data direction of the three passing modes—it does not validate amounts, read or write data files, or return business status. This lesson makes no promise about what happens when the number, type, or passing mode of arguments do not match, or about ABI compatibility across compilers and platforms. Writing a business conclusion such as `VALID`/`REJECTED` back to the caller is left to the extension exercise; [Lesson 28](../28_modular-batch-project/README.md) is where `CALL ... USING` is used to organize a project with multiple programs and Copybooks.

## Runtime Environment

- GnuCOBOL 3.2.0, default dialect (do not add `-std=cobol85`); source files use fixed format.
- Linux terminal; no database or third-party tools required.
- The three source files must be compiled and linked together: main program `lesson.cob` calls `add_one_25.cob` (`PROGRAM-ID. ADD-ONE`) and `report_binary_25.cob` (`PROGRAM-ID. REPORT-BINARY`).
- The parameter declaration comes from `copybooks/AMOUNT-INTERFACE.CPY`. Compilation must be able to resolve `COPY "AMOUNT-INTERFACE.CPY"`, so the command must include `-I copybooks`. Forgetting this causes compilation to fail immediately (the exact error is shown below).
- The program does not read or write business files. Its only result is standard output; the executable goes in `build/`.

## One Argument, Three Ways to Pass It

The main program runs three experiments with the same argument. Each asks just one thing: who owns this storage?

| Passing mode | What the caller writes | What the subprogram sees | Can the subprogram change the caller’s field? | Caller’s field after the call in this lesson |
|---|---|---|---|---|
| `BY REFERENCE` | Pass the field’s storage address | The same storage area | Yes | `11` |
| `BY CONTENT` | Pass a temporary copy of the contents | A temporary copy | No (only the copy changes) | `20` |
| `BY VALUE` | Pass the value itself, at full word size | A value parameter | Not applicable: `REPORT-BINARY` only reads it | `30` |

In terms of use, that is three statements: use `BY REFERENCE` when the subprogram should **write a result back**; use `BY CONTENT` when the subprogram should **consume input without being able to pollute the caller’s storage**; consider `BY VALUE` only when the parameter itself is a binary value, such as an integer shared with code on the C side.

One detail to remember when reading the third row: the caller’s field does not change on the `BY VALUE` path **not because it is necessarily safe**, but because `REPORT-BINARY` does not write anything back. The passing mode determines whether it can change; whether it does change depends on whether the subprogram writes to it.

## Positional Parameters; Use a Copybook to Lock Their Shape

Arguments after `USING` match by **position**, not by name: the first argument matches the first parameter in the subprogram’s `PROCEDURE DIVISION USING`, the second matches the second, and there is no name-based comparison. The subprogram must also use the same declaration in its `LINKAGE SECTION` to “receive” this storage, so the caller and both subprograms must `COPY` the same `AMOUNT-INTERFACE.CPY`.

The parameter declaration in this lesson is:

```cobol
       01 AMOUNT-ARGUMENT USAGE BINARY-LONG.
```

It has no `PIC`; it uses GnuCOBOL’s full-word binary form. A `LENGTH OF` probe in this lesson measured it as **4-byte signed** (it can store `-5` and return it unchanged), so the value passed by `BY VALUE` is a 4-byte integer.

Think about why this must be in a shared Copybook: even if the positions match, the interface is useless if the shapes do not. If the caller declares a 4-byte signed field but the subprogram mistakenly declares a 2-byte field, the position and mode can both be correct and the number can still be wrong—and the compiler will not catch it for you.

## How This Differs from Lesson 24

Lesson 24 had only one implicit mode, `BY REFERENCE`, so the subprogram always rewrote the caller’s result field in place. There was no second possibility. This lesson makes **data direction something you choose explicitly**, and gives you a way to check it: run each of the three modes, then compare the caller’s field with the expected value hard-coded in the program.

## Input and Rules

- **Input:** No external files or command-line arguments. The three test values `10`, `20`, and `30`, along with expected values `11`, `20`, and `30`, are hard-coded in paragraphs `1100/1200/1300` of `lesson.cob`. They are demonstration data, not business data.
- **Parameter:** One `AMOUNT-ARGUMENT`, type `USAGE BINARY-LONG` (4-byte signed integer, with no implied decimal places). It means “an integer to increment or display.”
- **Precondition:** The caller’s passing mode must match the subprogram’s `PROCEDURE DIVISION USING` declaration. Changes to `AMOUNT-ARGUMENT` in the subprogram reach the caller’s storage only with `BY REFERENCE`.
- **What the code actually checks:** `8100-CHECK-ACTUAL` compares the “caller’s field after the call” with `WS-EXPECTED`. If they match, it prints `合格` and increments the counter for the mode in `WS-MODE`; if not, it prints `不合格` and **does not increment any mode counter**.
- **What the code actually does at shutdown:** if `WS-FAIL-COUNT` is nonzero, it runs `MOVE 1 TO RETURN-CODE`.
- **What nobody checks:** the program does not check whether the value actually received by the subprogram matches the caller’s field (the semantics of `BY CONTENT`/`BY VALUE` can only be observed externally). Nobody checks whether the caller and subprogram use the same passing mode, either, and the compiler reports no error—there is a concrete example in the next section.

## Run and Observe

**Where to run it:** in this lesson’s directory. The program does not depend on relative filenames; the executable goes in `build/`.

**Commands and what each step does:**

```sh
mkdir -p build
cobc -fsyntax-only -I copybooks lesson.cob add_one_25.cob report_binary_25.cob   # 只做语法检查
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob                                 # 编译并链接三个程序
./build/lesson_25                                                                # 运行
echo $?                                                                          # 查看退出码
rm -rf build                                                                     # 清理可执行文件
```

- `-fsyntax-only` parses the syntax only; it does **not** generate an executable or run the program. Passing this check does not mean the program can run.
- `-x` requests an executable, and `-o` sets its output path. All three source files appear on the same command line and link into one executable.
- `-I copybooks` lets `COPY "AMOUNT-INTERFACE.CPY"` find the Copybook. **If it is omitted, compilation fails immediately**. The measured error was:

  ```text
  lesson.cob:12: error: AMOUNT-INTERFACE.CPY: そのようなファイルやディレクトリはありません
  lesson.cob:35: error: 'AMOUNT-ARGUMENT' is not defined
  ...
  ```

  The `COPY` in all three files reports that the file does not exist, followed by a series of “`AMOUNT-ARGUMENT` is not defined” errors: **6 `error` lines** in total, and the compile command exits with code **`1`**.
- `rm -rf build` deletes only the executable generated by this lesson; the lesson produces no business data files.

**Expected results (normal path):**

| Observation | Expected value |
|---|---|
| `cobc -fsyntax-only` exit code | `0`, with one warning on standard error that `BY VALUE` is unfinished |
| `cobc -x -Wall` exit code | `0`, with only the same warning on standard error and no other diagnostics |
| Standard output | 11 lines, 540 bytes (UTF-8), shown below |
| Process exit code (`echo $?`) | `0` |
| Generated file | Only `build/lesson_25` |

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=001 BY CONTENT=001 値=001
```

**The compiler warning: exact text and meaning.** Both syntax checking and the `-Wall` compilation print the same warning to standard error (the line number is from line 11 of this lesson’s current `report_binary_25.cob` source):

```text
report_binary_25.cob:11: warning: handling of parameters passed BY VALUE is unfinished; implementation is likely to be changed [-Wunfinished]
```

In plain language: GnuCOBOL 3.2.0 considers the `BY VALUE` implementation unfinished, and its behavior may change in later versions. Therefore, do not treat it as an interface contract that is already stable. Compilation still succeeds (exit code `0`), and on this toolchain the program produces the results above. This lesson keeps `BY VALUE` so that data direction can be explained through an observable result, not to recommend it for production interfaces. For real cross-language or long-lived interfaces, either verify against the GnuCOBOL version you have pinned or use one of the other two modes in this lesson.

**What the three results show:**

1. `BY REFERENCE`: before the call, the caller has `10`; `ADD-ONE` adds one and displays `11`; after return, the caller also sees `11`. The subprogram changed the caller’s storage itself.
2. `BY CONTENT`: before the call, the value is `20`; inside the subprogram it displays `21`, but the caller still has `20` after return. The increment happened on a temporary copy, which is discarded afterward.
3. `BY VALUE`: `REPORT-BINARY` displays `30` and does not write to it; the caller’s field remains `30`.
4. All three self-checks pass (`合格=003`), once for each passing mode, with exit code `0`.

**Japanese labels in the output (label → meaning):** `呼出側=呼出前` is the caller’s field before `CALL`; `被呼出側=加算後` is the value seen inside `ADD-ONE` after incrementing (for `BY CONTENT`, this is the copy); `被呼出側=受取値` is the value received by `REPORT-BINARY`; `呼出側=呼出後` is the caller’s field after the call returns; `確認=合格/失敗` is the result of this self-check; `集計 合格/不合格` is the number of passing/failed checks out of three.

The labels on the last line, `方式 BY REFERENCE=001 BY CONTENT=001 値=001`, are slightly misleading: it is meant to show the number of passing checks for each of the three modes, but the label for the third column (`BY VALUE` count) is `値=` (“value”), not `BY VALUE=`. Therefore, `値=001` is a **count**, not the value `30` shown earlier. Use the output guide above to interpret it.

### What Happens When the Passing Modes Disagree (Observed, Not Expected)

The caller and subprogram each declare the mode for `USING`; **the compiler does not check whether they match**. Two counterexamples were run on the verified toolchain in this lesson:

- **Caller uses `BY VALUE`, while the subprogram still uses the default `BY REFERENCE`:** the compile exit code is still `0` (with only the original `BY VALUE` warning), but execution aborts immediately with `attempt to reference invalid memory address (signal)` on standard error. The process exits with code **`139`**, and standard output contains only the first line (the value before the first `BY REFERENCE` call).
- **Caller uses `BY REFERENCE`, while the subprogram declares `BY VALUE`:** compilation and execution both “succeed” (exit code `0`), but the subprogram prints the address as if it were a value. The number in `被呼出側=受取値=` differs on each run—for example, runs showed `248421696`, `238583104`, `101783872`, and `423946432`; earlier records showed `802200896`, `631190208`, `646650048`, and `937214656`. The numbers themselves have no meaning: they are a memory address printed as an integer. The truly bad part is that the caller’s self-check still says `合格`, because `8100-CHECK-ACTUAL` only looks at the caller’s own storage and cannot see what happened on the subprogram side.

This is why the interface contract must be fixed through a Copybook, naming, and review. Do not expect the compiler or a self-check to catch it. **These observations are not cross-platform conclusions**: they show only that, on GnuCOBOL 3.2.0 and this repository’s toolchain, mismatched modes can either crash immediately or quietly produce a wrong number.

### Failure Path: Exit Code When a Self-Check Fails

Change `WS-EXPECTED` from `11` to `99` in `1100-TEST-REFERENCE` (leave everything else unchanged), then rebuild and run. The observed results are:

| Observation | Actual value |
|---|---|
| `cobc -x -Wall` exit code | `0` |
| Output line | `呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=失敗` |
| Summary line | `集計 合格=002 不合格=001` |
| Mode-count line | `方式 BY REFERENCE=000 BY CONTENT=001 値=001` |
| Process exit code | `1` |

Remember two details: the failed check is **not** included in any mode count (so `BY REFERENCE=000`), and `RETURN-CODE` is set to `1`. A calling script or build pipeline can use this number to determine that “the interface behavior did not match expectations.”

**Not everything on standard error is your output.** Runtime standard error also shows `Warning: program compiled against libxml 212 using older 209`. This is an environment warning caused by different linked-library versions in this workspace; it is unrelated to the compile-time `BY VALUE` warning. Neither is business output from this program.

## Source Reading Path

Read by following the “data direction,” rather than line by line:

1. `copybooks/AMOUNT-INTERFACE.CPY`: the only effective declaration is `01 AMOUNT-ARGUMENT USAGE BINARY-LONG.`. It has no `PIC`; all three programs share this declaration, which is what makes the interface consistent.
2. `WORKING-STORAGE SECTION` in `lesson.cob`: `COPY "AMOUNT-INTERFACE.CPY".` brings the parameter declaration into the caller; its parameter lives in `WORKING-STORAGE`. `WS-EXPECTED` and `WS-ACTUAL` are also `BINARY-LONG`; `WS-EDITED-ACTUAL` is `PIC 9(9)` and only formats the binary value as nine displayed digits.
3. `1100-TEST-REFERENCE`: first set `10` and expected `11`, then call `ADD-ONE` using explicit `BY REFERENCE`. “Explicit” is for teaching; omitting the mode also defaults to `BY REFERENCE`.
4. `1200-TEST-CONTENT`: use the same subprogram and argument, but switch only the mode to `BY CONTENT`; the expected value is `20` because the caller should not be changed.
5. `1300-TEST-VALUE`: use another subprogram, `REPORT-BINARY`, with `BY VALUE`; the expected value is `30`.
6. `add_one_25.cob`: the `LINKAGE SECTION` copies the same declaration. `PROCEDURE DIVISION USING AMOUNT-ARGUMENT` has no mode, so it means `BY REFERENCE`; `ADD 1 TO AMOUNT-ARGUMENT` writes directly to the caller’s storage (or to the copy).
7. `report_binary_25.cob`: the only difference is `PROCEDURE DIVISION USING BY VALUE AMOUNT-ARGUMENT`; here `AMOUNT-ARGUMENT` is a “value parameter,” and the program only reads it with `MOVE`.
8. `8100-CHECK-ACTUAL`: move the caller’s field after the call into `WS-ACTUAL` and compare it with `WS-EXPECTED`. If they match, increment the counter and print `合格`; if not, only increment the failure count. `9000-DISPLAY-SUMMARY` prints the totals, and `0000-MAIN` sets `RETURN-CODE` to `1` if `WS-FAIL-COUNT` is nonzero.

## Fixed-Format Check (By Bytes)

GnuCOBOL 3.2.0 counts **bytes** in UTF-8 source files, so Chinese comments count too. These three commands check the lesson’s four source files (`LC_ALL=C` makes `awk` count bytes):

```sh
for f in lesson.cob add_one_25.cob report_binary_25.cob copybooks/AMOUNT-INTERFACE.CPY; do
  LC_ALL=C awk 'length($0)>72 {print "over72", FILENAME, FNR, length($0)}' "$f"
  LC_ALL=C awk '/^      \*/ {next} {i=match($0,/[^ ]/); if (i>0 && (i<8 || (i>=9 && i<=11))) print "bad column", FILENAME, FNR, i}' "$f"
  LC_ALL=C awk '{if (length($0)>m) {m=length($0); n=FNR}} END {print FILENAME, "max bytes", m, "line", n}' "$f"
done
```

Observed results: the first two commands produce no output for all four files; the third reports `lesson.cob max bytes 70`, `add_one_25.cob max bytes 69`, `report_binary_25.cob max bytes 71`, and `copybooks/AMOUNT-INTERFACE.CPY max bytes 70` (all on line 1, the longest Chinese comment). All executable program text starts in column 8 (`DIVISION`, level `01`, and paragraph names) or column 12 (statements); this lesson has one level `01` parameter and no level `05` field. If a subordinate level is added to the Copybook later, the repository convention places level `05` in **column 11**. Comments use `*` in column 7. Remember: `-fsyntax-only` does not report column positions. Use the commands above; do not expect the compiler to alert you.

## Modification Exercises (with Answers)

Both exercises start from the **current source** (the three `.cob` files above plus the Copybook). After each change, rerun the same `cobc -x -Wall -I copybooks ...` command. Full questions and starting values are in [`exercise.md`](./exercise.md); reference answers are in [`answer.md`](./answer.md).

1. **Change the subprogram increment to 2:** in `add_one_25.cob`, change `ADD 1 TO AMOUNT-ARGUMENT` to `ADD 2 TO AMOUNT-ARGUMENT`, and in `1100-TEST-REFERENCE` in `lesson.cob`, change `WS-EXPECTED` from `11` to `12`. Leave everything else unchanged. Expected: after the `BY REFERENCE` call the caller has `12`; after the `BY CONTENT` call the caller still has `20` (while the subprogram displays `22`); the `BY VALUE` section is unchanged; `集計 合格=003 不合格=000`, exit code `0`.
2. **Change the second call to `BY REFERENCE`:** in `1200-TEST-CONTENT` in `lesson.cob`, change `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` to `BY REFERENCE`, change `WS-EXPECTED` in that paragraph from `20` to `21`, and change `WS-MODE` from `"BY CONTENT"` to `"BY REFERENCE"`. Expected: after the call, the caller has `21`, and this check is counted under `BY REFERENCE`; the summary becomes `方式 BY REFERENCE=002 BY CONTENT=000 値=001`, with exit code `0`.

## Extension Exercise (No Answer)

Extend the interface: add a second parameter to `AMOUNT-INTERFACE.CPY`, a status field that the subprogram writes back as `VALID` or `REJECTED`. Have the subprogram write this status to the caller **only through `BY REFERENCE`**, and branch on the status field after `CALL`. Then, separately, change the status parameter to `BY CONTENT`, recompile and run, and record whether the caller can still receive the status. State the parameter order, the `PIC`/`USAGE` of both fields, and each field’s value before and after the call. Verify with at least two input values, one valid and one invalid.

As a boundary check, deliberately make the passing mode for the status parameter disagree with the subprogram declaration, and record what you actually observe: whether compilation reports an error, whether execution is normal, and whether the status field can be trusted.

No answer is provided. Do not use `BY VALUE` for a group item or data of arbitrary length, and do not assume that the storage layout or cross-platform behavior of the three passing modes is the same. The exercise is in [`exercise.md`](./exercise.md).

## Trace a Real Workflow

Placed back into the processing chain, this lesson fits like this:

1. **Define the interface shape first.** After Lesson 24 extracts validation logic into a subprogram, the interface is “the first parameter passes the amount; the second returns status.” This lesson adds the statement that is easiest to omit: the subprogram **only reads** parameter one and **writes back** parameter two. Put this agreement in a shared declaration such as `AMOUNT-INTERFACE.CPY` (introduced in Lesson 23), which the caller’s `WORKING-STORAGE` and the subprogram’s `LINKAGE` both `COPY`. This is the only way for both sides to “see the same shape,” and it is also why the counterexample at the end of this lesson is possible.
2. **Arrange arguments according to the agreement.** The main program orders them in `CALL ... USING`; the subprogram receives them in the same order in `PROCEDURE DIVISION USING`. Names are not part of matching, so parameter order is itself part of the contract.
3. **Someone must handle failures.** This lesson’s `RETURN-CODE` says only whether the self-check passed. In a real chain, first distinguish a business rejection from a system failure ([Lesson 26](../26_error-handling/README.md)), then write it to a log ([Lesson 27](../27_logging/README.md)).
4. **Pass it on.** [Lesson 28](../28_modular-batch-project/README.md) organizes multiple subprograms and Copybooks into a repeatable build; the reconciliation project in [Lesson 32](../32_bank-reconciliation-project/README.md) passes real records across these module boundaries and uses the returned status to decide whether the batch continues or stops.

In one sentence: what this lesson produces is not merely “a program that runs,” but **an interface agreement that other people can reuse**—one that every later lesson will use.

## What Would Happen If This Code Went into Production

- **Who schedules it:** not the overnight scheduler. This kind of program is a one-time check in a build pipeline or before a release; run it after an interface change to see whether the three data directions still match expectations.
- **Who reads the output:** the person who wrote the interface, the person reviewing it, and the unlucky colleague who changes this code three months later. They read the 11 lines and the exit code.
- **How the next system connects:** programs in Lessons 28 and 32 will `COPY` the Copybook together. Change the parameter width by one byte and every consumer’s semantics must be recalculated.
- **The most likely first-month incident:** treating “compilation passed, exit code `0`” as “the interface is fine.” In both counterexamples above, compilation did not report an error, but one run crashed and the other quietly returned a wrong number.
- **The next easy trap:** putting `BY VALUE` into production as a “clean cross-language contract.” The compiler itself warns that it is unfinished.
- **What it does not handle yet:** there are no business rules, error-code versioning, nullable/missing-value policy, or enforcement that the caller and subprogram must be recompiled together. This lesson provides none of what a real interface needs here. Before telling someone during a handoff that “the interface is fine,” think about which pieces are missing.

## Evidence and Verification Scope

Every observation in this document comes from running the commands above in the current repository. The scope is:

| Scenario | Command actually run | Observed result |
|---|---|---|
| Normal path | The full sequence in “Commands and What Each Step Does” (`-fsyntax-only`, `-x -Wall`, run, `echo $?`) | Compile `0`, run `0`, 11 lines / 540 bytes of standard output, identical to the block above |
| Failure without `-I` | `cobc -fsyntax-only lesson.cob add_one_25.cob report_binary_25.cob` (remove `-I copybooks`) | All three `COPY`s report missing files, then `AMOUNT-ARGUMENT` is undefined; 6 `error` lines total; exit code `1` |
| Failed self-check | Change `WS-EXPECTED` to `99`, then rebuild and run | `確認=失敗`, `合格=002 不合格=001`, `BY REFERENCE=000`, exit code `1` |
| Parameter-width probe | Temporarily write a small program that checks `LENGTH OF AMOUNT-ARGUMENT` and round-trips `MOVE -5` (using the same Copybook; not added to the repository) | Width `4` bytes; `-5` is read back unchanged, confirming it is signed |
| Topic boundary (mode mismatch) | Change one `CALL` at a time so its mode is opposite the subprogram’s declaration | One combination aborts at runtime (exit code `139`, only the first line remains on standard output); the other prints a different number on every run; see “What Happens When the Passing Modes Disagree” |
| Modification exercises 1 and 2 | Copy the lesson sources to a temporary directory, make the requested changes, then rebuild and run | Expected output in [`answer.md`](./answer.md), identical to the measured output |

Items outside the verification scope, and why they were not verified: whether `BY VALUE` is consistent with C-side functions, other compilers, or other platforms—the local machine has only GnuCOBOL 3.2.0 and no second compiler or platform for comparison; behavior when the argument count or `PIC` does not match—would require constructing another counterexample outside this lesson’s topic; whether changes to a `BY CONTENT` copy leave an observable trace inside the subprogram—the language provides no way to observe that. None of these are promised by this lesson.

## References

- [GnuCOBOL Programmer’s Guide: PROCEDURE DIVISION USING](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#PROCEDURE-DIVISION-USING)
- [GnuCOBOL Programmer’s Guide: CALL](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#CALL)
- [GnuCOBOL Programmer’s Guide: USAGE](https://gnucobol.sourceforge.io/HTML/gnucobpg.html#USAGE)
- [Lesson 24: CALL — Split Validation Logic into a Subprogram](../24_call-subprograms/README.md)
- Course home in the repository: [README.md](../../README.md)

