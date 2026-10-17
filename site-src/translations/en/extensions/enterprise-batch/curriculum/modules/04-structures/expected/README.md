# Module 04 Expected Results and Independent Verification

`expected` is determined independently from structure semantics and measured ABI, then compared against the compiled COBOL output; program output is not treated as the answer. The core measurements are performed field by field by [../scripts/check.py](../scripts/check.py) using GnuCOBOL `ADDRESS OF` (175 leaves + V1/V2 offsets), and written to [../evidence/M04-layout-author.json](../evidence/M04-layout-author.json).
Before release, `run.sh` uses [../scripts/verify.py](../scripts/verify.py) to recompute the report using the same semantics and compare each item (04.3 is recomputed directly from the raw bytes using the catalog offsets); any mismatch is rejected and nothing is published.

## 04.1 Structure Semantics

| Item | Expected | Basis |
|---|---|---|
| WRAP length | 18 | PAYLOAD=8+7+3=18; the REDEFINES alias occupies no additional bytes |
| PAYLOAD / PAYLOAD-RAW length | 18 / 18 | Two views of the same storage area |
| R-AB length | 7 | RENAMES R-A(3) THRU R-B(4) |
| R-AB value | `AAABBBB` | R-A=`AAA`, R-B=`BBBB` |
| OCCURS item count / INDEX-3 | 5 / `CCC` | `SET IDX-POS TO 3` selects the 3rd item |
| ODO count=3 length | 17 | 2 (count) + 3×5 |
| ODO count=7 length | 37 | 2 (count) + 7×5 |

## 04.2 COPY REPLACING and Offset Shifts

| Item | Expected | Basis |
|---|---|---|
| LEN,V1 | 1778 | Canonical length of enterprise customer V1 |
| LEN,V2 | 1779 | Only CUSTOMER-CLASSIFICATION changes from X(1) to X(2) |
| SHIFT | 1 | Widened by 1 byte |
| Classification offset | 460 (same in both versions) | The classification field itself is widened after its starting offset |
| SYNC-STATE offset | V1=1778 / V2=1779 | Every field after it shifts by +1 |
| REFMOD FIRST4/LAST6 | `0000` / `000001` | `CUSTOMER-ID` = `0000000001` |

## 04.3 Enterprise Record Location

- `normal/enterprise-2.dat`: 2 records (key 0000000001=A/EXAMPLE/1234, 0000000003=B/SAMPLE/-25). See [04.3-normal.txt](04.3-normal.txt).
- `boundary/enterprise-1.dat`: 1 record; `boundary/enterprise-empty.dat`: 0 records (RC0).
- `invalid/`: length mismatch / version `009` / ABI mismatch / nonnumeric key all return RC8 with nothing published.

## Relationship to Module 07

The catalog, Copybook, and 1,778-byte layout share the same source as Module 07 L4; this module teaches only structure and record location, not field-by-field business-domain comparison. The consistency of the 175 field offsets with the catalog is independently rechecked by this module's `check.py`.
