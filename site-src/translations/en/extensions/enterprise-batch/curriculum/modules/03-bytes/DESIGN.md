# Module 03 Design: Physical Amount Representation and Invalid Data Parsing

This design changes neither the CUSTOMER v1=27B, ACCOUNT v1=47B, nor TRANSACTION v1=55B contracts, and does not change module 07 or the existing P1 experiment.

## Environment and ABI baseline

- GnuCOBOL 3.2, Linux x86-64, **default dialect**; `COMP-3` / `FUNCTION TRIM` are GNU extensions. Do not use `-std=cobol85`. Other compilers, architectures, and byte orders require fresh measurements and a separate ABI version.
- Measured ABI (runtime probe in this repository's `instructor/modules/03-bytes/M03BYTES.COB` + P1):
  - DISPLAY `PIC S9(n)` uses 1 byte per digit; `SIGN LEADING SEPARATE` adds 1 sign byte.
  - Without DISPLAY `SIGN SEPARATE`, the sign is **overpunched**: positive `0x30|digit`, negative `0x70|digit` (e.g. final byte `0x77` for `-12345.67`).
  - `COMP-3`: two digit nibbles per byte; final nibble holds sign (C positive / D negative); byte length = `ceil((N+1)/2)` for N digits. `S9(11)V99` → 13 digits + sign → 7 bytes.
  - `COMP` on this setup is **big-endian**, with length determined by value range (`S9(4)`=2B, `S9(9)`=4B, `S9(18)`=8B).
  - `COMP-5` uses native **little-endian** byte order.
- Interpret numeric values only after validating raw bytes; high-order bytes of `COMP`/`COMP-3` must **not** be scanned as ASCII.
- **Host Data Exception versus actual GnuCOBOL behavior**: COBOL specifies that arithmetic on a numeric item containing invalid digits raises a data exception; on IBM mainframes this appears as ABEND `S0C7`. In local GnuCOBOL 3.2, testing showed **no error**: storing `ABC`/`XYZ` in `PIC X`, redefining as `PIC 9`, and using `COMPUTE` returned 124/901 with RC0 (silent garbage). Therefore the course requires explicitly validating nibbles and never relying on the runtime.
- Runtime message `Warning: program compiled against libxml 212 using older 209` is local GnuCOBOL link-library noise, unrelated to business behavior. It appears in `stderr.txt` and is not asserted.

## Common record unit (03.3)

- Raw file: contiguous 7-byte records, no LF or alignment; `PIC S9(11)V99 COMP-3`, 13 digit nibbles plus sign.
- Outer boundary: file size must be a multiple of 7, or return RC8 and publish nothing. Reason: GnuCOBOL fixed-length sequential reads may silently space-pad a short `PIC X` record and return `FILE STATUS 00`; the read loop alone is insufficient.
- Nibble validation: all 13 digit nibbles must be 0–9; sign nibble must be C or D (F is not accepted in this course). **Do no decimal arithmetic before validation passes**; only compare integer nibbles first.
- Decode: first 11 digits are the integer part and final 2 digits the fractional part (the implied decimal point occupies no byte). Positive and negative zero (C/D) are both numeric zero, with different bytes but equivalent value.

## Output contract

CSV-style plain-text report, with a fixed line order:

- 03.1: `LESSON`, `ABI` (endianness), `DECL,<name>,<usage>,<digits>,<bytes>,<formula>`.
- 03.2: `LESSON`, `AMOUNT`, `HEX,<name>,<lower-hex>`, `TOTAL,<bytes>`.
- 03.3: `LESSON`, `REC,<seq>,<hex>,OK,<value>,` or `REC,<seq>,<hex>,REJECT,[INVALID],<reason>`, then three `SUMMARY` lines.

The checker compares line by line; any extra or missing line fails.

## RC and publication

| Situation | RC | Publish |
|---|---:|---|
| 03.1 / 03.2 normal | 0 | Yes |
| 03.3 all records valid | 0 | Yes |
| 03.3 contains rejections (valid input structure; parsing verdict) | 4 | Yes |
| 03.3 file length is not a multiple of 7 (structural misalignment) | 8 | No |
| Build/lock/output/validation failure | 12 | No |

## Runner and fail-closed publication

`run.sh`: validate arguments → acquire directory lock `OUT.lock` → create private `mktemp` stage → snapshot input and checksum → compile reference/student source → run in stage (`stdout`→`report.txt`, `stderr`→`stderr.txt`) → normalize RC (0/4 pass; others fail) → verify checksums and manifest → atomically publish with `mv -T -n` only after all checks pass. Any failure cleans the stage and preserves the lock explanation; no final output is created. `reset.sh` deletes output only when the file set is complete and the manifest verifies (rejecting unknown files, symlinks, or tampering).

## Relationship to the bank system

03.1/03.2 use the basic experimental amount `12345.67` and additionally demonstrate ACCOUNT v1's integer-minor-unit idea (`S9(9) COMP` stores 1234567 cents). The 7-byte Packed record in 03.3 is in the same family as module 07 L4's `S9(9)V99 COMP-3` limit field (both are Packed; validate nibbles before comparison), preparing for module 07 Packed processing and module 11 incident investigation (invalid digit/misalignment). This module introduces no new bank file contract.

## Limitations

- Tested only on Linux x86-64 / GnuCOBOL 3.2; EBCDIC, mainframe overpunch code tables, and other endianness are unverified.
- Demonstrates single-byte ASCII only; multibyte/Unicode character versus byte count is outside the module's conclusions.
