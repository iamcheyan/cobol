---
_translated_from: lessons/28_modular-batch-project/exercise.md
_translated_by: site-src/translation agent
---

# Lesson 28 Exercise: Module Interfaces and Reproducible Builds

This exercise uses only topics from Lessons 23–28: Copybooks, `CALL ... USING BY REFERENCE`, `LINKAGE SECTION`, paragraphs, `EVALUATE`/`IF`, `STRING`, and batch build scripts.

## Modification Exercises (Answers in `answer.md`)

Start both changes from the original source. After each change, rerun `./build.sh run`; the script recompiles both subprograms and relinks the main program so that the change takes effect:

```sh
./build.sh check      # 组合语法检查
./build.sh run        # 重新编译、链接并在 build/ 里运行
echo $?               # 退出码
./build.sh clean      # 清理 build/
```

1. Change `2000.00` in `1300-POST-OVERDRAFT` to `1000.00`. Confirm that the withdrawal changes from rejected to successful, the final balance and `記帳`/`拒否` counts change accordingly, and check the status of the third transaction event in `build/batch.log`.
2. Restore the original source, then change the type in `1400-POST-UNKNOWN-TYPE` from `"X"` to `"D"`. Confirm that the posting module returns `POSTED`, the account report reflects the deposit, and the log still uses transaction number `004`.

**Correctness criteria:** For each change, check standard output, `build/batch.log`, and the count invariant (`記帳 + 拒否 = 5`). Changing only the test fixture or rerunning without relinking does not count as completion. For both exercises, explain the control flow: where the `CALL` occurs, where `GOBACK` returns control, and which side increments the count.

See `answer.md` for the reference answer.

## Transfer Exercise (No Answer)

Change the sample transactions to file input, and move “read / EOF / bad-record classification” into a separate module. Keep the account, transaction, and status Copybooks as the only interface definitions. Explain how to ensure every affected module is recompiled and linked after a Copybook change.

Submit the source, `build.sh` commands, actual standard output, and `batch.log`. Explain which module owns the counts and which module is read-only. Do not disguise a business rejection as a compile failure or redefine record layouts already declared in Copybooks. No answer is provided.
