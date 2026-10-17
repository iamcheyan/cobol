# Boss L3: customer-day aggregation and four-stream merge

This lesson reconciles accepted L2 accounting results with a customer-day snapshot and previous-day controls. A customer may have multiple accounts and transactions. Accounts and transactions each belong to one customer; aggregate account balances/counts and accepted credit/debit amounts/counts by customer. N:N means multiple accounts and transactions share one customer aggregation key; it does **not** create account × transaction pairs or a Cartesian product, and does not copy customer balances to each account.

L2 remains the source of accounting facts. The official runner sends raw ACCOUNT, TRANSACTION, and REVERSAL-LINK through B01 L2 first, retaining accepted/rejected records, the complete closing master, and its report, then runs this lesson's core. L3 does not post transactions again and does not update the database. The Snapshot is offline seed data; real database extraction and updates belong to Module 08.

When accounts are ordered by account_id, customer_id can move backward: account 1 → customer 2, account 2 → customer 1, account 3 → customer 2. Therefore COBOL must first create disk-sorted streams carrying customer_id, then merge four streams: ACCOUNT, accepted TX, Snapshot, Previous. Keep only four cursors, current records, and fixed-precision accumulators. Spool each customer group to disk and decide eligibility or isolation only at group end.

## Fields and policy

Open [DESIGN](DESIGN.md) and [FIELD-CATALOG](FIELD-CATALOG.md), then use `:CobolGotoCopybook` to inspect this lesson's actual `CUSTOMER-SNAPSHOT-V1.CPY` and `PREVIOUS-DAY-V1.CPY`. ACCOUNT v1 is canonical 47B; TRANSACTION v1 is canonical 55B and has no layout-version field; Snapshot v1 is 36B and Previous-Day v1 is 39B. All records must be fixed-width ASCII and LF-terminated. Validate dates against the real Gregorian calendar; Previous means the prior calendar day, not the bank business-day calendar.

For each complete customer group, verify: customer account count equals the previous-day count; current opening total equals previous closing; `expected closing = previous closing + L2 accepted credit - L2 accepted debit`; recalculated closing equals the L2 closing-master aggregate; account count and closing do not exceed snapshot controls. Counts/balances include all account statuses A, F, C. L2 rejected records are retained separately and excluded from accepted amounts.

Missing Snapshot/Previous, customer status D, or business differences in account count/balance return RC4 and write associated accounts/accepted transactions to isolation with original 47B/55B bytes and reasons. Missing rows/orphan Snapshot or Previous rows must also preserve their original 36B/39B source. Structural errors (missing LF, CRLF, bad width/date/version, duplicate or descending keys) return RC8 and are not published. Tool, permission, sort-disk, verification, lock, and publication errors map to RC12 and are not published. RC4 may still publish other passing customers, but downstream processing must exclude isolated files.

Global controls must satisfy: original ACCOUNT count = eligible master count + isolated account count; L2 accepted count = eligible accepted TX count + isolated accepted TX count; accepted credit and debit totals each equal eligible plus isolated amounts; opening + credit − debit = closing. L2 rejected count remains separate.

## Learning path

1. Hand-trace `fixtures/normal`: reading by account yields customer order 2, 1, 2; calculate customer 1 as 2,000−100=1,900 and customer 2 as 4,000+120−20=4,100. Compare `expected/normal-master.dat` and `expected/normal-customer-totals.csv`; from the repository root run `(cd curriculum/modules/07-matching/labs/04-many-to-many && sha256sum -c SHA256SUMS)`.
2. Read `1300-SORT-ACCOUNTS`, `1400-SORT-TRANSACTIONS`, `1500-RUN-FOUR-WAY`, `1550-RESET-GROUP`, `1580-DECIDE-GROUP`, and `1590-REPLAY-SPOOL` in reference `instructor/modules/07/04-many-to-many/BATCHL3.COB`. This table records actual cursors after READ at each program stage: at group start choose the minimum customer key across four streams; read all ACCOUNT rows for that customer through group end, then all accepted TX rows through group end, then read the matching Snapshot and Previous once each, and only then decide/replay the spool. Each cursor shown is the current row after that stage's READ; unchanged streams retain their position. Original ACCOUNT customer sequence is 2,1,2; after sorting by customer/account, account IDs are 2,1,3. Accepted TX customers are `01:T003`, `02:T001,T002,T004`.

| ordinal | Records consumed this stage | A current | T current | S current | P current | Group accumulator or decision |
|---:|---|---|---|---|---|---|
| 0 | Initial READ | 01:A02 | 01:T003 | 01:S01 | 01:P01 | Minimum group key 01 |
| 1 | READ after consuming A02 | 02:A01 | 01:T003 | 01:S01 | 01:P01 | Customer 01: account 2 opening 2000 |
| 2 | READ after consuming T003 | 02:A01 | 02:T001 | 01:S01 | 01:P01 | Customer 01: T003 debit 100 |
| 3 | READ after consuming S01 | 02:A01 | 02:T001 | 02:S02 | 01:P01 | Customer 01 snapshot consumed once |
| 4 | READ after consuming P01; decide 01 | 02:A01 | 02:T001 | 02:S02 | 02:P02 | 2000−100=1900; customer 01 complete |
| 5 | READ after consuming A01 | 02:A03 | 02:T001 | 02:S02 | 02:P02 | Customer 02: account 1 opening 1000 |
| 6 | READ after consuming A03 | EOF | 02:T001 | 02:S02 | 02:P02 | Customer 02: account 3 opening 3000; account stream EOF |
| 7 | READ after consuming T001 | EOF | 02:T002 | 02:S02 | 02:P02 | Customer 02: credit 50 |
| 8 | READ after consuming T002 | EOF | 02:T004 | 02:S02 | 02:P02 | Customer 02: debit 20 |
| 9 | READ after consuming T004 | EOF | EOF | 02:S02 | 02:P02 | Customer 02: credit 70; transaction stream EOF |
| 10 | READ after consuming S02 | EOF | EOF | EOF | 02:P02 | Customer 02 snapshot consumed once |
| 11 | READ after consuming P02; decide 02 | EOF | EOF | EOF | EOF | 4000+credit 120−debit 20=4100; customer 02 complete |

