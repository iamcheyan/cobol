# 07.3 / Boss L1: 1:1 reconciliation of two sorted streams

Recommended: 2 hours. Prerequisites: read SELECT/FD/FILE STATUS, PERFORM, EVALUATE, and understand fixed-width file bytes. If needed, read the [data contract](../../../../../docs/curriculum/BANK-SYSTEM.md), then do the [byte-layout lab](../../../../validation/layout/README.md).

## Business task

Nightly processing receives an account Master and a transaction file. The upstream contract for this exercise allows at most one transaction per account. Classify: present in both, account only, or transaction only. An orphan transaction may mean its upstream account has not arrived yet; it must not be silently dropped. This lesson only classifies; it **does not update balances or post charges**. L2 defines account status, credits/debits, and amount policy.

Do not put all files in arrays or rescan Master for each transaction. Read each file forward only; workspace holds the current record, previous key, and a fixed number of counters.

## Run from a clean checkout

The verified Linux environment needs GnuCOBOL 3.2, Bash, GNU coreutils (including realpath and sha256sum), Make/Git; acceptance also needs Python 3. Plugins and a database are not required. macOS/WSL are unverified.

Run the reference program from the repository root:

```bash
lab=curriculum/modules/07-matching/labs/01-one-to-one
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" /tmp/bank-l1-first 20261009
cat /tmp/bank-l1-first/report.txt
diff -u "$lab/expected/normal.txt" /tmp/bank-l1-first/report.txt
(cd /tmp/bank-l1-first && sha256sum -c inputs.sha256)
python3 "$lab/scripts/check.py"
```

Use a new output directory each time. If `/tmp/bank-l1-first` exists, the script returns 12 and preserves the old result. On reset, delete only a run directory you created; tests use and clean their own temporary directories. The script works from any starting directory and accepts paths with spaces.

`run.sh` uses the separate instructor reference by default so you can first observe business results. To practice, copy the starter to your own directory and use the same runner/check with `COURSE_SOURCE`:

```bash
cp "$lab/starter/MATCH.COB" /tmp/MY-MATCH.COB
export COURSE_SOURCE=/tmp/MY-MATCH.COB
python3 "$lab/scripts/check.py"  # starter should fail; your completed version should pass
```

The starter builds but deliberately returns 12; it does not pretend to be complete. All reference answers are under `instructor/`; do not read them before self-testing.

## Input and output

Each account record is 47 bytes, each transaction 55 bytes, and every record must be followed by LF; LF is not part of the width. Business date is `20261009`. Receive Copybook numeric fields as PIC X first and test IS NUMERIC before conversion; invalid data must never enter arithmetic.

See [DESIGN.md](DESIGN.md) for field details. Empty files, zero amounts, and key `0000000000` are allowed. Accounts are strictly ascending; transaction account keys are strictly ascending for this 1:1 lesson. Transaction ID is 16 uppercase ASCII letters/digits and globally unique. Blank lines, CRLF, NUL, short/long rows, missing final LF, descending order, duplicate keys, old business dates, and unknown versions all return 8.

`report.txt` lists `MATCH|account_id`, `MASTER-ONLY|account_id`, and `TX-ONLY|account_id` in key order. The final row has five counts in order: account reads, transaction reads, MATCH, MASTER ONLY, TX ONLY; each is zero-padded to 12 digits.

Manual calculation for the normal fixture: account keys 1/3/5/8; transaction keys 1/2/5/7. Common keys are 1/5; account orphans are 3/8; transaction orphans are 2/7. Therefore `4=2+2` and `4=2+2`. Expected files are written from this set relationship, not copied from program output. Amounts are unchanged, and original input snapshots are retained with the results for tracing.

## Implement step by step

1. Draw two read pointers and manually trace each comparison in the normal fixture.
2. Define two independent EOF flags. An all-zero or all-nine real key cannot stand in for EOF.
3. Implement read-master/read-transaction separately. Preserve raw length; validate fields and ordering before handing records to the compare loop.
4. Each comparison advances only the stream consumed; equality advances both. At EOF, drain the other side.
5. Emit the three detail categories, check count equations, check CLOSE status, and return 0 on success.
6. Run acceptance, then deliberately reverse a comparison branch to confirm the tests catch it.

## Change and fault exercises

- Add account keys `0000000000` and `9999999999` at the beginning and end to prove EOF is not a sentinel key.
- Change the final transaction to reference a nonexistent account; submit a new manual trace and expected result.
- Substitute files from `fixtures/invalid/` for corresponding inputs. Expect RC8 and no new output directory; a missing file should return RC12.
- Keep a same-name `.lock` during a run and observe RC12. The lock belongs to the active attempt; never remove another process's lock automatically. After an abnormal exit, first confirm no process is running, then manually clear a stale lock.
- Why can a 1:N case not simply reuse this lesson? Explain the strict ascending restriction and the Key Break state needed by L2.

## Plugin and terminal investigation

In `MATCH.COB`, use `:CobolGotoDef` to follow PERFORM, `:CobolGotoCopybook` to inspect COPY, and `:CobolCalcRecord` to estimate 47/55 bytes; do not substitute estimates for measurement. The same investigation can use `rg -n 'PERFORM|READ|EOF|COPY'`, `nl -ba`, and `od -An -tx1`.

## Deliverables and pass criteria

Submit source, state-transition table, normal/fault commands and RCs, original input SHA256, report, and both count-conservation equations. Record them using [evidence/README.md](evidence/README.md). Passing automated acceptance does not replace explaining “why only one side advances at this step.” Memory-growth checks are in [pressure.py](scripts/pressure.py); runner and data-generator processes are excluded from COBOL matcher RSS.
