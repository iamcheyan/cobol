# L4 fixtures

The old and new files are fixed-width binary record streams for `ENTERPRISE-CUSTOMER-V1` (1,778 bytes per record, with no separator or LF). They contain synthetic ASCII values and are designed to exercise field-level comparison rules. `old.dat` and `new.dat` include matching, old-only, and new-only customer keys, plus selected changes for RAW, TEXT-NORM, NUMERIC, and IGNORE-AUDIT behavior.

Do not edit fixtures in place. Use a work copy for mutation exercises and retain the original hashes. The independent verifier checks field offsets, values, comparison classifications, and the complete output manifest.