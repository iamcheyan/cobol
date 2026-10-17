---
_translated_from: lessons/09_group-items/answer.md
_translated_by: site-src/translation agent
---
# Lesson 09 Modification Exercise: Reference Answer

Change the initial value of `WS-ACCOUNT-NUMBER` to `VALUE "0007654321".` and recompile and run:

```sh
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

Only 3 output lines change; the exit code is `0`:

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

The account number occupies bytes 21–30 of the 58-byte record (after `8+12` bytes). Replacing those 10 characters leaves the width and declaration order unchanged, so both group outputs change in the same way while remaining 58 bytes long.
