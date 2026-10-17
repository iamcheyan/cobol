# Independent expectations (Module 05)

`expected/*.txt` are whole-file expectations for `report.txt`, determined from the business rules and the **hand-calculated examples** in DESIGN.md. `check.py` independently rebuilds accepted/rejected outputs from fixtures and compares them byte for byte. Never treat reference implementation output as the answer. Naming convention: `<group>-<case>.txt`.

- `normal-clean.txt`: all 3 records accepted; status `a`→`A`, `D` unchanged; AMOUNT=60.
- `boundary-empty.txt`: READ=ACCEPT=REJECT=0, AMOUNT=0 (an empty file is valid).
- `boundary-min-amount.txt`: amount 0 is valid; AMOUNT=0.
- `boundary-max-amount.txt`: amount 50,000,000 is valid; the two records total 50,000,001.
- `boundary-single.txt`: one record, AMOUNT=1.
- `invalid-missing-name.txt` / `bad-id` / `non-numeric-amount` / `amount-over-cap` /
  `unknown-status` / `duplicate-id`: one rejected record each, with the reason shown above; `duplicate-id` has 1 accepted + 1 rejected, AMOUNT=50.
- `invalid-mixed.txt`: the DESIGN hand-calculated example: READ=6, ACCEPT=1, REJECT=5, AMOUNT=50.

Structural/contract error fixtures (`unsorted`, `short-record`, `long-record`, `no-trailing-lf`,
`crlf`) have **no** expected report: the expected result is RC8 and no publication.

Calculation example (`boundary-max-amount.dat`): record 1 has amount 50,000,000 and record 2 has amount 1. Both are valid, so AMOUNT = 50,000,000 + 1 = 50,000,001; 2 records read = 2 accepted + 0 rejected.
