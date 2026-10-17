# Independent expectations (Module 06)

`expected/*.txt` are whole-file expectations for `report.txt`, determined from the DESIGN field contract and hand calculations, then independently rebuilt by `check.py` from fixtures for byte-for-byte accepted/rejected comparison. Naming convention: `<group>-<case>.txt`.

- `normal-valid.txt`: BALANCE = +1000 + 50 − 500 = **550**; READ=ACCEPT=3, REJECT=0.
- `boundary-empty.txt`: READ=ACCEPT=REJECT=0, BALANCE=0 (empty file is valid).
- `boundary-single.txt`: +1.
- `boundary-negative-balance.txt`: BALANCE = −9,999,999,999,999.
- `boundary-zero-balance.txt`: BALANCE = 0.
- `invalid-bad-account-id` / `bad-customer-id` / `unknown-currency` / `bad-sign` /
  `bad-balance` / `bad-date` / `date-mismatch` / `unknown-status`: one rejected record each, with the reason in the DESIGN catalog; BALANCE=0.
- `invalid-duplicate-id.txt`: 1 accepted + 1 rejected; BALANCE=1000.
- `invalid-mixed.txt`: the DESIGN hand-calculated example: READ=6, ACCEPT=2, REJECT=4, BALANCE=1100.

Contract-error fixtures (`bad-layout`, `unsorted`, `short-record`, `long-record`, `no-trailing-lf`,
`crlf`) have **no** expected report because the expected result is RC8 and no publication. A missing file likewise has no expected report (RC12).

Calculation example (`invalid-mixed.dat`): record 1 (+1000) and record 6 (+100) are accepted; the other four records are each rejected for one field error. BALANCE = 1000 + 100 = 1100; 6 records read = 2 accepted + 4 rejected.
