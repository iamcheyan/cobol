---
_translated_from: lessons/26_error-handling/answer.md
_translated_by: site-src/translation agent
---

# Lesson 26 Modification Exercise: Reference Answer

This answer covers only the **modification exercise** in `exercise.md` (correcting the amount for `A00002`); it does not answer the transfer exercise. All figures come from an actual run with GnuCOBOL 3.2.0/Linux in this workspace.

## Correct the Amount Field for A00002

**Baseline:** `build/transactions.txt`, a copy of the original `transactions.txt` fixture (5 lines, 62 bytes).

**Change:** change only line 2 from `A00002|00X50` to `A00002|00150`; the line remains 12 bytes, and the other four lines are unchanged.

```sh
(cd build && ./lesson_26); echo "rc=$?"
```

**Process return code:** `0`.

**Standard output (observed, 7 lines):**

```text
受理口座=A00001
受理口座=A00002
拒否口座=A00003 REASON=ZERO_AMOUNT
受理口座=A00004
拒否口座=A00005 REASON=BAD_WIDTH
集計 入力=005 受理=003 拒否=002
システムエラー=N
```

Compared with the baseline, line 2 changes from `拒否口座=A00002 REASON=BAD_AMOUNT` to `受理口座=A00002`; all other lines and record order are unchanged. The summary changes from `受理=002 拒否=003` to `受理=003 拒否=002`. `システムエラー` remains `N`.

**`build/accepted.txt` (3 lines, 13 bytes per line = 39 bytes):**

```text
A00001|00125
A00002|00150
A00004|00999
```

`A00002|00150` appears on **line 2**: records are written in input order, with `A00001` first and `A00004` after it; `A00002` is the second fixture record and is accepted this time.

**`build/rejected.txt` (2 lines: 19 + 17 = 36 bytes):**

```text
A00003|ZERO_AMOUNT
A00005|BAD_WIDTH
```

The baseline’s `A00002|BAD_AMOUNT` line is gone. Only the zero-amount and short-record rejections remain.

**Reasoning and checks:**

- `00150` is a 5-digit, nonzero numeric amount. It passes the width (12 bytes), delimiter (column 7 is `|`), and amount checks in order, so it is no longer a `BAD_AMOUNT` rejection and is written to the accepted file.
- The rejection count falls from 3 to 2, but the return code stays 0: business rejection determines only the record’s destination and **does not change the batch return code**. Every file operation has status `00`, so `WS-SYSTEM-ERROR` remains `N` and `RETURN-CODE` remains 0.
- Check the invariant: `input 005 = accepted 003 + rejected 002`; `accepted.txt` has 3 lines and `rejected.txt` has 2, matching both counts. Every record has exactly one destination.
