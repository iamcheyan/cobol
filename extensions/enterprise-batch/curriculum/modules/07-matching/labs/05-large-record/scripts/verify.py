#!/usr/bin/env python3
"""Independent, streaming byte-level oracle for the COBOL candidate report.

Unlike a whole-file oracle, this generator reads the two fixed-record input
files one 1778-byte record at a time, emits the expected report to a temporary
file, then compares that file against the COBOL report in bounded chunks.
Peak memory stays proportional to a single record plus the field catalog, not
to the number of records or report size, so million-record / high-diff runs
are measured honestly through the real runner.
"""
import csv
from decimal import Decimal
import hashlib
from pathlib import Path
import sys
import tempfile

RECORD_BYTES = 1778
CHUNK = 1 << 20

lab = Path(__file__).resolve().parents[1]
old_path, new_path, report_path = map(Path, sys.argv[1:4])
fields = list(csv.DictReader((lab / "FIELD-CATALOG.csv").open()))


def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(CHUNK), b""):
            digest.update(chunk)
    return digest.hexdigest()


def records(path):
    """Yield fixed 1778-byte records without buffering the whole file."""
    with path.open("rb") as stream:
        while True:
            record = stream.read(RECORD_BYTES)
            if not record:
                return
            if len(record) != RECORD_BYTES:
                raise ValueError("partial fixed record")
            yield record


def raw(field, rec):
    start = int(field["offset_1_based"]) - 1
    return rec[start:start + int(field["length_bytes"])]


def value(field, rec):
    data = raw(field, rec)
    usage, pic = field["usage"], field["pic"]
    if usage == "DISPLAY" and pic.startswith("9("):
        return int(data.decode("ascii"))
    if usage == "COMP":
        return int.from_bytes(data, "big", signed=True)
    if usage == "COMP-3":
        nibbles = [n for byte in data for n in (byte >> 4, byte & 15)]
        sign = nibbles.pop()
        if sign not in (12, 13) or any(d > 9 for d in nibbles):
            raise ValueError("invalid packed decimal")
        number = int("".join(map(str, nibbles)))
        scale = len(pic.split("V", 1)[1]) if "V" in pic else 0
        result = Decimal(number).scaleb(-scale)
        return -result if sign == 13 else result
    return data


def show(field, rec):
    data = raw(field, rec)
    if field["usage"] == "DISPLAY":
        return data.decode("ascii")
    if field["usage"] == "COMP":
        n = int.from_bytes(data, "big", signed=True)
        return ("-" if n < 0 else "+") + f"{abs(n):09d}"
    if field["usage"] == "COMP-3":
        d = value(field, rec)
        pre, _, frac = field["pic"].partition("V")
        digits = int(pre.replace("S", "").split("(")[1].split(")")[0])
        scale = len(frac)
        whole = int(abs(d) * (10 ** scale))
        rendered = f"{whole:0{digits + scale}d}"
        if scale:
            rendered = rendered[:-scale] + "." + rendered[-scale:]
        return ("-" if d < 0 else "+") + rendered
    raise ValueError(field)


