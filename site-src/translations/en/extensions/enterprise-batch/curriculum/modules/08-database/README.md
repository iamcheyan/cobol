# Module 08: COBOL + Database (practical Embedded SQL)

This module uses a **real Embedded SQL toolchain validated in P1** (GnuCOBOL 3.2 + a pinned GixSQL commit + two local patches + PostgreSQL 17) to execute COBOL cursors, updates, and transactions in a disposable Docker container/network. This is not a mock, and PostgreSQL `psql` export does not replace the COBOL cursors being taught. The business date comes from an argument, not the machine's current date. All data is synthetic; disposable containers are cleaned up on exit, and no host database is referenced.

Lessons: **08.1** Host/Indicator Variables, NULL, SQLCODE/SQLSTATE; **08.2** DECLARE/OPEN/FETCH/CLOSE cursors and distinguishing no data from errors; **08.3** extract a customer snapshot by business date and reconcile it against an upstream file; **08.4** updates, unique constraints, COMMIT/ROLLBACK, connection loss, and transaction retry.

- Design details: [DESIGN.md](DESIGN.md)
- Independent expectations and calculations: [expected/README.md](expected/README.md)
- Student evidence template: [evidence/README.md](evidence/README.md)
- Instructor reference implementation: [instructor/modules/08-database/](../../../instructor/modules/08-database/)

## 1. Business need / learner task

Nightly batch processing must coordinate **between the database and files**: extract a fixed customer view by business date, reconcile it against an upstream customer file, identify matches and differences, then write that day's transactions **idempotently** to the ledger and update balances. On-call developers especially need to avoid treating NULL as a space and charging twice on reruns. Your task is to understand and repair this flow so that rerunning the same business date does not apply charges twice, and to produce reproducible evidence for “no data,” unique-constraint conflicts, connection failures, and an uncertain commit result.

## 2. Inputs, formats, assumptions

- Upstream customer file: `fixtures/customer-upstream-20261009.dat`, fixed-width CUSTOMER v1 **27 bytes** + LF.
- Transaction file: `fixtures/transactions-20261009.dat`, fixed-width TRANSACTION v1 **55 bytes** + LF.
- DB seed: `db/seed.sql` (synthetic customers/accounts); schema: `db/schema.sql`.
- Assumptions: business date `20261009`; text is ASCII; LF is excluded from record width; amounts are integer minor units.
- Frozen contracts: CUSTOMER v1=27B, ACCOUNT v1=47B, TRANSACTION v1=55B.

## 3. Build, run, and reset from a clean checkout

Requires Docker (for isolated ESQL toolchain) and Python 3:

```bash
lab=$(cd curriculum/modules/08-database && pwd)
python3 "$lab/scripts/check.py"          # offline contracts + independent oracle (no Docker)
bash "$lab/scripts/check.sh"             # offline + real DB end-to-end + student starter
```

Run the real experiment separately (artifacts go to a new directory; overwrite is refused):

```bash
bash "$lab/scripts/run.sh" /tmp/m08-out 20261009
(cd /tmp/m08-out && sha256sum -c inputs.sha256 && sha256sum -c manifest.sha256)
```

Build a single ESQL source as an executable (paths containing spaces are supported):

```bash
bash "$lab/scripts/build.sh" /tmp/probe "$lab/system/ESQL-PROBE.COB"
```

Reset: `bash "$lab/scripts/reset.sh" --containers` removes leftover disposable containers/networks;
`PGHOST=... bash "$lab/scripts/reset.sh" --db` replays schema+seed to the running course database.
Each `run.sh` invocation creates uniquely named `m08-*-db` container and `m08-*-net` network, removed on exit (including Ctrl-C); the tool image is retained for reuse. All derived files go under `<OUTPUT>` (including `manifest.sha256`), not the source tree.

## 4. Expected output, RC, counts, amounts, and independent calculation

Normal results from `run.sh 20261009` (the **independent calculations are in [expected/README.md](expected/README.md)** and do not depend on program output):

| Scenario | Expectation | Independent calculation basis |
|---|---|---|
| 08.1/08.2 probes | `PROBE=PASS`, RC0 | Indicator -1 (NULL), empty-string indicator 0, `02000` no data, `23514` real error, `23505` unique constraint |
| 08.3 snapshot vs upstream | RC4, `DIFFS=3` (MATCH2 / FIELD-DIFF1 / DB-ONLY1 / FILE-ONLY1) | Compare seed and upstream file by key |
| 08.3 no-difference upstream | RC0, all MATCH | Upstream and DB snapshot are byte-identical |
| 08.4 rollback mode | RC0, balances unchanged `100,200,300` | Opening balances; transaction rolled back |
| 08.4 first commit | RC0, balances `130,270,300`, 3 ledger rows, 1 commit row | Opening balances + each C/D transaction |
| 08.4 retry | RC0, balances still `130,270,300`, no added ledger/commit rows | Unique keys skipped, idempotent |
| 08.4 duplicate within one run | RC8, 0 ledger rows, balances unchanged | Unique-key conflict + SAVEPOINT rollback |
| Connection failure | RC12, SQLSTATE `08xxx` | Invalid port |