The ACCOUNT and TX loops each consume all rows for the current customer; they do not pair A03 against T001/T002/T004 one by one. Customer 02 has 2 accounts and 3 transactions. Each transaction is assigned to an ACCOUNT first, then contributes via `account.customer_id` exactly once; no amount is duplicated and no Cartesian product is created.
3. Create a separate work copy and run the starter; verify its TODO returns RC12 and publishes nothing. First implement only four-cursor comparison and EOF states, manually tracing every READ; then add customer spool and group-end replay; finally add amount equations, customer-difference isolation, and control conservation. Compare against the reference at each stage; do not hard-code expected results into the student program.
4. In a separate work copy, change account 1's customer_id from 02 to 01 while keeping transactions assigned through their account; update Snapshot/Previous rows and calculate independently. Verify customer 01/02 amounts aggregate once by account, without copying customer balances. Then remove customer 01's Snapshot: customer 01 account/TX sources should be isolated byte-for-byte; customer 02 may still publish; JOB returns RC4.
5. Change a Snapshot date to an old value, remove final LF, or duplicate a snapshot key: expect structural RC8 and no target directory. Use `python3 scripts/check.py` to inspect each permanent case, then `bash scripts/check.sh` for all business/raw-byte/starter/reset/fixture checks.

## Build, run, check, reset

```bash
lab=curriculum/modules/07-matching/labs/04-many-to-many
bash "$lab/scripts/build.sh" /tmp/batchl3
python3 "$lab/scripts/check.py"
bash "$lab/scripts/check.sh"
```

An official run creates a lock and isolated stage, snapshots inputs, runs B01, then this lesson's COBOL. External `sort` only reorders candidate outputs into the downstream account/sequence/id byte order. An independent disk-backed SQLite oracle verifies each stream before publication. Typical teaching commands:

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
work=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$work/"
cd "$work"
bash "$lab/scripts/run.sh" account.dat transaction.dat \
  reversal-link.dat customer-snapshot.dat previous-day.dat \
  output-20261009 20261009
cd - >/dev/null
(cd "$work/output-20261009" && sha256sum -c inputs.sha256 \
  && sha256sum -c manifest.sha256)
```

A normal batch with no differences returns RC0; L2 or customer business isolation returns RC4 with a published directory; structural error RC8 and system error RC12 publish nothing. Official output always goes to a new directory; an existing target is refused. Set `COURSE_SOURCE=/absolute/path/BATCHL3.COB` to select student source; this override applies only to B03, while L2 continues to use its accepted reference implementation.

Use an isolated source for the starter:

```bash
lab=$(cd curriculum/modules/07-matching/labs/04-many-to-many && pwd)
student=$(mktemp -d)
cp "$lab/fixtures/normal/"*.dat "$student/"
cp "$lab/starter/BATCHL3.COB" "$student/BATCHL3.COB"
if COURSE_SOURCE="$student/BATCHL3.COB" bash "$lab/scripts/run.sh" \
  "$student/account.dat" "$student/transaction.dat" \
  "$student/reversal-link.dat" "$student/customer-snapshot.dat" \
  "$student/previous-day.dat" "$student/result" 20261009; then
  starter_rc=0
else
  starter_rc=$?
fi
[[ $starter_rc == 12 && ! -e $student/result ]]
```

It should return 12 and not create `result`. Check again after completing the TODO. `scripts/init-workspace.sh DIR` writes a workspace marker only to an empty directory; `scripts/reset.sh DIR` resets only a marked workspace with no running lock. Any lock causes RC12 and all files are preserved.

## Exercise checks

Try the following and retain the command, raw RC, output manifest, core stdout/stderr, and fixture hash for each:

| Exercise | Expectation | Check |
|---|---|---|
| Snapshot balance limit exactly 4100 | RC0 | Equality with limit is allowed |
| Set limit to 4099 | RC4 | Only customer 02 isolated |
| Remove customer 01 Snapshot | RC4 | Customer 02 eligible; customer 01 source isolated byte-for-byte |
| Change Previous closing to 4001 | RC4 | Opening mismatch; split amounts still conserved |
| Set Snapshot date to old date | RC8 | Whole batch unpublished |
| Duplicate or descend customer_id | RC8 | Do not overwrite old output or publish candidate |

## Fault-investigation order

First inspect the runner's raw RC, then the candidate stage. For RC4, check `customer-status.txt`, `isolation.txt`, and control splits. For RC8, check raw LF/width, dates, versions, and customer-key ordering. For RC12, inspect stderr for build, sort, temp-directory, lock, independent-verification, or publication failure. `run.sh` automatically cleans private stage and lock on failure; no official output directory should exist. After successful publication, use `sha256sum -c inputs.sha256` to prove input snapshot integrity, then `sha256sum -c manifest.sha256` for output files. Hashes establish integrity; business correctness is checked by the independent oracle and control equations.

Terminal alternative to editor plugins: `rg -n '1500-RUN-FOUR-WAY|1580-DECIDE-GROUP|1590-REPLAY-SPOOL' instructor/modules/07/04-many-to-many/BATCHL3.COB`, and `od -An -tc` for actual line endings and bytes. Plugin jumps target only paragraphs and Copybooks that actually exist in this lesson.
