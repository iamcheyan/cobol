# Module 08 fixtures

All fixtures contain synthetic data for business date `20261009`. Text interfaces are ASCII and LF-terminated; LF is excluded from fixed record widths. CUSTOMER v1 records are 27 bytes and TRANSACTION v1 records are 55 bytes. `SHA256SUMS` covers the fixture files, and the checks verify inputs before and after execution. Do not edit originals; create temporary copies for fault exercises.

| Fixture | Purpose |
|---|---|
| `customer-upstream-20261009.dat` | Upstream CUSTOMER file with one field difference, one file-only key, and one DB-only key |
| `customer-upstream-20261009-nodiff.dat` | Upstream file identical to the database snapshot |
| `transactions-20261009.dat` | Three transactions used to verify commit and balance updates |
| `transactions-dup-in-run.dat` | Repeats a transaction within a single run to exercise RC8 rollback |

The database seed is in `db/seed.sql`. The fixtures are designed to support independent calculations documented in `expected/README.md`; program output is not the source of expected results.