#!/usr/bin/env python3
"""Deterministically generate fixed-width teaching records from field metadata."""
import csv
import re
from pathlib import Path

lab = Path(__file__).resolve().parents[1]
fields = list(csv.DictReader((lab / "FIELD-CATALOG.csv").open()))

def packed_zero(length):
    return bytes([0x00] * (length - 1) + [0x0C])

def base(key, rev=1):
    data = bytearray(b" " * 1778)
    for f in fields:
        start, size = int(f["offset_1_based"])-1, int(f["length_bytes"])
        pic, usage, name = f["pic"], f["usage"], f["cobol_name"]
        if usage == "COMP-3": value = packed_zero(size)
        elif usage == "COMP": value = (0).to_bytes(size, "big", signed=True)
        elif pic.startswith("9("): value = b"0" * size
        else: value = b"A" * size
        data[start:start+size] = value
    def put(name, value):
        f = next(x for x in fields if x["cobol_name"] == name)
        start, size = int(f["offset_1_based"])-1, int(f["length_bytes"])
        b = value.encode("ascii")
        assert len(b) == size, (name, len(b), size)
        data[start:start+size] = b
    for f in fields:
        if f["usage"] != "DISPLAY" or not f["pic"].startswith("X("):
            continue
        codes=[]
        for part in re.split(r",|;|\bor\b", f["valid_range"]):
            match=re.match(r"\s*([A-Z0-9]{1,6})(?=\s|$)", part)
            if match:
                codes.append(match.group(1))
        if len(codes) > 1:
            put(f["cobol_name"], codes[0].ljust(int(f["length_bytes"])))
    put("LAYOUT_VERSION", "001")
    put("BINARY_ABI_CODE", "GCOB32BE")
    put("CUSTOMER_ID", key)
    put("REVISION_NO", f"{rev:04d}")
    put("CUSTOMER_CLASSIFICATION", "A")
    put("CUSTOMER_RISK_GRADE", "01")
    put("HOME_BRANCH_ID", "000001")
    put("SERVICING_BRANCH_ID", "000001")
    put("PREFECTURE_CODE", "JP01")
    put("CITY_CODE", "JPC001")
    put("POSTAL_CODE", "100-0001".ljust(10))
    put("ID_DOCUMENT_MASKED", "ABCD".ljust(24))
    put("PRIMARY_ACCOUNT_MASKED", "****000000000000")
    put("EMAIL_ADDRESS", "USER@EXAMPLE.COM".ljust(64))
    for name in ("PRIMARY_PHONE_COUNTRY", "PRIMARY_PHONE_AREA",
                 "PRIMARY_PHONE_NUMBER", "SECONDARY_PHONE_COUNTRY",
                 "SECONDARY_PHONE_AREA", "SECONDARY_PHONE_NUMBER",
                 "FAX_COUNTRY", "FAX_NUMBER", "CONTACT_TIME_FROM",
                 "CONTACT_TIME_TO", "EMERGENCY_PHONE", "POST_OFFICE_BOX"):
        put(name, " " * int(next(f["length_bytes"] for f in fields
                                  if f["cobol_name"] == name)))
    put("RECORD_STATUS", "A")
    put("EFFECTIVE_DATE", "20261010")
    for f in fields:
        if "Gregorian YYYYMMDD" in f["valid_range"] and f["pic"] == "X(8)":
            put(f["cobol_name"], "20261010")
        if "TIMESTAMP" in f["cobol_name"] and f["pic"] == "X(14)":
            put(f["cobol_name"], "20261010120000")
    return data

old = [base("0000000001"), base("0000000003")]
new = [base("0000000001",2), base("0000000002"), base("0000000003")]
# Name change and a distinct classification change are deterministic byte edits.
def setvalue(data, field, text):
    f=next(x for x in fields if x["cobol_name"]==field)
    pos=int(f["offset_1_based"])-1
    b=text.encode("ascii")
    data[pos:pos+len(b)]=b
setvalue(new[0], "LEGAL_SURNAME", "EXAMPLE")
setvalue(new[0], "CUSTOMER_CLASSIFICATION", "B")
for name, records in (("old", old), ("new", new)):
    (lab/"fixtures"/(name+".dat")).write_bytes(b"".join(records))
