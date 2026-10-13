#!/usr/bin/env python3
"""Deterministically build module 03 raw-byte fixtures.

The record unit is a packed decimal S9(11)V99 COMP-3 amount: 13 digit
nibbles plus one sign nibble, stored as exactly 7 bytes, most significant
digit first. This generator only writes fixtures and their SHA256SUMS; the
COBOL reference under instructor/modules/03-bytes/ is compiled separately.
"""
import hashlib
from pathlib import Path

lab = Path(__file__).resolve().parents[1]
fx = lab / "fixtures"


def packed(digits: str, sign: str) -> bytes:
    """digits: exactly 13 decimal characters; sign: 'C' or 'D'."""
    assert len(digits) == 13 and digits.isdigit(), digits
    assert sign in "CD", sign
    nibbles = list(digits) + [sign]
    out = bytearray()
    for i in range(0, 14, 2):
        hi = int(nibbles[i], 16)
        lo = int(nibbles[i + 1], 16)
        out.append((hi << 4) | lo)
    assert len(out) == 7
    return bytes(out)


def amount(text: str, sign: str = "C") -> bytes:
    """text like '12345.67' -> 13 digits (11 int, 2 frac) plus sign."""
    whole, frac = text.split(".")
    digits = (whole.rjust(11, "0") + frac.ljust(2, "0"))
    return packed(digits, sign)


FIXTURES = {
    "normal/mixed-valid.dat": b"".join([
        amount("12345.67", "C"),
        amount("12345.67", "D"),
        amount("0.00", "C"),
        amount("0.00", "D"),
        amount("99999999999.99", "C"),
    ]),
    "boundary/empty.dat": b"",
    "boundary/zero-positive.dat": amount("0.00", "C"),
    "boundary/zero-negative.dat": amount("0.00", "D"),
    "boundary/max-value.dat": amount("99999999999.99", "C"),
    "invalid/bad-digit-nibble.dat": bytes.fromhex("00000a1234567c"),
    "invalid/bad-sign-nibble.dat": bytes.fromhex("0000001234567f"),
    "invalid/truncated.dat": amount("12345.67", "C")[:6],
    "invalid/trailing-byte.dat": amount("12345.67", "C") + b"\x00",
}

for name, payload in FIXTURES.items():
    path = fx / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)

lines = []
for name in sorted(FIXTURES):
    digest = hashlib.sha256((fx / name).read_bytes()).hexdigest()
    lines.append(f"{digest}  {name}")
(fx / "SHA256SUMS").write_text("\n".join(lines) + "\n")
print("wrote", len(FIXTURES), "fixtures")
