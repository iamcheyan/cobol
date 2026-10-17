# Expected results: independent calculations

The expectations here were **not** copied from current program output. They are derived independently from the business contract, seed SQL, and fixtures, then checked by the program (see the authoring standard, section 4). The executable oracle in `scripts/check.py` recomputes the expectations below from `db/seed.sql` and `fixtures/`; any mismatch fails validation.

## Snapshot (08.3)

For business date `20261009`, the database customers in `db/seed.sql` are C1/C2/C3/C5. In ascending `customer_id` order, assemble CUSTOMER v1 27B (`id(8)+name(10)+balance(8)+status(1)`) into `snapshot-20261009.dat` (4 × 27B + LF = 112B). C4 belongs to business date `20261010` and is correctly filtered by the cursor.

## Reconciliation (08.3)

Upstream `fixtures/customer-upstream-20261009.dat` contains C1/C2/C3/C9. C2's balance is 260 (250 in the DB), and C9 exists only in the file. C5 exists only in the DB. Comparing by key gives:

| Key | Result |
|---|---|
| 00000001 | MATCH |
| 00000002 | FIELD-DIFF `balance_demo` at positions 19-26, DB=00000250, upstream=00000260 |
| 00000003 | MATCH |
| 00000005 | DB-ONLY |
| 00000009 | FILE-ONLY |

`snapshot-control.txt`: `DATABASE-ROWS=4 FILE-ROWS=4 MATCH=2 FIELD-DIFF=1 DB-ONLY=1
FILE-ONLY=1 DIFFS=3` → RC4. The no-difference upstream `…-nodiff.dat` is byte-identical to the DB snapshot: all MATCH, `DIFFS=0` → RC0.

## Apply and idempotency (08.4)

Opening balances (`db/seed.sql`): A1=100, A2=200, A3=300. Transactions in
`fixtures/transactions-20261009.dat`: A1 +50, A1 −20, A2 +70.

- First commit: A1=100+50−20=**130**, A2=200+70=**270**, A3=**300**; 3 ledger rows, 1 commit row → `db-after-first.txt`.
- Retry (same business date, new run_id): all unique keys already exist → all SKIP; the values above remain unchanged → `db-after-retry.txt`. `apply-retry.out` contains `ALREADY-APPLIED=` and `DAY-ALREADY-COMMITTED=YES`.
- Rollback mode: no commit → balances `100,200,300`, 0 ledger rows → `db-after-rollback.txt`.
- In-run duplicate `fixtures/transactions-dup-in-run.dat` (T…001 copied): `23505` → duplicate within this run → RC8 and full rollback → `db-after-dup.txt` (balances `100,200,300`, 0 ledger rows, 0 commits).

`db-after-*.txt` is read through an **independent psql connection** (`docker exec … psql`), not printed by COBOL. This can detect an incorrect balance even when the program returns RC0.

## Metadata keys

`snapshot-meta.keys.txt` lists the required keys. `CUTOFF` comes from the DB clock, so only its presence and format are checked; it is not compared byte for byte.
