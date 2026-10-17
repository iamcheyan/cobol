# Enterprise Legacy Batch COBOL Curriculum

This extension follows the [12-module/76-hour design](../docs/curriculum/README.md) and consistently uses a synthetic bank overnight-processing scenario. Modules 01–12 include instructional units, real data, runnable reference implementations, starters, independent expected results, fault exercises, and evidence templates. Module status distinguishes self-testing by the execution agent from independent acceptance by the primary agent. For the older foundational curriculum, see [`legacy-workshop/`](../../legacy-workshop/README.md).

## Modules and Acceptance Entry Points

| Module | Contents | Quick check entry point | Status |
|---|---|---|---|
| [01-foundations](modules/01-foundations/README.md) | Legacy/business date/JOB, compile and link, fixed/free format, and column truncation | `bash modules/01-foundations/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [02-data](modules/02-data/README.md) | PIC/hierarchy/VALUE, MOVE truncation and padding, CUSTOMER v1 27B field catalog | `bash modules/02-data/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [03-bytes](modules/03-bytes/README.md) | Raw DISPLAY/COMP/COMP-5/COMP-3 bytes and malformed Packed parsing | `bash modules/03-bytes/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [04-structures](modules/04-structures/README.md) | REDEFINES/OCCURS/ODO/COPY REPLACING, 175-field catalog and offsets | `bash modules/04-structures/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [05-control](modules/05-control/README.md) | IF/EVALUATE/PERFORM, SEARCH, STRING/UNSTRING, customer cleansing | `bash modules/05-control/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [06-files](modules/06-files/README.md) | FD/FILE STATUS/EOF, fixed-length and LINE files, relative/indexed files and locks | `bash modules/06-files/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [07-matching](modules/07-matching/README.md) | SORT/MERGE, L1/L2/L3/L4 matching benchmarks (12h, core) | `bash modules/07-matching/check.sh` | L1/L2/SORT/MERGE/L3 accepted by primary agent; L4 awaiting primary agent acceptance |
| [08-database](modules/08-database/README.md) | Real ESQL cursors/NULL/transactions/idempotency (6h) | `bash modules/08-database/scripts/check-quick.sh` (offline); `.../scripts/check.sh` (real DB, requires Docker) | Real DB end-to-end run verified with RC0; awaiting primary agent review |
| [09-modular](modules/09-modular/README.md) | CALL/LINKAGE/USING, RETURNING, shared modules, and state lifecycle | `bash modules/09-modular/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [10-jobs](modules/10-jobs/README.md) | JOB001–009, RC/locks/snapshots/Manifest, recovery across four crash boundaries (9h, core) | `bash modules/10-jobs/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [11-incidents](modules/11-incidents/README.md) | Six types of incident investigation, maintenance expanding customer classification from 1 to 2 digits (9h, core) | `bash modules/11-incidents/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |
| [12-capstone](modules/12-capstone/README.md) | Integrated project on an unfamiliar system, four day-close workflows, hidden incidents, and grading (9h) | `bash modules/12-capstone/scripts/check.sh` | Execution agent self-test complete; awaiting primary agent review |

## Local Acceptance

```bash
cd "$(git rev-parse --show-toplevel)/extensions/enterprise-batch"
bash curriculum/check.sh                                  # P1 + quick acceptance entry points for all 12 modules + fixed-format gate
bash curriculum/modules/07-matching/check.sh              # Standalone entry point for Module 07
bash curriculum/modules/08-database/scripts/check.sh      # Real DB end-to-end (Docker + PostgreSQL + GixSQL)
bash curriculum/validation/database/check.sh              # P1 ESQL toolchain regression (Docker)
python3 curriculum/modules/07-matching/labs/01-one-to-one/scripts/pressure.py    # L1 memory pressure
python3 curriculum/modules/07-matching/labs/04-many-to-many/scripts/pressure.py # L3 multi-stream pressure
python3 curriculum/modules/07-matching/labs/05-large-record/scripts/pressure.py # L4 full-pipeline pressure (including oracle)
bash curriculum/scripts/package-student.sh                # Generate student package excluding instructor/
```

`curriculum/check.sh` does not require Docker. It runs P1 checks, the quick acceptance entry point for every module, and three gates: frozen bank interface widths (measured as 47/55/27 bytes for all `copybooks/{ACCOUNT,TRANSACTION,CUSTOMER}-V1.CPY` files), curriculum material structure (README/DESIGN/starter/fixtures/expected/scripts/evidence and both routes for all 12 modules), and the 72-column/ASCII/no-Tab gate. The quick entry point for `08-database` checks only the offline contract; the real DB experiment has a separate optional entry point. On its first run, `curriculum/validation/database/check.sh` builds the ESQL tool online, uses an ephemeral database/network, and cleans up on exit; it creates no host ports or persistent database volumes.

If Docker, GixSQL, or PostgreSQL is unavailable locally, real DB and some interpreter experiments must be marked “UNVERIFIED”; do not report them as passing.

## Platform, ABI, and Verified Boundaries

- The required platform is Linux x86-64 + GnuCOBOL 3.2.0; macOS/WSL/ARM have not been tested and are marked “UNVERIFIED” in the documentation.
- PIC COMP was measured as big-endian locally; COMP-5 is native little-endian. Interpret binary representations using the pinned ABI; do not extrapolate across platforms.
- Module 08 uses real Embedded SQL (a pinned GixSQL commit, two local patches, and PostgreSQL); the DB layers in modules 10/11/12 are explicitly marked **offline file checkpoints** (`real_db_verified=false`) and are not connected to real PostgreSQL.

## Development Progress

| Phase | Current status |
|---|---|
| P0 Design | Complete and approved for implementation |
| P1 Technical validation | Byte/two-stream/real DB baselines and evidence are in `validation/`; platform limited to Linux x86-64 |
| P2 Module 07 benchmark | L1/SORT/MERGE/L2/L3 accepted by primary agent; L4 implemented with full-pipeline stress evidence and awaiting primary agent acceptance |
| P3 Modules 01–06, 09 | All implemented and passed execution agent self-tests; awaiting independent primary agent review |
| P4 Modules 08, 10 | Implementation complete; real DB tested for 08, offline DB marked for 10; awaiting primary agent review |
| P5 Modules 11, 12 | Implementation complete: six incident types and maintenance in 11, unfamiliar system and grading in 12; awaiting primary agent review |
| P6 Release/legacy content transition | Student packaging script and main entry point are ready; old curriculum materials archived under `extensions/legacy-workshop/` |

The design document remains the source of truth for the curriculum baseline. Inputs and expected business results are defined before implementation in every lesson; unverified platforms, recovery boundaries, and DB status remain explicitly incomplete. See the [implementation Goal handoff document](../tasks/enterprise-cobol-implementation-goal.md) for task and review protocols.
