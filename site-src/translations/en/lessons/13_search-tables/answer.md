---
_translated_from: lessons/13_search-tables/answer.md
_translated_by: site-src/translation agent
---
# Lesson 13 Modification Exercises: Reference Answers

This answer covers only the two modification exercises in `exercise.md`; it does not provide an answer to Apply What You Learned. Start each exercise independently from the original `lesson.cob`. Compile and run with:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_13 lesson.cob
./build/lesson_13
```

## Change the Balance of an Existing Account

Change the statement in `1000-LOAD-ACCOUNTS` to:

```cobol
           MOVE 600.00 TO WS-ACCOUNT-BALANCE(3)
```

Both search methods find the same account and return the updated balance:

```text
逐次検索=検出 口座=0002468101  残高=0000600.00
二分検索=検出 口座=0002468101  残高=0000600.00
```

## Append the Highest Account Number

Change the OCCURS upper bound to 5:

```cobol
          05 WS-ACCOUNT-ENTRY OCCURS 5 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
```

Append a unique record with a key greater than all existing keys after the fourth entry:

```cobol
           MOVE "0009999999" TO WS-ACCOUNT-NUMBER(5)
           MOVE 75.00 TO WS-ACCOUNT-BALANCE(5).
```

Update the second search target to `0009999999`. The fifth entry still satisfies ascending order and key uniqueness. Both search methods should output:

```text
逐次検索=検出 口座=0009999999  残高=0000075.00
二分検索=検出 口座=0009999999  残高=0000075.00
```

If the `ASCENDING KEY` declaration changes but the actual table data is not kept in the corresponding order, `SEARCH ALL` results are unreliable; the declaration does not sort the table.
