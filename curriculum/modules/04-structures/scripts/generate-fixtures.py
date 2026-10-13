#!/usr/bin/env python3
"""Deterministically build module 04 enterprise-record fixtures.

Each record is exactly 1,778 bytes (the canonical ENTERPRISE-CUSTOMER-V1
layout reused read-only from module 07). The generator knows the catalog
offsets only to place a handful of valid sentinel values; it does not compile
or run COBOL, so it cannot become the oracle for the layout check.
"""
import hashlib
from pathlib import Path

lab = Path(__file__).resolve().parents[1]
fx = lab / "fixtures"
record_len = 1778


def put(buf, offset, text):
    b = text.encode("ascii")
    buf[offset - 1:offset - 1 + len(b)] = b


def record(key, surname, klass, status, sync, risk):
    buf = bytearray(b" " * record_len)
    put(buf, 1, "001")                 # LAYOUT-VERSION
    put(buf, 4, "GCOB32BE")            # BINARY-ABI-CODE
    put(buf, 12, key)                  # CUSTOMER-ID (10 digits)
    put(buf, 22, status)               # RECORD-STATUS
    put(buf, 59, surname)              # LEGAL-SURNAME (32)
    put(buf, 460, klass)               # CUSTOMER-CLASSIFICATION
    buf[1466:1470] = risk.to_bytes(4, "big", signed=True)  # RISK-SCORE COMP
    put(buf, 1778, sync)               # SYNC-STATE
    return bytes(buf)


NORMAL = record("0000000001", "EXAMPLE", "A", "A", "I", 1234) \
    + record("0000000003", "SAMPLE", "B", "A", "I", -25)
ONE = record("0000000001", "EXAMPLE", "A", "A", "I", 1234)
BAD_VERSION = bytearray(ONE)
put(BAD_VERSION, 1, "009")
BAD_KEY = bytearray(ONE)
put(BAD_KEY, 12, "ABCDEFGHIJ")
BAD_ABI = bytearray(ONE)
put(BAD_ABI, 4, "BADABI  ")

FIXTURES = {
    "normal/enterprise-2.dat": NORMAL,
    "boundary/enterprise-empty.dat": b"",
    "boundary/enterprise-1.dat": ONE,
    "invalid/enterprise-bad-length.dat": ONE + b"\x00" * 5,
    "invalid/enterprise-bad-version.dat": bytes(BAD_VERSION),
    "invalid/enterprise-bad-key.dat": bytes(BAD_KEY),
    "invalid/enterprise-bad-abi.dat": bytes(BAD_ABI),
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
