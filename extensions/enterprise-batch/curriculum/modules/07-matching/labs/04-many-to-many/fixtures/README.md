# B03 fixtures and independent expected data

`normal/` is the 47B ACCOUNT, 55B TRANSACTION, 48B REVERSAL-LINK, 36B
CUSTOMER-SNAPSHOT and 39B PREVIOUS-DAY normal example. The transaction IDs
and customer keys intentionally disagree in sort order. `expected/` was
calculated by hand from opening + accepted credits - accepted debits.

`cases/` contains literal boundary rows and a JSON expected policy matrix.
These case bytes are independently authored policy variants; the checker uses
them as runner inputs and validates RC, published partition and values through
its separate SQLite oracle. Verify all checked-in fixture and expected hashes
with `sha256sum -c SHA256SUMS` from this lesson directory.
