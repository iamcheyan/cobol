# Independent Expected Results and Manual Reconciliation (Module 01)

The expected results in this directory are derived from the ACCOUNT v1 contract and manual, record-by-record reconciliation; they are not copies of program output.
`check.py` compares the control report byte for byte and independently derives `accepted.dat` and
`rejected.dat` from the original fixtures, without trimming the entire file.

## Contract Rules

An ACCOUNT v1 record must satisfy the following within its 47 bytes: account positions 1–10 are all digits; currency positions 19–21 are `JPY`;
sign position 22 is `+`/`-`; amount positions 23–35 are all digits; status position 36 is `A`/`F`/`C`; date positions 37–44 equals the job's
business date; and layout version positions 45–47 are `001`. Files must be in strictly ascending account order.

- Structural contract violations (length, LF, CR, account characters, layout, date, ordering/duplicate keys): RC8; the entire batch fails,
  and no output directory is published.
- Business field rule (unknown status): RC4; that record goes to `rejected.dat`, the rest go to `accepted.dat`,
  and the reconciled results are still published.
- Read-count conservation: `READ = ACCEPTED + REJECTED`.

## Reconciliation by Fixture

**normal**: 3 records, accounts 1/2/3 in strictly ascending order, and all statuses A/F/C are valid → accept 3, reject 0.

```text
READ=000000000003  ACCEPTED=000000000003  REJECTED=000000000000
```

**empty**: 0-byte file, allowed to be empty → read 0 records.

```text
READ=000000000000  ACCEPTED=000000000000  REJECTED=000000000000
```

**single**: 1 record, account 42, status A → accept 1.

```text
READ=000000000001  ACCEPTED=000000000001  REJECTED=000000000000
```

**unknown-status**: 1 record, account 7, status `Z` (not in `A/F/C`) → reject 1, reason `UNKNOWN-STATUS`.

```text
READ=000000000001  ACCEPTED=000000000000  REJECTED=000000000001
```

The rejected-record format is the original 47 bytes + `|` + reason, so this line in `rejected.dat` is 62 bytes (excluding LF):

```text
000000000700000003JPY+0000000000000Z20261009001|UNKNOWN-STATUS
```

## Publication Conditions

The control row `CONTROL|READ=..|ACCEPTED=..|REJECTED=..` must match the reconciliation above, and `accepted.dat`/`rejected.dat` must match byte for byte for the run to pass. For RC8 fixtures, the pass condition is that **no** output directory is created and the source fixture SHA256 remains unchanged.
