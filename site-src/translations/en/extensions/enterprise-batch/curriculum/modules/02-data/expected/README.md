# Independent Expected Results and Manual Calculations (Module 02)

Expected results are derived manually from the CUSTOMER v1 contract and COBOL `MOVE` rules; they are not program output. `check.py` compares the control report and
`movelab.txt` byte for byte, and independently derives `accepted.dat`/`rejected.dat` from the raw fixtures.

## CUSTOMER v1 Load Calculations

Rules: 27 bytes per record; ID is 8 digits and strictly ascending; name is not all spaces; `balance_demo` is 8 digits (in cents,
unsigned); status is `A`/`D`. Rejection priority: `NAME-MISSING` > `BAD-AMOUNT` > `UNKNOWN-STATUS`.
`BALANCE-TOTAL` accumulates accepted records only.

**normal**: `ALICE 12345` + `BOB 50` + `CAROL 9999999`, with valid statuses A/D/A.
12345 + 50 + 9999999 = **10012394**; 3 accepted, 0 rejected.

```text
READ=3  ACCEPTED=3  REJECTED=0  BALANCE-TOTAL=10012394
```

**empty**: 0 bytes, allowed to be empty → all zeroes.

**single**: `SOLO 500` → 1 accepted, total 500.

**max-balance**: `MAX 99999999` (8-digit limit) → 1 accepted, total 99999999.

**name-full**: name is exactly 10 characters, `ABCDEFGHIJ` → 1 accepted, total 1000.

**name-missing**: name is 10 spaces → 1 rejected, reason `NAME-MISSING`, total 0.

**bad-amount**: `balance_demo` = `00000A00` (contains the letter A) → 1 rejected, reason `BAD-AMOUNT`, total 0.

**unknown-status**: status is `Z` → 1 rejected, reason `UNKNOWN-STATUS`, total 0.

Rejected record format is the original 27 bytes + `|` + reason, for example:

```text
00000006          00000000A|NAME-MISSING
00000007BADBAL    00000A00A|BAD-AMOUNT
00000008STATUS    00000000Z|UNKNOWN-STATUS
```

## Structural Fixtures (RC8, no formal expected results)

`short`(26B), `long`(28B), `crlf`, `bad-id`, `duplicate-id`, `unsorted`, and `no-final-lf` all
violate the interface contract. The contract requires **the entire batch to fail without producing any output directory**,
so there is no formal report; the pass condition is “no output directory and the source fixture SHA256 is unchanged”.

## MOVE Experiment Table (`expected/movelab.txt`)

Rule source: COBOL fixed-point **decimal alignment** and alphanumeric **left alignment/right space padding** semantics.

| Case | Expression | Expected bytes | Rationale |
|---|---|---|---|
| A | `PIC 9(3)V99 VALUE 41.5` display | `A|041.50|` | Implied decimal displays with a decimal point; 3+2 digits |
| B | `41.5 → PIC 9(5)` | `B|00041|` | After decimal alignment, take integer 41 |
| C | `PIC 9(5) 41 → PIC X(5)` | `C|00041|` | Numeric → alphanumeric preserves 5 displayed digits |
| D | `'AB' → PIC X(5)` | `D|AB   |` | Alphanumeric pads with 3 spaces on the right |
| E | `S9(3) LEADING SEPARATE -12` | `E|-012|` | Separate sign occupies 1 byte |
| F | `S9(3)V99 LEADING SEPARATE -1.25` | `F|-001.25|` | Sign + implied decimal |
| G | `'ABCDEFGH' → PIC X(5)` | `G|ABCDE|` | Truncate on the right, keeping the first 5 characters |
| H | `12345 → PIC 9(3)` | `H|345|` | Truncate high-order numeric digits, keeping the low-order digits |
| I | `12345.67 → PIC 9(3)V99` | `I|345.67|` | Truncate high-order digits; retain the fractional part |

## Type and Hierarchy Experiment Table (`expected/typeslab.txt`)

Input `fixtures/types/typeinput.dat`: three 5-byte records, `ABCDE` / `AB123` / `AB CD`. Rule source:
`IS ALPHABETIC` is true for letters and spaces and false for digits; `MOVE` does not perform category validation.

| Record | Original `PIC X(5)` value | Moved to `PIC A(5)` | `IS ALPHABETIC` | Category |
|---|---|---|---|---|
| `ABCDE` | `ABCDE` | `ABCDE` | true | `A` |
| `AB123` | `AB123` | `AB123` | false | `M` |
| `AB CD` | `AB CD` | `AB CD` | true | `A` |

`78 WS-LIMIT VALUE 25` displays `25`; `77 WS-COUNT` counts each record up to `00003`. Full expected output (byte for byte):

```text
TYPESLAB|V1
LIMIT|25|
00001|ABCDE|ABCDE|A|
00002|AB123|AB123|M|
00003|AB CD|AB CD|A|
COUNT|00003|
```

Reproducible failure: moving `X` data containing digits to `PIC A` does **not** automatically reject it (see record 2); moving a numeric item
with `MOVE` to `PIC A` fails directly at compile time, and `check.py` asserts that the `MOVE` exits nonzero.

## Layout Experiment

`LENGTH-PROBE` outputs `CUSTOMER-RECORD=27`, `NAME-LENGTH=10` for the canonical Copybook; for the **intentionally
incorrect, non-contract** `X(11)` variant it outputs `28`, `11`. This demonstrates that changing a single field's `PIC` moves the total record length and
subsequent offsets; this variant demonstrates an incorrect layout, not the CUSTOMER v1 contract or a 27→28 migration.

## Release Conditions

Pass only when `control.txt` has two lines, counts/totals match the calculations above, `accepted.dat`/`rejected.dat` match byte for byte,
and `movelab.txt`, `typeslab.txt` match the experiment outputs byte for byte.
