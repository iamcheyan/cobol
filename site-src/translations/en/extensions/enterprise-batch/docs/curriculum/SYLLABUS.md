# Enterprise COBOL Batch Curriculum Syllabus


## Modules and Lessons

### 01 COBOL and Legacy Systems (3 hours)

- 01.1 Business dates, online and overnight Batch, differences between programs and JOBs; draw an initial system diagram.
- 01.2 GNUCOBOL compilation, linking, runtime, build directory; compile the same banking program and locate a build failure.
- 01.3 DIVISION/SECTION/Paragraph, periods and scope; compare fixed/free format.
- Outcomes: environment evidence, minimal banking batch entry point, and a diagram relating source to executable.
- Acceptance: reproduce from a clean directory; identify inputs, outputs, and actual entry point; explain column truncation errors.

### 02 Data Definitions and Customer Record (4 hours)

- 02.1 PIC X/A/9, 01/05/77/78/88, VALUE, group items, and elementary items.
- 02.2 S/V, amount ranges, implied decimals, MOVE category conversion, truncation, and padding.
- 02.3 Customer Record v1: ID, name, category, status; create a field catalog.
- Outcomes: customer Copybook, field contract, and MOVE experiment table.
- Acceptance: explain the difference between digits, bytes, and numeric range; explain actual experiment results for negative numbers and MOVE to X.

### 03 Low-Level Data Representation (5 hours)

- 03.1 DISPLAY, SIGN/SEPARATE, COMP/BINARY/COMP-5, COMP-3; distinguish declarations from the ABI.
- 03.2 Write the same amount as raw bytes and compare sign, implied decimal, byte order, and length using Hex Dump.
- 03.3 Experiments parsing invalid Packed Decimal and misaligned/wrong-length amounts.
- Outcomes: amount representation lab pack, byte interpretation table, parser, and bad-data detection strategy.
- Acceptance: explain the 13 digit positions and common 7-byte storage of S9(11)V99 COMP-3; actual results depend on the locked environment; do not mistake raw file bytes for strings.

### 04 Complex Data Structures (5 hours)

- 04.1 REDEFINES, 66 RENAMES, OCCURS, INDEXED BY, OCCURS DEPENDING ON.
- 04.2 Copybook/COPY REPLACING, REFERENCE MODIFICATION, layout versions, and offsets.
- 04.3 Read an extended business record: customer, account, address, risk, limits, contact, and audit fields.
- Outcomes: record with 150+ named fields, layout catalog, and field-location exercises.
- Acceptance: catalog length matches compiler-measured length; identify which later fields move when one field changes.

### 05 Program Control and Data Cleansing (4 hours)

- 05.1 IF/EVALUATE, PERFORM paragraphs/inline/UNTIL/VARYING, scope, and falling through into subsequent paragraphs.
- 05.2 SEARCH/SEARCH ALL sorting prerequisites; STRING/UNSTRING/INSPECT, INITIALIZE.
- 05.3 Standardize customer status, validate required fields and amount ranges, classify rejection reasons.
- Outcomes: reusable validation logic, rejection-code catalog, and normal/invalid cleansing results.
- Acceptance: distinguish business rejection from system failure; provide a minimal fixture for each rejection code.

### 06 File Processing (6 hours)

- 06.1 SELECT/FD/SD, OPEN/READ/WRITE/CLOSE, FILE STATUS, EOF.
- 06.2 Differences between fixed-byte records and LINE SEQUENTIAL; newline is not included in logical record width; detect length anomalies.
- 06.3 Missing/empty files, short lines, long lines, invalid numbers, duplicate IDs, unknown status, and input control totals.
- 06.4 Relative/indexed files, REWRITE/DELETE, locked reading exercises, and applicability boundaries.
- Outcomes: validation and conversion program, valid/rejected output, and file status log.
- Acceptance: input = accepted + rejected; whether empty files are allowed is determined by contract; failures publish no formal artifacts.

### 07 Enterprise Batch Core Algorithms (12 hours)

- 07.1 SORT work files, SD, INPUT/OUTPUT PROCEDURE; sort validation and temporary-space failure.
- 07.2 MERGE ordered streams; contract for sort key, order within the same key, and duplicate keys.
- 07.3 Boss L1: 1:1 Master/Transaction sequential matching, three output classes, and EOF combinations on both sides.
- 07.4 Boss L2: 1:N, Key Break by account, accumulate in transaction order, handle refunds/reversals and balance overflow.
- 07.5 Boss L3: Master, Transaction, DB Snapshot, Previous Day streams; define business N:N rather than assuming a Cartesian product.
- 07.6 Boss L4: compare each of 150+ fields and output field name, offset, old/new values, and comparison rule.
- Outcomes: matching design, state transition table, implementation, classification files, difference report, and conservation evidence.
- Acceptance: do not replace matching with DB/Python/whole-file arrays; memory remains bounded as data grows; cover duplicate keys, reverse order, empty files, EOF, and overflow.

