# Maintenance Change Package: Enterprise Customer Classification from 1 to 2 Characters

This directory is the Legacy Maintenance change package required by section 6 of `AUTHORING-STANDARD`.
The change must be **investigated before modification**: the order below is also the delivery order; do not edit code until review is complete.

| Order | File | Deliverable |
|---:|---|---|
| 1 | [impact-investigation.md](impact-investigation.md) | Impact investigation |
| 2 | [change-list.md](change-list.md) | Change target list |
| 3 | [change-policy.md](change-policy.md) | Change policy (layouts v1/v2, compatibility, migration, rollback) |
| 4 | [test-cases.md](test-cases.md) | Test cases |
| 5 | [evidence-plan.md](evidence-plan.md) | Evidence plan |
| 6 | [copybooks/CAP-CUSTOMER-FEED-V2.CPY](copybooks/CAP-CUSTOMER-FEED-V2.CPY) | Frozen v2 interface (32 bytes) |
| 7 | [regression/red-green.sh](regression/red-green.sh) | Before/after regression (RED→GREEN) |

Requirement (original): **Expand customer classification from 1 character to 2.**

## Change target: independent, versioned enterprise customer layout

The change target is **not** the 27-byte canonical CUSTOMER v1. Byte 27 of that frozen interface is **record status** (A=active / D=disabled), unrelated to customer classification, and is **not changed** in this repository (see [curriculum/bank/README.md](../../../bank/README.md) and [section 2 of BANK-SYSTEM.md](../../../../docs/curriculum/BANK-SYSTEM.md)).

Customer classification belongs to a **separate, versioned capstone customer feed**, named `CAP-CUSTOMER-FEED`. It deliberately does **not share a name** with the 1778-byte, 175-field canonical `ENTERPRISE-CUSTOMER` large record in modules 04/07: their physical lengths and fields are incompatible, and a shared name would let a version label hide layout drift (the module 11 experimental layout is likewise named separately).

| Layout | Version | Width | `CUSTOMER-CLASSIFICATION` | Values |
|---|---|---:|---|---|
| CAP-CUSTOMER-FEED v1 | `001` | 31 B | `PIC X(1)` | `A`/`B`/`C`/`D` |
| CAP-CUSTOMER-FEED v2 | `002` | 32 B | `PIC X(2)` | `A1`/`B1`/`C1`/`D1` |

The enterprise layout **embeds** the 27-byte canonical CUSTOMER v1 (bytes 1–27), so byte 27 remains record status; classification is a separate field appended after it.

Reference interfaces: `system/copybooks/CAP-CUSTOMER-FEED-V1.CPY` (31 bytes) and `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` (32 bytes). The canonical `system/copybooks/CUSTOMER-V1.CPY` (27 bytes, byte 27 = status) remains unchanged.
