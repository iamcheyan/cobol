# 07.1: Sort a transaction stream with COBOL SD/SORT

This lesson turns unordered TRANSACTION v1 input into a strictly ordered stream that L2 can consume directly. COBOL `SORT` does the sorting: the INPUT PROCEDURE reads and validates raw bytes and `RELEASE`s valid 55-byte records; the OUTPUT PROCEDURE `RETURN`s and writes them unchanged. The key is `(account_id, sequence, transaction_id)`, not the whole line, account/ID alone, or input order.

See [DESIGN.md](DESIGN.md) and the shared [field catalog](../common/FIELD-CATALOG.md) for interfaces, RCs, field rules, and work-file budget. The sole record definition is the canonical [TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY). Account and transaction keys are not rewritten; zero amount is structurally valid and is classified downstream by L2; IDs use uppercase A–Z/digits only and status is N only.

## From hand calculation to execution

1. In the [normal input](fixtures/normal/transaction.dat), mark Z…001 (seq1), A…002/M…003 (seq2), A…004 (seq3), then trace account 2's A…006/B…005. First write down the six composite keys independently and compare them with [expected/normal.dat](expected/normal.dat). Z's ID sorts lexically after A but comes first because its sequence is earlier; within the same sequence, A precedes M.
2. Read `LOAD-INPUT`, `CHECK-FIELDS`, and `WRITE-OUTPUT` in `instructor/modules/07/02-sort-merge/SORTTX.COB`. The key appears in `SORT ... ON ASCENDING KEY`; this lesson's source has no separate `CHECK-KEY` paragraph. Trace one record through its full lifetime at `RELEASE`/`RETURN`.
3. At `COPY "TRANSACTION-V1.CPY"`, use `:CobolGotoCopybook` to open the real canonical Copybook. Check the catalog against bytes 35–40 and 11–26. Terminal alternative: `nl -ba instructor/modules/07/02-sort-merge/SORTTX.COB`, `rg -n 'SORT|RELEASE|RETURN|CHECK-FIELDS|TRANSACTION-V1' instructor/modules/07/02-sort-merge/SORTTX.COB`, and `nl -ba curriculum/bank/copybooks/TRANSACTION-V1.CPY`.
4. Draw the state flow: “read raw bytes → assemble 55B → validate fields/date → RELEASE → SORT → RETURN → independent acceptance → publish.” Explain why a bad row discards the candidate and why the runner snapshots input first.
5. Starter `MAIN-PROCEDURE` is a buildable TODO scaffold and has no editable `CHECK-KEY` paragraph. Write pseudocode on paper, then port `SD TX-WORK`, `SORT ... INPUT PROCEDURE`, `RELEASE`, `OUTPUT PROCEDURE`, and `RETURN` from the reference into the starter. Build and run a separate starter target after each section until it no longer returns RC12. To verify your own field logic, copy it to a workspace and explicitly select that source: `cp "$lab/starter/SORTTX.COB" "$work/SORTTX.COB"`; after implementing it, run `COURSE_SOURCE="$work/SORTTX.COB" python3 "$lab/scripts/check-core-raw.py"`. Loosen ID validation to accept lowercase in that copy; the same check should fail. Restore ASCII A–Z/0–9 validation. Finally run this lesson's `check.sh` and record work-file evidence from a large input.

An external sort is only a comparison for the key rules:

```bash
LC_ALL=C sort -k1.1,1.10 -k1.35,1.40 -k1.11,1.26 fixtures/normal/transaction.dat
```

The keys correspond to bytes 1–10, 35–40, 11–26. This cannot replace COBOL SD/SORT in the lesson. The external sort inside `check.py` is only for disk-backed global-ID uniqueness and a byte-multiset oracle.

## Starter, build, run, check, reset

```bash
lab=$PWD/curriculum/modules/07-matching/labs/02-sort-merge/01-sort
work=$(mktemp -d)
bash "$lab/scripts/init-workspace.sh" "$work"
cd "$work"
# default builds the instructor reference
bash "$lab/scripts/build.sh" "$work/sorttx"
bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/transaction.dat" "$work/sorted.dat"
cd "$lab/.."
sha256sum -c SHA256SUMS
bash "$lab/scripts/check.sh"
```

To practice the starter, remove the target program in the work directory, then explicitly select the starter:

```bash
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/build.sh" "$work/sorttx"
COURSE_SOURCE="$lab/starter/SORTTX.COB" \
  bash "$lab/scripts/run.sh" "$lab/fixtures/normal/transaction.dat" \
  "$work/starter-output.dat"  # separate new path confirms starter ran and returned 12
```

The starter is a buildable TODO scaffold; it returns RC12 and does not publish. The distinct `starter-output.dat` avoids a no-clobber result caused by output left by the reference. The default reference is in a separate instructor directory. Complete the starter incrementally before acceptance. `check.sh` checks reference behavior for normal, empty stream, one row, valid leap day, zero amount, all structural errors, direct-core raw-byte rejection, normal/zero-amount L2 bridges, and fail-closed behavior. `reset.sh "$work"` only cleans `sorttx` and `sorted.dat` in a marked workspace with no output lock; any lock makes reset return RC12 and preserve all files so a running job is not interrupted.

JOB settings: `B02_DATE` defaults to `20261009`; `COB_SORT_MEMORY` defaults to `2M` (GnuCOBOL requires more than 1M); `TMPDIR` selects the core SORT work-file directory. Input snapshots preserve the original; candidate output is checked for bytes, width, order, and multiset, then published via a no-clobber link. RC0 success, RC8 input-contract error, RC12 system/sort-resource/build/verification/publication failure; failed candidates are not published. L2 handles business zero amount as RC4 with a published classification result.

## Plugin and terminal paths

Optional Neovim: at `COPY "TRANSACTION-V1.CPY"` in the reference source, run `:CobolGotoCopybook`; use `:CobolGotoDef` in `SORTTX` to jump to `LOAD-INPUT` and `WRITE-OUTPUT`; inspect `TRANSACTION-RECORD` under SD with `:CobolCalcRecord` to estimate 55 bytes. Plugin navigation only helps read source; shell checks provide runtime and byte evidence. The terminal route uses `rg -n 'LOAD-INPUT|CHECK-FIELDS|SORT|RELEASE|RETURN'`, `nl -ba`, and `od -An -tc`.

## Evidence

Record actual results in [evidence/TEMPLATE.md](evidence/TEMPLATE.md). In-lesson expected outputs are static hand-calculated byte files; pressure, spill observations, and resource failures are in shared [B02 evidence](../evidence/B02-pressure-2026-10-10.json).
