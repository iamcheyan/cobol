# Corrective Patch (Enterprise Customer Classification from 1 to 2 Characters)

This directory records the delivered correction. The correction is already included in the runnable reference implementation, so this document avoids repeating large code blocks and lists only the changes and reproducible entry point:

| Change | File | Description |
|---|---|---|
| New interface | `system/copybooks/CAP-CUSTOMER-FEED-V2.CPY` | Frozen 32B interface (enterprise layout v2) |
| Validation/normalization | `system/cobol/CUSTV2.COB` | Accepts 31/32B; upgrades v1→v2; BADSTATUS/BADCLASS/BADVERSION |
| Report width guard | `system/cobol/NIGHTRPT.COB` | Checks declared layout against physical width |
| Storage | `system/lib/capdb.py` | Stores 32B in customer.table |
| Byte guard | `system/lib/validate.py` | Enterprise layout widths 31/32 |

The change applies to the **separate, versioned enterprise customer layout** (`CAP-CUSTOMER-FEED` v1/v2), not the 27 bytes of canonical CUSTOMER v1; byte 27 status semantics remain unchanged.

Pre-change baseline (RED): `starter/CUSTV2.COB` (v1-only, returns RC12 for v2).

Reproduce RED→GREEN:

```bash
bash curriculum/modules/12-capstone/maintenance/regression/red-green.sh /tmp/m12-rg
```

Rollback: see section 4 of `maintenance/change-policy.md`.
