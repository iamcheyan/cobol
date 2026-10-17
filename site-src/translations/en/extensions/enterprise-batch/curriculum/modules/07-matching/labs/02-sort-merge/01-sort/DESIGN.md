# 07.1 SORT: deterministic transaction-file sorting contract

## Interface and ordering

Input/output both use TRANSACTION v1: each record is 55 ASCII bytes + LF; LF is not part of the 55 bytes. The input business date is an argument and is checked against the Gregorian calendar on every row. Account, transaction ID, date, sequence, direction (C/D), 13-digit unsigned amount (zero is valid), and status (only N) are validated. IDs allow only ASCII A–Z and 0–9. Empty input is allowed; a nonempty final row must end in LF. Do not read into a fixed-length PIC first and guess the original width afterward.

Business sort key: `(account_id 1–10, sequence_no 35–40, transaction_id 11–26)`, strictly ascending across all three components. Preserve all original 55 field bytes and emit canonical LF. Records with the same sequence but different IDs are valid; `transaction_id` determines their order. A globally repeated `transaction_id` (including nonadjacent rows or different accounts) is a contract error, RC8, with no publication; an identical composite key is therefore also rejected. Do not rely on runtime stability for identical full keys.

Hand example: Z…001 has sequence 000001; A…002 and M…003 have sequence 000002. Business-key output is Z…001, A…002, M…003. Lexically, the sequence-1 Z sorts after the sequence-2 A, but business order must put Z first; within the same sequence A must precede M. This also proves that sorting is not by the whole line or ID alone. See `expected/normal.dat` for the complete sample.

## Program boundary and RC

The COBOL SD sort-work record is composed from TRANSACTION-V1.CPY. The SORT INPUT PROCEDURE reads and validates each byte and RELEASEs records; the OUTPUT PROCEDURE writes 55-byte records in RETURN order. The runner explicitly sets `COB_SORT_MEMORY`, defaulting away from GnuCOBOL's large 128M pool; the value must be ≥1M. Work beyond the sort pool spills to disk. An independent external cut/sort is used only to check global ID uniqueness, not to produce transaction order.

| RC | Condition | Publish |
|---:|---|---|
| 0 | Input contract valid, IDs unique, SORT-RETURN=0, output verification passes | Atomic publication |
| 8 | Length/character/field/date error or duplicate ID | No |
| 12 | Open/read/write/lock/build/temp work-file/permission/unexpected SORT-RETURN/verification/publication failure | No |

The verifier checks output bytes as a stream, full-key ascending order, preservation of every source field, input/output count conservation, and ID uniqueness. Candidate stdout or partial files are never official output. A SORT work-file resource error must be checked using `SORT-RETURN` and mapped to RC12.
