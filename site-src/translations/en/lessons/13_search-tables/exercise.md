---
_translated_from: lessons/13_search-tables/exercise.md
_translated_by: site-src/translation agent
---
# Lesson 13 Exercise: SEARCH and SEARCH ALL

This lesson uses only material covered in Lessons 11–13: `OCCURS` tables, `INDEXED BY` indexes, `SEARCH` / `SEARCH ALL`, `SET`, `MOVE`, and `DISPLAY`.

## Modification Exercises (Reference Answers in `answer.md`)

1. In `1000-LOAD-ACCOUNTS`, change the balance for account `0002468101` from `520.00` to `600.00`. Run both search methods and verify the returned balance.
2. Expand the account table from four entries to five, append account `0009999999` with balance `75.00`, and change the second search target from `0005550000` to `0009999999`. Run both search methods.

Perform each exercise independently from the original `lesson.cob`; do not combine the changes. After each modification, run:

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_13 lesson.cob
./build/lesson_13
```

When expanding the table, do not update only the `OCCURS` upper bound and forget to load the corresponding data. Otherwise, the new account number will be spaces and the search will not find it. The reference answers cover only these modification exercises.

## Apply What You Learned (No Answer Provided)

Build a five-entry product inventory table. Use `SEARCH` to find product codes that are present and absent; then declare a key order and search with `SEARCH ALL`. Ensure that codes are unique and that the runtime order matches `ASCENDING KEY` or `DESCENDING KEY`.

Submit the complete source and actual output for both search types. Explain which part of the code maintains the ordering convention; what risk arises if the table data is reordered without updating the key declaration; and why this lesson’s probe cannot automatically detect that risk. Use in-memory data only; do not add files or a database. No answer is provided.
