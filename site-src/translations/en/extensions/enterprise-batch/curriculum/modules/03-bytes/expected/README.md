# Module 03 Expected Results and Independent Calculation

All expected results are calculated first by an **independent reference model**, then compared with the compiled COBOL output; program output is not saved as the answer. The reference model is in [../scripts/verify.py](../scripts/verify.py) (Python, called by `run.sh` before release); the test entry point [../scripts/check.py](../scripts/check.py) reuses the same model; the COBOL implementation is `instructor/modules/03-bytes/M03BYTES.COB`.

## 03.1 Declared Digits and ABI

| Name | USAGE | Logical digit count | Bytes | Basis |
|---|---|---:|---:|---|
| AMT-DISPLAY | DISPLAY | 7 | 7 | 1 byte per digit |
| AMT-SIGN-SEP | SIGN LEADING SEPARATE | 7 | 8 | digits + 1 separate sign byte |
| AMT-PACKED | COMP-3 | 7 | 4 | ceil((7+1)/2) |
| AMT-PACKED-BIG | COMP-3 | 13 | 7 | ceil((13+1)/2) |
| AMT-BINARY-4 | COMP | 4 | 2 | range S9(4) |
| AMT-BINARY-9 | COMP | 9 | 4 | range S9(9) |
| AMT-BINARY-18 | COMP | 18 | 8 | range S9(18) |

Byte order: storing `16909060 = 0x01020304` in `S9(9) COMP` yields `01 02 03 04` (big-endian); storing it in `S9(9) COMP-5` yields `04 03 02 01` (native little-endian on x86-64).

## 03.2 Raw Bytes for the Same Amount, 12345.67

| Field | Value | Raw bytes | Description |
|---|---|---|---|
| AMT-DISPLAY | +12345.67 | `31323334353637` | ASCII `1234567`, implied decimal, positive sign = overpunch `0x30` |
| AMT-SIGN-SEP | +12345.67 | `2b31323334353637` | leading separate `+` |
| AMT-DISPLAY-NEG | -12345.67 | `31323334353677` | last byte `0x77`=`0x70|7` negative overpunch |
| AMT-SIGN-SEP-NEG | -12345.67 | `2d31323334353637` | leading separate `-` |
| AMT-PACKED-POS | +12345.67 | `1234567c` | 7 digits + C sign |
| AMT-PACKED-NEG | -12345.67 | `1234567d` | 7 digits + D sign |
| AMT-PACKED-BIG | +12345.67 | `0000001234567c` | 13 digits + C, 7 bytes |
| AMT-BINARY-4 | +1234 | `04d2` | 0x04D2=1234, big-endian |
| AMT-COMP-MINOR | +1234567 | `0012d687` | 0x12D687=1234567, integer “cents” |
| AMT-BINARY-18 | +123456789012345 | `00007048860ddf79` | 8 bytes, big-endian |

`amounts.bin` = the 10 fields above concatenated in order, 59 bytes total.

## 03.3 Packed-Decimal Parsing

Reference model: each 7-byte record → 14 nibbles; the first 13 are digits (must be 0–9), and the final nibble is the sign (C/D); decode as `<sign><11-digit integer>.<2 decimal places>`.

| Fixture | Raw bytes | Result |
|---|---|---|
| `normal/mixed-valid.dat` | 5 positive/negative/±zero/maximum records | all OK, RC0 |
| `boundary/empty.dat` | 0 bytes | TOTAL=0, RC0 |
| `boundary/zero-positive.dat` | `0000000000000c` | `+00000000000.00` |
| `boundary/zero-negative.dat` | `0000000000000d` | `-00000000000.00` (numeric value is 0) |
| `boundary/max-value.dat` | `9999999999999c` | `+99999999999.99` |
| `invalid/bad-digit-nibble.dat` | `00000a1234567c` | REJECT `DIGIT-NOT-0-9`, RC4 |
| `invalid/bad-sign-nibble.dat` | `0000001234567f` | REJECT `BAD-SIGN-NIBBLE`, RC4 |
| `invalid/truncated.dat` | 6 bytes | RC8, publish nothing (length is not a multiple of 7) |
| `invalid/trailing-byte.dat` | 8 bytes | RC8, publish nothing |