def expected_lines(old_iter, new_iter, run_id):
    """Generate report lines for two ascending key streams, one record deep.

    Each FIELD/AUDIT line carries the full attribution context required by
    DESIGN.md: run id, input layout version, the old/new record sequence
    numbers, the redacted customer key, the field id and its canonical COBOL
    name, then offset/length/rule. The IGNORE-AUDIT block is emitted before the
    business-field block, exactly as the COBOL core writes it.
    """
    counts = {"matched": 0, "old_only": 0, "new_only": 0, "diff": 0,
              "norm": 0, "representation": 0, "audit": 0}
    old = next(old_iter, None)
    new = next(new_iter, None)
    old_seq = 1 if old is not None else 0
    new_seq = 1 if new is not None else 0
    while old is not None or new is not None:
        if old is None:
            key = new[11:21].decode("ascii")
            yield "NEW-ONLY,******" + key[-4:]
            counts["new_only"] += 1
            new = next(new_iter, None)
            new_seq += 1
            continue
        if new is None:
            key = old[11:21].decode("ascii")
            yield "OLD-ONLY,******" + key[-4:]
            counts["old_only"] += 1
            old = next(old_iter, None)
            old_seq += 1
            continue
        old_key, new_key = old[11:21], new[11:21]
        if old_key < new_key:
            yield "OLD-ONLY,******" + old_key.decode("ascii")[-4:]
            counts["old_only"] += 1
            old = next(old_iter, None)
            old_seq += 1
            continue
        if old_key > new_key:
            yield "NEW-ONLY,******" + new_key.decode("ascii")[-4:]
            counts["new_only"] += 1
            new = next(new_iter, None)
            new_seq += 1
            continue
        counts["matched"] += 1
        ctx = (f",{run_id},{old[0:3].decode('ascii')},{old_seq:09d},"
               f"{new_seq:09d},******{old_key.decode('ascii')[-4:]}")
        for f in fields:
            if f["comparison_rule"] != "IGNORE-AUDIT":
                continue
            if raw(f, old) != raw(f, new):
                counts["audit"] += 1
                yield (f"AUDIT{ctx},{f['field_id']},{f['cobol_name']},"
                       f"{f['offset_1_based']},{f['length_bytes']},IGNORE-AUDIT")
        for f in fields:
            rule = f["comparison_rule"]
            if rule == "IGNORE-AUDIT":
                continue
            a, b = raw(f, old), raw(f, new)
            if rule == "TEXT-NORM":
                av = a.decode("ascii").upper().rstrip(" ")
                bv = b.decode("ascii").upper().rstrip(" ")
                if a != b and av == bv:
                    counts["norm"] += 1
                changed = av != bv
            elif rule == "NUMERIC":
                av, bv = value(f, old), value(f, new)
                if a != b and av == bv:
                    counts["representation"] += 1
                changed = av != bv
            else:
                changed = a != b
            if changed:
                counts["diff"] += 1
                head = (f"FIELD{ctx},{f['field_id']},{f['cobol_name']},"
                        f"{f['offset_1_based']},{f['length_bytes']},{rule}")
                if f["sensitivity"] in ("PII", "CONFIDENTIAL"):
                    yield head + ",[REDACTED]"
                else:
                    yield head
                    yield "OLD|" + show(f, old)
                    yield "NEW|" + show(f, new)
        old = next(old_iter, None)
        old_seq += 1
        new = next(new_iter, None)
        new_seq += 1
    yield f"SUMMARY,OLD-RECORDS,{counts['old_only'] + counts['matched']:09d}"
    yield f"SUMMARY,NEW-RECORDS,{counts['new_only'] + counts['matched']:09d}"
    for label, key in (("MATCHED", "matched"), ("OLD-ONLY", "old_only"),
                       ("NEW-ONLY", "new_only"),
                       ("FIELD-DIFFERENCES", "diff"),
                       ("NORMALIZED-EQUAL", "norm"),
                       ("NUMERIC-REPRESENTATION-EQUAL", "representation"),
                       ("AUDIT-ONLY", "audit")):
        yield f"SUMMARY,{label},{counts[key]:09d}"
    yield {"__counts__": counts}


def body_writer(destination):
    """Return an emit(line) helper writing LF lines and harvesting counts."""
    state = {"counts": None}

    def emit(line):
        if isinstance(line, dict):
            state["counts"] = line["__counts__"]
            return
        destination.write(line.encode("ascii"))
        destination.write(b"\n")

    return emit, state


def streams_equal(left_path, right_path):
    with left_path.open("rb") as left, right_path.open("rb") as right:
        while True:
            a = left.read(CHUNK)
            b = right.read(CHUNK)
            if a != b:
                return False
            if not a:
                return True


def main():
    run_id = hashlib.sha256(
        (sha256_file(old_path) + "  old.dat\n" +
         sha256_file(new_path) + "  new.dat\n").encode("ascii")).hexdigest()[:16]
    with tempfile.NamedTemporaryFile() as generated:
        generated.write(f"RUN,{run_id}\n".encode("ascii"))
        emit, state = body_writer(generated)
        for line in expected_lines(records(old_path), records(new_path), run_id):
            emit(line)
        generated.flush()
        if not streams_equal(Path(generated.name), report_path):
            print("B04 independent report mismatch", file=sys.stderr)
            raise SystemExit(12)
    print("PASS: independent 175-field streaming byte oracle", state["counts"])


if __name__ == "__main__":
    main()