Published artifacts: `snapshot.dat` (27B records), `snapshot-meta.txt` (business date/schema version/layout version/cutoff/count), `snapshot[-nodiff]-reconcile.txt` and `-control.txt`, `apply-*.out`, `db-after-*.txt` (balances/ledger/commit counts read using an **independent psql connection**), `probe.out`, `probe-fail.out`, `p1-patches.sha256`, `manifest.sha256`, `inputs.sha256`.

## 5. What to modify and interfaces to preserve

Learners start from [starter/DBBATCH.COB](starter/DBBATCH.COB) (builds, but is incomplete; returns RC12 and publishes nothing). Preserve the 27B/55B contracts, environment-variable interface (`M08_BIZ_DATE/M08_SNAPSHOT/M08_META/M08_UPSTREAM/M08_DIFF/M08_CONTROL`), RC policy, and unique business key. Existing support programs `system/ESQL-PROBE.COB` (08.1/08.2 probe) and `system/APPLY.COB` (08.4 posting) are included in the student package and selected automatically by `run.sh`. The snapshot program is the learner's deliverable: by default `run.sh` builds the learner's own `starter/DBBATCH.COB` (or an external source selected with `COURSE_SOURCE`); the instructor reference at `instructor/modules/08-database/SNAPSHOT.COB` is not shipped in the student package.

### Student snapshot source entry (`COURSE_SOURCE`)

`run.sh` uses `COURSE_SOURCE=<your snapshot source>` instead of `bin/snapshot` (08.2/08.3); the remaining steps still use instructor references. **The source goes through the same business validation as the instructor reference**; setting `COURSE_SOURCE` does not cause unconditional failure:

- Different upstream data → RC4; identical upstream data → RC0; the 27B snapshot must also be byte-identical to `expected/snapshot-20261009.dat`. Only after all checks pass does execution continue to 08.4 and publish.
- System failure (for example, incomplete `DBBATCH.COB` returning RC12) → RC12, no publication.
- Semantically wrong implementation that returns RC4/RC0 (wrong amount/sign/status, missing or extra rows) → rejected by byte comparison with RC8, no publication.

Regression checks: sections 4–6 of `scripts/check.sh` verify correct reference used as `COURSE_SOURCE` publishes normally, a semantically wrong student source is rejected, and the incomplete starter returns RC12 without publication.

## 6. Deliberate faults and investigation/recovery (at least one reproducible fault per lesson)

| Lesson | Change | Reproducible fault | Investigation and recovery |
|---|---|---|---|
| 08.1 | Remove the indicator from `:HV-NOTE:HV-NOTE-IND` | Fetching NULL yields spaces instead of NULL; NULL and empty string are confused | Use indicator -1 to detect NULL; restore indicator |
| 08.2 | Treat cursor `FETCH` as success without checking `02000` | End of data is treated as an error or rows are missed | After `FETCH`, `IF SQLSTATE='02000'` is normal completion; other states are errors |
| 08.3 | Change one upstream customer's `balance_demo` digit | Snapshot differs from DB: `FIELD-DIFF`, RC4; locate field and offset | Restore upstream or DB seed, rerun for RC0; difference report identifies `19-26` |
| 08.4 | Duplicate a `transaction_id` in the transaction file | Unique key `23505` → in-run duplicate → RC8 rollback | Deduplicate and rerun; historical retry takes the SKIP branch |

Two additional severe faults are measured: **72-column overflow**—placing a multi-column `INSERT` past column 72 causes GixSQL/cobra to truncate identifier `sequence_no`, yielding syntax error `42601`; fix by keeping SQL lines within column 72. **PostgreSQL transaction abort**—after `23505`, another `SELECT` in the same transaction returns `25P02`; recover locally with `SAVEPOINT` + `ROLLBACK TO SAVEPOINT` (see DESIGN.md section 4).

## 7. Plugin operation and terminal alternative

- Fixed-format safety: use the cobol.nvim ruler for Area A/B and the red over-column-72 diagnostic; terminal alternatives: `awk 'length($0)>72{print NR}' <file>.COB`, `:set list`.
- Locate reference paragraphs: `gd`/`:CobolGotoDef` to jump to `1150-ONE`, `1200-DAY-COMMIT`; terminal alternative: `rg -n '1150-ONE|1200-DAY-COMMIT' system/APPLY.COB` (an existing support program in the student package).
- Preview COPY Copybooks: `K`/`:CobolPreview`; terminal alternative: `cat copybooks/CUSTOMER-V1.CPY`.
- Inspect real bytes (LF/width): terminal `od -An -tc fixtures/customer-upstream-20261009.dat`.
- **Plugin estimates are not final evidence for byte layout**; use fixed-width assertions in `check.py` and `od`.

## 8. Evidence to submit and failure criteria

Following [evidence/README.md](evidence/README.md), submit compiler and DB tool versions, image ID, P1 patch SHA256, business date, run_id, commands, **raw RC**, `inputs.sha256`/`manifest.sha256`, raw DB state (balances/ledger/commits), reconciliation table, and limitations. Fail if any assertion disagrees with published artifacts; manifest/input checksums fail; the 27B snapshot differs from the independent oracle; a retry increases balances or ledger rows; an in-run duplicate is not rolled back; the incomplete student source publishes any artifacts; or an unverified platform/recovery boundary is reported as “passed.”
