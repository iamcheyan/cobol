# 07.4 / Boss L2: 1:N account posting with bounded state

Recommended: 4 hours. Prerequisites: 07.3 L1, file status, and decimal amounts. Business task: an account has zero or more sorted transactions per day; update the balance one transaction at a time, explain rejections, and support reversals that reference original transactions. On completion, explain Key Break finalization, why transaction IDs need global deduplication, and why the 55-byte v1 record cannot identify an original transaction for reversal.

## Run

Requires Linux x86-64, GnuCOBOL 3.2 (BDB indexed-file support), Bash, GNU coreutils, Python 3 (acceptance driver only), and `sort`. macOS/WSL are unverified. Run all files into a new output directory; inputs and existing outputs are not overwritten. The instructor reference is under `instructor/`; the starter builds but returns 12.

```bash
lab=curriculum/modules/07-matching/labs/03-one-to-many
set +e
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/account.dat" \
  "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-run 20261009
rc=$?
set -e
test "$rc" -eq 4   # this case has a business rejection; RC4 still publishes reconciled results
diff -u "$lab/expected/normal.txt" /tmp/bank-l2-run/report.txt
python3 "$lab/scripts/check.py"
python3 "$lab/scripts/check-indexed.py"
```

Amount outputs use fixed-width signed integers. RC4 means per-transaction business rejections; checked output is still published. RC8 is an interface/order/global-uniqueness error; RC12 is a system failure. Neither creates an output directory. A cross-account reversal target is a business rejection RC4 with a published reason; an association whose account/sequence does not match the referenced transaction is a structural RC8 error and the whole batch is not published.

The published directory contains `report.txt`, full 47-byte closing `master.dat`, original accepted transactions in `accepted.dat`, rejected original transactions with reasons in `rejected.dat`, input/output SHA256 manifests, and a source-version summary. Viewing stdout alone does not replace the official published directory.

On this machine, GnuCOBOL BDB can write buffered LINE SEQUENTIAL output to `/dev/full` while WRITE/CLOSE status remains 00 and the program returns business RC4. Therefore the reference core may only be run through `run.sh` as the JOB entry point: it stream-checks the report, original input rows, all three outputs, and per-account/global amount controls. Any missing row, truncation, CRLF, or conservation mismatch is mapped to RC12 and not published. Running the compiled core directly does not provide publication guarantees.

## Learning path and runnable tasks

Follow this order; predict each stage first, then verify with commands:

1. **Manual trace**: read the `DESIGN.md` example and calculate every closing balance for normal; mark T03's reference to T01 and explain why T02 does not prevent the lookup. Use `awk '{print NR, length($0)}'` for row widths and `od -An -tc` to confirm LF.
2. **EOF and Key Break**: find the dual-pointer `EVALUATE` in `1000-MAIN` and `4000-CLOSE-ACCOUNT`. Draw pointer states when transactions end first, an account has no transactions, and the final account ends. Explain why closing output can only be emitted after consuming the account's transaction group; compare expected outputs for `boundary-no-transactions` and `boundary-empty-all`.
3. **Ledger state**: inspect preload in `1700-INDEX-TRANSACTIONS` and random `READ`/`REWRITE` in `6000-POST-TX`. Run `check-indexed.py` to observe writes/reads, duplicate key 22, missing key 23, and open failures. Explain why the ledger stores original transaction acceptance/reversal state, not per-account group balances.
4. **Conservation**: independently calculate each account's `opening + credits - debits = closing` and global control for normal. Inspect `boundary-aggregate-over-13`: each account amount is valid, but the global total exceeds 13 digits. Expectations must be derived from fixtures, not copied from program output.
5. **Fault investigation**: first copy fixtures to a temporary directory. A zero-amount mutation should return RC4 and emit a rejection reason; changing the REVERSAL-LINK account should return RC8 without publication. Compare `run.txt`, `inputs.sha256`, and `source.sha256` to verify run snapshot and source evidence.

`COURSE_SOURCE` can connect the buildable starter to the same runner. The starter should return RC12 and publish nothing:

```bash
starter=$(realpath "$lab/starter/BATCHL2.COB")
set +e
COURSE_SOURCE="$starter" bash "$lab/scripts/run.sh" \
  "$lab/fixtures/normal/account.dat" "$lab/fixtures/normal/transaction.dat" \
  "$lab/fixtures/normal/reversal-link.dat" /tmp/bank-l2-starter 20261009
rc=$?
set -e
test "$rc" -eq 12 && test ! -e /tmp/bank-l2-starter
```

## Build, check, reset

```bash
bash "$lab/scripts/build.sh" /tmp/batchl2  # compile exercise; official run still publishes via run.sh
bash "$lab/scripts/check.sh"
bash "$lab/scripts/reset.sh" /tmp/bank-l2-run
```

`reset.sh` only accepts a non-symlink directory marked by this course's `run.txt`, `inputs.sha256`, `outputs.sha256`, and `report.txt`; repository paths and unmarked directories are rejected. For manual exercises, copy fixtures and leave originals unchanged. Tests automatically clean intermediate files.

## Business interface and exercises

ACCOUNT remains 47 bytes and TRANSACTION 55 bytes; full policy and hand calculations are in [DESIGN](DESIGN.md). Reversal uses a separate 48-byte REVERSAL-LINK v1 with account, sequence, reversal ID, and original transaction ID. This association file does not change the public transaction v1. When reading the source, follow the two sequential pointers and account Key Break first, then inspect READ KEY/REWRITE in the temporary INDEXED ledger. The ledger supports cross-transaction ID references; core balance processing remains sequential and one transaction at a time.

Plugin path: use `:CobolGotoDef` for read paragraphs; put the cursor on `COPY "ACCOUNT-V1.CPY"` or `COPY "TRANSACTION-V1.CPY"` in the reference source and run `:CobolGotoCopybook` to inspect canonical interfaces. Terminal alternative: `rg -n 'KEY BREAK|READ|REWRITE|OVERDRAFT|PERFORM'` and `od -An -tc`. Exercise: add a zero-amount rejection assertion; then change a reversal reference to an existing original transaction on another account, expecting RC4 and a published `CROSS-ACCOUNT` reason; separately alter the association row's account, expecting RC8 and no publication. Explain how rejected transactions preserve closing balances and conservation.

Submit source, normal transaction-by-transaction balance table, at least one failure RC/no-publication example, input SHA256, and count/amount conservation evidence. Instructor root causes, hints, and reference source are in `instructor/modules/07/03-one-to-many/`.
