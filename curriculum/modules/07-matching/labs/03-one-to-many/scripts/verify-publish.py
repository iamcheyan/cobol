#!/usr/bin/env python3
"""Streaming publish-integrity gate; never implements matching or balances."""
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


def record(stream, width: int, name: str) -> bytes | None:
    value = read_line(stream, name, width + 2)
    if value is not None and len(value) != width:
        raise ValueError(f"record width mismatch in {name}")
    return value


def count_field(fields: list[str], name: str) -> int:
    for item in fields:
        key, sep, value = item.partition("=")
        if key == name and sep and value.isascii() and value.isdigit():
            return int(value)
    raise ValueError(f"missing/malformed count {name}")


def amount_field(fields: list[str], name: str, digits: int,
                 signed: bool = False) -> int:
    pattern = rf"[+-][0-9]{{{digits}}}" if signed else rf"[0-9]{{{digits}}}"
    for item in fields:
        key, sep, value = item.partition("=")
        if key == name and sep and re.fullmatch(pattern, value):
            if signed:
                return (-1 if value[0] == "-" else 1) * int(value[1:])
            return int(value)
    raise ValueError(f"missing/malformed amount {name}")


def signed_value(value: str, digits: int) -> int:
    if not re.fullmatch(rf"[+-][0-9]{{{digits}}}", value):
        raise ValueError("malformed signed amount")
    return (-1 if value[0] == "-" else 1) * int(value[1:])


