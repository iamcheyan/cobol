---
_translated_from: lessons/25_using-parameters/answer.md
_translated_by: site-src/translation agent
---

# Lesson 25 Modification Exercise — Reference Answers

This answer covers only the two modification exercises in [`exercise.md`](./exercise.md); it does not provide an answer to the extension exercise. Start both exercises from the current source, and recompile all three source files with the same command each time:

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

The standard output below is from actual runs (each exercise starts again from the original source, so the two are independent). The `-Wunfinished` warning for `BY VALUE` still appears in both answers; it is unrelated to the program’s business behavior.

## 1. Change the Subprogram Increment to 2

Changes:

- `add_one_25.cob`: `ADD 1 TO AMOUNT-ARGUMENT` → `ADD 2 TO AMOUNT-ARGUMENT`
- `lesson.cob`, in `1100-TEST-REFERENCE`: `MOVE 11 TO WS-EXPECTED` → `MOVE 12 TO WS-EXPECTED`

Standard output (11 lines, exit code `0`):

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000012
呼出側=呼出後 方式=BY REFERENCE 値=000000012 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000022
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=001 BY CONTENT=001 値=001
```

There are only three differences from the original output: in the two `被呼出側=加算後` lines, `011`/`021` become `012`/`022`, and the after-call value in the `BY REFERENCE` section changes from `011` to `012`. The reason is that `ADD-ONE` still receives either the same parameter storage (`BY REFERENCE`) or a temporary copy of it (`BY CONTENT`). Increasing by 2 instead of 1 changes the value seen inside the subprogram in both cases. Only the `BY REFERENCE` call changes the caller’s own storage, so its value goes from 10 to 12; the caller’s value in the `BY CONTENT` section remains 20. The `BY VALUE` section calls another subprogram and is unaffected.

## 2. Change the Second Call to BY REFERENCE

Changes (all in `lesson.cob`, within `1200-TEST-CONTENT`):

- `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` → `CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT`
- `MOVE 20 TO WS-EXPECTED` → `MOVE 21 TO WS-EXPECTED`
- `MOVE "BY CONTENT" TO WS-MODE` → `MOVE "BY REFERENCE" TO WS-MODE`

Standard output (11 lines, exit code `0`):

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY REFERENCE 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY REFERENCE 値=000000021 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=002 BY CONTENT=000 値=001
```

Differences: the label on line 4 becomes `BY REFERENCE`; the caller’s after-call value on line 6 changes from `000000020` to `000000021`; and the summary becomes `方式 BY REFERENCE=002 BY CONTENT=000 値=001`. Once the passing mode changes to `BY REFERENCE`, the subprogram increments the caller’s storage itself, so the caller’s value changes from 20 to 21. The expected value must therefore also change to 21 for the self-check to pass. `WS-MODE` controls which mode’s counter receives this passing result, so all three lines must be updated together.

**What happens if you change only the call mode and leave the expected value and label unchanged (observed):** If you change only the `CALL` to `BY REFERENCE`, leaving `WS-EXPECTED` as `20` and `WS-MODE` as `"BY CONTENT"`, the program prints `呼出側=呼出後 方式=BY CONTENT 値=000000021 確認=失敗`. The summary is `集計 合格=002 不合格=001`, the mode counts are `方式 BY REFERENCE=001 BY CONTENT=000 値=001`, and the exit code is `1`. The failed check is not counted under any mode. Therefore, `BY CONTENT=000` does not mean “there was no `BY CONTENT` call”; it means “no call labeled `BY CONTENT` passed the self-check.”

## Conclusion

The passing mode determines how the subprogram affects caller storage and what value the caller should see after `CALL`. When changing any of these items, update the call mode, expected value, and mode label together. Otherwise, the self-check fails with exit code `1`, and the display and category counts can mislead the reader. The caller-side self-check observes only the caller’s own storage, so it cannot confirm whether the subprogram received the correct argument (see the observed “Topic Boundary” case in the README).
