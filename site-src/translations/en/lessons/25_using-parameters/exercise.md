---
_translated_from: lessons/25_using-parameters/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 25 Exercises: Data Direction of Call Parameters

Source files for this lesson: main program `lesson.cob`, subprograms `add_one_25.cob` (`ADD-ONE`) and `report_binary_25.cob` (`REPORT-BINARY`), and parameter declaration `copybooks/AMOUNT-INTERFACE.CPY`. See [`README.md`](./README.md) for the explanation and expected results.

After each change, recompile all three source files with the same command (`-I copybooks` is required):

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

The compiler’s “unfinished” warning for `BY VALUE` is expected in this lesson’s environment. All three runtime self-checks should still pass (`集計 合格=003 不合格=000`), with exit code `0`.

## Modification Exercises (answers in [`answer.md`](./answer.md))

Start both exercises from the **current source**; they are independent. Do not change `report_binary_25.cob` or the Copybook.

1. **Change the subprogram increment to 2.**
   - Locations: in `add_one_25.cob`, change `ADD 1 TO AMOUNT-ARGUMENT` → `ADD 2 TO AMOUNT-ARGUMENT`; in `lesson.cob`, in `1100-TEST-REFERENCE`, change `WS-EXPECTED` from `11` to `12`.
   - Constraint: leave all other paragraphs, expected values, and `WS-MODE` labels unchanged.
   - Expected result: after the `BY REFERENCE` call, the caller sees `12`; in the `BY CONTENT` section, the subprogram displays `22` internally while the caller remains at `20`; the `BY VALUE` section remains at `30`; the summary is `集計 合格=003 不合格=000`, with exit code `0`.
   - Question: Why does the value displayed inside the same subprogram change in both sections, while the caller’s field changes in only one?

2. **Change the second call to `BY REFERENCE`.**
   - Locations: in `lesson.cob`, in `1200-TEST-CONTENT`, change `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` → `... USING BY REFERENCE AMOUNT-ARGUMENT`; change `WS-EXPECTED` in the same paragraph from `20` to `21`; change `WS-MODE` in the same paragraph from `"BY CONTENT"` to `"BY REFERENCE"`.
   - Constraint: leave paragraphs `1100` and `1300` unchanged.
   - Expected result: after the call, the caller sees `21`; this passing result is counted under `BY REFERENCE`. The summary is `方式 BY REFERENCE=002 BY CONTENT=000 値=001`, `集計 合格=003 不合格=000`, with exit code `0`.
   - Question: What does the program display if you change `BY CONTENT` to `BY REFERENCE` but leave `WS-EXPECTED` and `WS-MODE` unchanged? Why is changing only the call mode insufficient?

For both exercises, save the complete standard output and identify the “value inside the subprogram” separately from the “caller’s field value.”

## Extension Exercise (no answer provided)

Use an interface Copybook to add an amount input field and a status output field (status values `VALID` / `REJECTED`). Have the subprogram write the status back using `BY REFERENCE`, then branch on the status field after `CALL` in the main program. Next, change only the status parameter to `BY CONTENT` and compare whether the caller still receives the status. Record the caller’s result in both calls, the parameter positions, the `PIC`/`USAGE` of both fields, and the input values you used to check both a valid and an invalid case.

As a boundary check, deliberately make the status parameter’s passing mode disagree with the subprogram’s `PROCEDURE DIVISION USING` declaration (for example, caller uses `BY VALUE` while the subprogram receives it by default `BY REFERENCE`). Record what you observe: whether compilation reports an error, whether execution completes normally, and whether the status field can be trusted. Explain why this kind of interface error cannot be caught by a program self-check.

No answer is provided. Do not use `BY VALUE` for a group item or data of arbitrary length, and do not assume that the storage layout or cross-platform behavior of the three passing modes is the same. You decide and explain the field design, parameter order, test input values, and observed behavior.