### 08 COBOL + DB (6 hours)

- 08.1 Embedded SQL toolchain validated through P1, Host/Indicator Variable, NULL, SQLCODE/SQLSTATE.
- 08.2 DECLARE/OPEN/FETCH/CLOSE Cursor; distinguish no data from an error.
- 08.3 Extract a customer snapshot by business date, match against upstream files, and output differences.
- 08.4 Updates, unique constraints, COMMIT/ROLLBACK, connection interruption, and transaction retries.
- Outcomes: DB initialization/seed data, cursor extraction, update Batch, and transaction evidence.
- Acceptance: real DB exercise; repeated business dates do not update twice; recovery plan for a crash after commit; DB-specific errors are clearly labeled.

### 09 Modular Programs (4 hours)

- 09.1 CALL/LINKAGE/USING, BY REFERENCE/CONTENT/VALUE, RETURNING, GOBACK.
- 09.2 Working storage lifecycle, common Copybook, parameter length/version, and interface mismatch.
- 09.3 Extract amount calculation, customer validation, and logging modules; joint impact investigation by caller and callee.
- Outcomes: interface specification, shared modules, and call exercises.
- Acceptance: correct results across repeated calls; no implicit shared state; caller accurately propagates failure status.

### 10 Shell / JCL / Scheduler (9 hours)

- 10.1 Bash parameters, environment variables, configuration precedence, business date, paths, and temporary directories; POSIX sh differences.
- 10.2 RC=0/4/8/12, pipefail, JOB dependencies, and Warning pass-through policy.
- 10.3 Locks, input snapshots, checksums, logs, atomic publication, Manifest.
- 10.4 Full rerun, phase recovery, publication failure after DB commit, duplicate transactions, and idempotency.
- 10.5 Read JCL/JP1 examples and map them to a local JOB Flow; do not claim unverified platforms are runnable.
- Outcomes: complete overnight JOB, dependency table, recovery checklist, and runbook.
- Acceptance: downstream steps do not run after prerequisite failure; concurrent start is rejected; same-business-date rerun does not debit twice; all four crash boundaries are recoverable.

### 11 Incident Investigation and Maintenance (9 hours)

- 11.1 Build a timeline from Scheduler state, JOB Log, RC, and input inventory; preserve original evidence.
- 11.2 Invalid numbers, record misalignment, and runtime exceptions: reproduce first, then identify the root cause.
- 11.3 DB unique constraint, zero-byte file, reverse-ordered Master, temporary-space/permission failure.
- 11.4 RC=0 with incorrect balance or control totals; investigate business correctness.
- 11.5 Expand customer category from 1 digit to 2: submit impact investigation before changes.
- Outcomes: impact investigation, change target list, change strategy, Test Cases, Evidence, and incident postmortem.
- Acceptance: root cause is supported by source/data/log evidence; fixes do not hide the issue by changing original input; explain rollback and rerun boundaries.

### 12 Integrated Project and Graduation Acceptance (9 hours)

- 12.1 Receive a banking system and design documents in an unfamiliar version; reconstruct architecture and dependencies.
- 12.2 Complete customer category expansion and handle normal, exceptional, and rerun days.
- 12.3 Run the full overnight flow: intake → validation → sorting → matching → update → reporting → publication.
- 12.4 Investigate a hidden-root-cause incident scene and submit evidence and recovery actions.
- Outcomes: complete system, design and operations documentation, maintenance change package, test and incident evidence.
- Acceptance: meet the hard gates in the production standards; explain why upstream/downstream systems were not broken.

## Plugin Exercises Throughout the Course

Use the fixed-format ruler and diagnostics in 01/06; field navigation, Copybook preview, and record layout estimates in 02–04; outline and paragraph navigation in 07 to trace both read pointers; review call interfaces in 09; and use navigation for impact investigation in 11/12. Every task has a terminal alternative; missing plugins must not block the course.

## Learning Checkpoints

Data representation review in module 03; file contract review in module 06; first Boss in module 07; JOB operations review in module 10; maintenance process review in module 11; graduation in module 12. If a prerequisite checkpoint is not passed, complete the relevant exercise first; memorizing syntax cannot substitute for business evidence.
