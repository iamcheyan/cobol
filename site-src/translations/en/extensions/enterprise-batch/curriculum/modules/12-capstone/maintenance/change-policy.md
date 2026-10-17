# Change Policy: Layouts v1/v2, Compatibility, Migration, and Rollback

## 1. Layout strategy

- **Append** rather than rewrite: enterprise layout v2 = v1's 31 bytes + a second classification subcode character. Bytes 1–27 (including the canonical CUSTOMER v1 prefix and byte 27 record status) retain their meaning, so old readers that "read only the first 27 bytes" will not encounter shifted data.
- v1 classification upgrade rule: `A` → `A1`, `B` → `B1`, `C` → `C1`, `D` → `D1` (subcode `1` means "v1 baseline subdivision"). This matches the mapping in module 07 L4.
- Valid v2 codes: `[ABCD][0-9]`. Other values are `BADCLASS` (business rejection, RC4).
- Record status still accepts only `A`/`D` and is validated independently from classification; other values are `BADSTATUS` (RC4).
- layout_version must match the declared layout (`001`/`002`); a mismatch is `BADVERSION` (RC4).
- The entire file uses one layout; mixing 31/32-byte records within one file is a structural error (RC8).

## 2. Compatibility strategy

| Reader | v1 file | v2 file |
|---|---|---|
| v1-only legacy program | Works | **Rejected** (width 32 ≠ 31, RC8 / RC12 for unfinished implementations) |
| v2 program (this delivery) | Reads 31B and upgrades to v2 | Reads 32B |
| DB `customer.table` | — | Stores v2 (32B) consistently |
| Downstream `customer-day.dat` | Classification column upgraded to `A1`..`D1` | Classification column contains v2 code |

## 3. Migration steps

1. Upstream declares `layout_customer=002` in MANIFEST and delivers an enterprise layout v2 file.
2. At JOB002a, this system checks physical width against the declared layout; a mismatch returns RC8 and does not publish.
3. JOB002d normalizes v1/v2 to v2 and writes it to DB `customer.table` (32B).
4. Existing 31B rows in the DB: `capdb.read_customer_records` upgrades them automatically; no downtime script is needed. For a one-time physical migration, rewrite `customer.table` using the same function.
5. Switch downstream readers to v2; during the transition, the v1 reading path in NIGHTRPT can still be used for reconciliation.

## 4. Rollback steps

- Rolling code back to a v1-only version allows it to read v1 files (v2 files will be rejected).
- Data rollback: project DB `customer.table` from 32B back to 31B (discard byte 29's subcode). **Projection loses the subcode**; do this only after confirming downstream does not use it, and retain the original v2 backup.
- Rollback does not change original input fixtures, only derived data; after rollback, rerun the day and reconcile control totals.
- **The 27 bytes of canonical CUSTOMER v1 and the byte 27 status semantics are outside rollback scope and always remain unchanged.**

## 5. Data cutover and parallel validation

- Parallel period: run old and new versions once each on the same v1 day and compare `customer-day.dat` and control totals.
- Cutover criteria: v1 day, v2 day, and cross-version day all pass, and the incident materials are reproducible without changing original input.
