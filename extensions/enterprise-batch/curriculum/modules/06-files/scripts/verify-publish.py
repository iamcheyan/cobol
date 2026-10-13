#!/usr/bin/env python3
"""Streaming publish-integrity gate for module 06; verifies only that the
report, accepted/rejected files and control totals are mutually consistent
and LF-terminated (no business rules are re-implemented here)."""
from pathlib import Path
import re
import sys


def read_line(stream, name: str, maximum: int = 256) -> bytes | None:
    raw = stream.readline(maximum)
    if raw == b"":
        return None
    if len(raw) == maximum or not raw.endswith(b"\n") or raw.endswith(b"\r\n"):
        raise ValueError(f"missing LF, CRLF, or oversized line in {name}")
    return raw[:-1]


def count_field(fields: list[str], name: str) -> int:
    for item in fields:
        key, sep, value = item.partition("=")
        if key == name and sep and value.isascii() and value.isdigit():
            return int(value)
    raise ValueError(f"missing/malformed count {name}")


def signed_field(fields: list[str], name: str, digits: int) -> int:
    for item in fields:
        key, sep, value = item.partition("=")
        if key == name and sep and re.fullmatch(
                rf"[+-][0-9]{{{digits}}}", value):
            return (-1 if value[0] == "-" else 1) * int(value[1:])
    raise ValueError(f"missing/malformed amount {name}")


def verify(input_path: Path, report_path: Path, accept_path: Path,
           reject_path: Path) -> None:
    if not input_path.is_file():
        raise ValueError("input snapshot missing")
    with (report_path.open("rb") as report,
          accept_path.open("rb") as accepted,
          reject_path.open("rb") as rejected):
        read_total = accept_total = reject_total = balance_total = 0
        control: list[str] | None = None

        while True:
            raw = read_line(report, "report")
            if raw is None:
                break
            text = raw.decode("ascii")
            if text.startswith("CONTROL|"):
                if control is not None:
                    raise ValueError("duplicate CONTROL row")
                control = text.split("|")
                if read_line(report, "report") is not None:
                    raise ValueError("CONTROL is not the final report row")
                break
            if not text.startswith("ACCT|"):
                raise ValueError("unknown report row")
            parts = text.split("|")
            read_total += 1
            identifier = parts[1]
            if len(identifier) != 10:
                raise ValueError("malformed account id in report")
            if parts[2] == "ACCEPT":
                if len(parts) != 5 or parts[3] not in ("A", "C", "F"):
                    raise ValueError("malformed ACCEPT report row")
                if not re.fullmatch(r"[+-][0-9]{18}", parts[4]):
                    raise ValueError("malformed accepted balance")
                record = read_line(accepted, "accepted output")
                if record is None or len(record) != 47:
                    raise ValueError("accepted record width mismatch")
                if record[:10].decode("ascii") != identifier:
                    raise ValueError("accepted id disagrees with report")
                if record[35:36].decode("ascii") != parts[3]:
                    raise ValueError("accepted status disagrees with report")
                accept_total += 1
                balance_total += (-1 if parts[4][0] == "-" else 1) * \
                    int(parts[4][1:])
            elif parts[2] == "REJECT":
                if len(parts) != 4 or not re.fullmatch(r"[A-Z][A-Z-]+",
                                                       parts[3]):
                    raise ValueError("malformed REJECT report row")
                record = read_line(rejected, "rejected output", 128)
                if record is None or len(record) < 49:
                    raise ValueError("rejected record too short")
                if record[:10].decode("ascii") != identifier:
                    raise ValueError("rejected id disagrees with report")
                if record[47:48] != b"|":
                    raise ValueError("rejected record missing separator")
                if record[48:].decode("ascii") != parts[3]:
                    raise ValueError("rejected reason disagrees with report")
                reject_total += 1
            else:
                raise ValueError("unknown disposition")

        if control is None:
            raise ValueError("missing CONTROL row")
        if (read_line(accepted, "accepted output") is not None or
                read_line(rejected, "rejected output", 128) is not None):
            raise ValueError("extra accepted/rejected record")
        if len(control) != 6:
            raise ValueError("malformed CONTROL row")
        date_key, date_sep, date_value = control[1].partition("=")
        if date_key != "BUSINESS-DATE" or not date_sep or \
                not re.fullmatch(r"[0-9]{8}", date_value):
            raise ValueError("malformed CONTROL business date")
        if (count_field(control, "READ") != read_total or
                count_field(control, "ACCEPT") != accept_total or
                count_field(control, "REJECT") != reject_total):
            raise ValueError("control counts disagree with report stream")
        if signed_field(control, "BALANCE", 18) != balance_total:
            raise ValueError("control balance disagrees with accepted rows")
        if read_total != accept_total + reject_total:
            raise ValueError("read = accept + reject conservation failed")


def main() -> int:
    try:
        if len(sys.argv) != 5:
            raise ValueError("expected input report accepted rejected")
        verify(*(Path(value) for value in sys.argv[1:]))
    except (OSError, ValueError, UnicodeError) as error:
        print(f"publish verification failed: {error}", file=sys.stderr)
        return 12
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
