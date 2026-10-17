# Change Target List

Responsible roles: upstream interface (external), batch development (this repository), DB operations, downstream consumers.

| # | Category | Target | Change | Owner | Regression evidence |
|---:|---|---|---|---|---|
| 1 | Copybook | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | Add frozen 32B interface | Batch development | Format check |
| 2 | Program | `system/cobol/CUSTV2.COB` | Accept 31/32B; upgrade v1 to v2; validate BADSTATUS/BADCLASS/BADVERSION | Batch development | RED→GREEN |
| 3 | Program | `system/cobol/NIGHTRPT.COB` | Check declared layout against physical width | Batch development | Layout guard |
| 4 | DB | `system/lib/capdb.py` | Store 32B in `customer.table`; let `read_customer_records` accept 31/32B | DB operations | Snapshot/apply |
| 5 | File | `fixtures/extension/` | Add a synthetic v2 day | Batch development | Four day types |
| 6 | Shell | `system/jobs/job002-validate.sh` | Use CUSTV2 output normalized to v2 | Batch development | JOB002d |
| 7 | JOB | `JOB002/JOB004/JOB007` | Document layout-dependent behavior; no topology change | Batch development | Full nightly flow |
| 8 | Design docs | `DESIGN.md`, this change package | Record layout versions and migration | Batch development | Documentation review |
| 9 | Downstream interface | `customer-day.dat` | Fix classification field at 2 characters (upgrade v1 day `A→A1`) | Downstream consumers | Compatibility test |
| 10 | Upstream interface | `customer.extract` | Declare layout version (001/002) | Upstream | MANIFEST |

Do not modify modules 01–11, canonical runners (SORT/L2/BANKVAL), or frozen ACCOUNT v1 (47B)/TRANSACTION v1 (55B)/CUSTOMER v1 (27B, byte 27 = record status).
