# Shared field catalog: SORT/MERGE and L2 bridge

Canonical source: [TRANSACTION-V1.CPY](../../../../../bank/copybooks/TRANSACTION-V1.CPY). SORT and MERGE SD records `COPY` this version directly; do not copy it for the course or create another field definition. Input/output is 55 ASCII bytes; line-ending LF is excluded from the record length.

| Bytes (1-based) | Field | PIC | Contract |
|---|---|---|---|
| 1–10 | TX-ACCOUNT-ID | X(10) | ASCII digits |
| 11–26 | TRANSACTION-ID | X(16) | ASCII `A-Z` / `0-9`; globally unique |
| 27–34 | TRANSACTION-DATE | X(8) | Must equal JOB business date and be a valid Gregorian date |
| 35–40 | TRANSACTION-SEQUENCE | X(6) | ASCII digits; second sort-key component |
| 41 | TRANSACTION-DIRECTION | X | `C` or `D` |
| 42–54 | TRANSACTION-AMOUNT | X(13) | ASCII digits; zero is valid and classified by downstream business rules |
| 55 | TRANSACTION-STATUS | X | `N` only; reversal association is represented in separate REVERSAL-LINK v1 |

Full sort key is (account 1–10, sequence 35–40, ID 11–26), ascending for each component. MERGE sources are strictly ascending. Records with the same account/sequence and different IDs are valid.
