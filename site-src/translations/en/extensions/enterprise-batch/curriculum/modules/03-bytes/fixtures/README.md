# Fixed Binary Fixtures

All `.dat` files are generated deterministically by [../scripts/generate-fixtures.py](../scripts/generate-fixtures.py) (no external randomness or seed dependency). Each record is 7 bytes, `PIC S9(11)V99 COMP-3`; files contain no LF or other separators. See [SHA256SUMS](SHA256SUMS) for SHA256 hashes.

- `normal/mixed-valid.dat`: one record each for positive, negative, positive zero, negative zero, and maximum amount.
- `boundary/`: empty file, positive zero, negative zero, maximum amount.
- `invalid/`: invalid digit nibble `0xA`, invalid sign nibble `0xF`, truncated 6-byte record, 8-byte record (misaligned).

After updating fixtures, first review the hexadecimal diff, then independently verify the manual calculations in `../expected/`; do not generate answers from program output. Invalid bytes are committed as actual bytes, rather than merely described as “bad data” in the README.
