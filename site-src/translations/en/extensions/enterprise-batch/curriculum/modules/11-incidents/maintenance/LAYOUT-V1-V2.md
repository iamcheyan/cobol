# Enterprise Customer Classification 1→2 Characters: Interface Change Specification (Provided)

The subject is the **separate, versioned enterprise customer layout** `ENTERPRISE-CLASS`, **not** the 27-byte canonical CUSTOMER v1 record (whose byte 27 is record status A/D).

> **Naming and relationship (avoid same-name drift)**: The course's canonical large record is Module 07 L4 `ENTERPRISE-CUSTOMER-V1` (175 fields / 1778 bytes). This exercise deliberately uses the separate name `ENTERPRISE-CLASS` (23→24 bytes), retaining only the semantics of the same `CUSTOMER-CLASSIFICATION` field. It does **not** reuse the canonical name, avoiding different layouts drifting under the same name.

## 1. Layout comparison

| Item | V1 (current baseline) | V2 (target) |
|---|---|---|
| Layout version | `001` | `002` |
| Record width | **23 bytes** | **24 bytes** |
| Customer classification field | `CUSTOMER-CLASSIFICATION PIC X(1)` | `CUSTOMER-CLASSIFICATION PIC X(2)` |
| Classification values | `A` / `B` / `C` / `D` | `A1` / `B1` / `C1` / `D1` |
| Mapping | — | `A→A1`, `B→B1`, `C→C1`, `D→D1` |

Baseline definition: `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY`.

## 2. Byte offsets (1-based)

| Bytes | V1 length | V2 length | Field |
|---:|---:|---:|---|
| 1–3 | 3 | 3 | `LAYOUT-VERSION` (`001`→`002`) |
| 4–11 | 8 | 8 | `CUSTOMER-ID` |
| 12 | 1 | 1 | `RECORD-STATUS` (A active / I inactive) |
| 13–22 | 10 | 10 | `CUSTOMER-NAME` |
| 23 | 1 | — | `CUSTOMER-CLASSIFICATION` (V1, 1 character) |
| 23–24 | — | 2 | `CUSTOMER-CLASSIFICATION` (V2, 2 characters) |

**Key impact**: Classification is at the **end** of the record. Widening it only makes the record longer (+1 byte); all preceding field offsets remain unchanged in V2. However, the change in **total record length** affects fixed-width reads, file header/trailer handling, checksums, and downstream consumers that slice by byte. `RECORD-STATUS` has a different business meaning and **must not** be used as classification.

## 3. Compatibility and migration constraints

- **Do not rewrite V1 files in place**: the migration tool writes a **new V2 file**, preserving the original for parallel validation and rollback.
- Readers must choose width by version: `001` → 23 bytes; `002` → 24 bytes. A version/width mismatch must abort with `RC8`; do not silently pad or truncate.
- Version the downstream interface (`CLASS|<id>|<class>`): V1 class is 1 character; V2 is 2 characters. Both versions must be distinguishable during cutover.
- Rollback: V2 → V1 must be lossless (requires the second V2 character to be `1`) and reproduce the original V1 byte for byte.

## 4. External interfaces and downstream consumers to cover (investigation checklist, not exhaustive)

- `maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY` (baseline interface definition)
- Enterprise-classification reader/extractor (reference: `M11CUST2.COB`)
- `migrate-customer.py` (migration/rollback/parallel validation)
- Downstream enterprise-classification extract (`CLASS|<id>|<class>`)
- `fixtures/enterprise-customer/customer.v1` (V1 input)
- DB: this course snapshot uses an offline checkpoint (real DB unverified); if a real DB column exists, assess its width/migration and mark it unverified.
- **Unaffected**: canonical CUSTOMER v1 (27 bytes, byte 27 is status); nightly flow `M11CUST.COB` and `publish/<run_id>/customer-status.txt`.
- Documentation: `../../../../docs/curriculum/BANK-SYSTEM.md` (frozen-contract evolution)