def verify(account_path: Path, tx_path: Path, report_path: Path,
           master_path: Path, accept_path: Path, reject_path: Path) -> None:
    with (account_path.open("rb") as masters,
          tx_path.open("rb") as transactions,
          report_path.open("rb") as report,
          master_path.open("rb") as master_output,
          accept_path.open("rb") as accept_output,
          reject_path.open("rb") as reject_output):
        current_group: str | None = None
        group_tx = group_accept = group_reject = 0
        group_credit = group_debit = 0
        accounts = no_tx = total_tx = accepted = rejected = 0
        total_opening = total_closing = total_credit = total_debit = 0
        pending_account: str | None = None
        pending_opening = pending_closing = 0
        final_control: list[str] | None = None

        while True:
            raw = read_line(report, "report")
            if raw is None:
                break
            try:
                text = raw.decode("ascii")
            except UnicodeError as error:
                raise ValueError("report is not ASCII") from error

            if text.startswith("TX|"):
                if pending_account is not None:
                    raise ValueError("TX appears between ACCOUNT and its control")
                parts = text.split("|", 3)
                if len(parts) != 4 or not re.fullmatch(r"[A-Z0-9]{16}", parts[1]):
                    raise ValueError("malformed TX report line")
                raw_tx = record(transactions, 55, "transaction input")
                if raw_tx is None or raw_tx[10:26].decode("ascii") != parts[1]:
                    raise ValueError("TX report does not match input order")
                account_id = raw_tx[:10].decode("ascii")
                if current_group is not None and account_id < current_group:
                    raise ValueError("transaction input is not sorted")
                if account_id != current_group:
                    current_group = account_id
                    group_tx = group_accept = group_reject = 0
                    group_credit = group_debit = 0
                group_tx += 1
                total_tx += 1
                amount = int(raw_tx[41:54])
                if parts[2] == "ACCEPT":
                    if not re.fullmatch(r"[+-][0-9]{13}", parts[3]):
                        raise ValueError("bad accepted balance format")
                    if record(accept_output, 55, "accepted output") != raw_tx:
                        raise ValueError("accepted output differs from original TX")
                    if raw_tx[40:41] == b"C":
                        group_credit += amount
                        total_credit += amount
                    elif raw_tx[40:41] == b"D":
                        group_debit += amount
                        total_debit += amount
                    else:
                        raise ValueError("invalid accepted direction")
                    group_accept += 1
                    accepted += 1
                elif parts[2] == "REJECT" and parts[3]:
                    rejected_raw = read_line(reject_output, "rejected output", 82)
                    expected = raw_tx + b"|" + parts[3].encode("ascii")
                    if rejected_raw != expected:
                        raise ValueError("rejected output differs from original TX/reason")
                    group_reject += 1
                    rejected += 1
                else:
                    raise ValueError("unknown TX disposition")
            elif text.startswith("ACCOUNT|"):
                if pending_account is not None:
                    raise ValueError("ACCOUNT missing prior control")
                parts = text.split("|")
                if (len(parts) != 3 or
                        not re.fullmatch(r"[0-9]{10}", parts[1]) or
                        not re.fullmatch(r"[+-][0-9]{13}", parts[2])):
                    raise ValueError("malformed ACCOUNT report line")
                raw_master = record(masters, 47, "master input")
                if raw_master is None or raw_master[:10].decode("ascii") != parts[1]:
                    raise ValueError("ACCOUNT report does not match master order")
                opening = int(raw_master[22:35])
                if raw_master[21:22] == b"-":
                    opening = -opening
                closing = signed_value(parts[2], 13)
                credit = group_credit if current_group == parts[1] else 0
                debit = group_debit if current_group == parts[1] else 0
                if opening + credit - debit != closing:
                    raise ValueError("account balance equation failed")
                expected_master = raw_master[:21] + parts[2].encode("ascii") + raw_master[35:]
                if record(master_output, 47, "master output") != expected_master:
                    raise ValueError("closing master differs from source plus checked balance")
                pending_account = parts[1]
                pending_opening, pending_closing = opening, closing
                total_opening += opening
                total_closing += closing
                accounts += 1
            elif text.startswith("ACCT-CONTROL|"):
                if pending_account is None:
                    raise ValueError("orphan ACCT-CONTROL")
                parts = text.split("|")
                if len(parts) != 9 or parts[1] != pending_account:
                    raise ValueError("malformed account control")
                matching_group = current_group == pending_account
                expected_counts = ((group_tx, group_accept, group_reject)
                                   if matching_group else (0, 0, 0))
                actual_counts = tuple(count_field(parts[2:5], key)
                                      for key in ("TX", "ACCEPT", "REJECT"))
                if actual_counts != expected_counts:
                    raise ValueError("account counts disagree with TX stream")
                opening = amount_field(parts[5:], "OPENING", 13, signed=True)
                closing = amount_field(parts[5:], "CLOSING", 13, signed=True)
                credit = amount_field(parts[5:], "CREDIT", 18)
                debit = amount_field(parts[5:], "DEBIT", 18)
                expected_credit = group_credit if matching_group else 0
                expected_debit = group_debit if matching_group else 0
                if (opening != pending_opening or closing != pending_closing or
                        credit != expected_credit or debit != expected_debit or
                        opening + credit - debit != closing):
                    raise ValueError("account amount controls disagree with raw transactions")
                if actual_counts[0] == 0:
                    no_tx += 1
                if matching_group:
                    current_group = None
                    group_tx = group_accept = group_reject = 0
                    group_credit = group_debit = 0
                pending_account = None
            elif text.startswith("CONTROL|"):
                if pending_account is not None or final_control is not None:
                    raise ValueError("misplaced or duplicate CONTROL")
                final_control = text.split("|")
                if read_line(report, "report") is not None:
                    raise ValueError("CONTROL is not final report row")
                break
            else:
                raise ValueError("unknown report row")

        if final_control is None:
            raise ValueError("missing CONTROL")
        if (record(transactions, 55, "transaction input") is not None or
                record(masters, 47, "master input") is not None or
                record(master_output, 47, "master output") is not None or
                record(accept_output, 55, "accepted output") is not None or
                read_line(reject_output, "rejected output", 82) is not None):
            raise ValueError("unmatched input or extra output record")
        control = final_control[1:]
        expected_counts = (accounts, no_tx, total_tx, accepted, rejected)
        actual_counts = tuple(count_field(control, name) for name in
                              ("ACCOUNTS", "NO-TX", "TX", "ACCEPT", "REJECT"))
        if actual_counts != expected_counts:
            raise ValueError("global control counts disagree with streams")
        control_opening = amount_field(control, "OPENING", 18, signed=True)
        control_closing = amount_field(control, "CLOSING", 18, signed=True)
        control_credit = amount_field(control, "CREDIT", 18)
        control_debit = amount_field(control, "DEBIT", 18)
        if (control_opening != total_opening or control_closing != total_closing or
                control_credit != total_credit or control_debit != total_debit or
                control_opening + control_credit - control_debit != control_closing):
            raise ValueError("global amount controls disagree with streams")


def main() -> int:
    try:
        if len(sys.argv) != 7:
            raise ValueError("expected account tx report master accepted rejected")
        verify(*(Path(value) for value in sys.argv[1:]))
    except (OSError, ValueError, UnicodeError) as error:
        print(f"publish verification failed: {error}", file=sys.stderr)
        return 12
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
