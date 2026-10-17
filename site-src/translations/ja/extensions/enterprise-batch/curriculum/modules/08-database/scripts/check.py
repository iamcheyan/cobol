#!/usr/bin/env python3
"""モジュール08のオフライン契約検査（Dockerやデータベースは不要）。

覆盖：
  1. 固定格式：无 TAB、无 CR、末尾有 LF、有效代码不超过第 72 列、
     代码不早于第 7 列、语句关键字不早于 Area B（第 12 列）。
  2. 冻结契约字节宽度：CUSTOMER v1=27、TRANSACTION v1=55。
  3. 独立核算 oracle：从 db/seed.sql 与 fixtures 重新推导
     - 007 日客户快照 27B 是否等于 expected/snapshot-20261009.dat；
     - 应用交易后的账户余额是否等于 expected/db-after-first.txt。
     该 oracle 不使用任何 COBOL 程序输出，因此能独立发现“RC0 但金额错误”。
  4. P1 两个补丁存在且被 db/Dockerfile 引用（依赖补丁回归前置条件）。
  5. SHA256SUMS 校验 fixtures/expected 等。
"""
from __future__ import annotations
import hashlib
import re
import subprocess
import sys
from pathlib import Path

LAB = Path(__file__).resolve().parents[1]
REPO = LAB.parents[2]
P1 = REPO / "curriculum/validation/database"

STMT_KEYWORDS = (
    "MOVE", "PERFORM", "IF", "ELSE", "END-IF", "EVALUATE", "WHEN",
    "ADD", "SUBTRACT", "COMPUTE", "OPEN", "CLOSE", "READ", "WRITE",
    "REWRITE", "DELETE", "STRING", "UNSTRING", "INSPECT", "DISPLAY",
    "ACCEPT", "GOBACK", "STOP", "EXIT", "END-PERFORM", "END-EVALUATE",
    "END-READ", "END-STRING", "ROLLBACK", "COMMIT", "CONTINUE",
)
AREA_A = (
    "IDENTIFICATION", "PROGRAM-ID", "ENVIRONMENT", "DATA", "WORKING-STORAGE",
    "FILE", "FILE-CONTROL", "INPUT-OUTPUT", "PROCEDURE", "FD", "01", "77", "78",
)


def die(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(1)


def check_fixed(path: Path) -> None:
    raw = path.read_bytes()
    if b"\r" in raw:
        die(f"{path.name}: contains CR (must be LF)")
    if not raw.endswith(b"\n"):
        die(f"{path.name}: missing final LF")
    for n, line in enumerate(raw.split(b"\n")[:-1], 1):
        if b"\t" in line:
            die(f"{path.name}:{n}: contains TAB")
        if len(line) > 72:
            die(f"{path.name}:{n}: code beyond column 72 ({len(line)} bytes)")
        stripped = line.lstrip(b" ")
        if not stripped:
            continue
        first = len(line) - len(stripped)
        if first < 6:
            die(f"{path.name}:{n}: code before column 7")
        if line[6:7] in (b"*", b"/"):
            continue
        text = line[7:].lstrip() if len(line) > 7 else b""
        word = text.split(b" ")[0].decode(errors="replace").upper()
        if word in STMT_KEYWORDS and first < 11:
            die(f"{path.name}:{n}: statement '{word}' not in Area B (col>=12)")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_sums() -> None:
    sums = LAB / "SHA256SUMS"
    if not sums.is_file():
        die("SHA256SUMS missing")
    result = subprocess.run(
        ["sha256sum", "-c", "SHA256SUMS"], cwd=str(LAB),
        text=True, capture_output=True)
    if result.returncode != 0:
        die(f"SHA256SUMS mismatch:\n{result.stdout}{result.stderr}")


def parse_seed_customers() -> list[tuple[str, str, int, str, str]]:
    text = (LAB / "db/seed.sql").read_text()
    rows = []
    pat = re.compile(
        r"\('(\d{8})',\s*'([^']*)',\s*(\d+),\s*'([A-Z])',\s*"
        r"(?:NULL|'[^']*'),\s*'(\d{8})'\)")
    for m in pat.finditer(text):
        rows.append((m.group(1), m.group(2), int(m.group(3)),
                     m.group(4), m.group(5)))
    if not rows:
        die("seed.sql: no customer rows parsed")
    return rows


def parse_seed_accounts() -> dict[str, int]:
    text = (LAB / "db/seed.sql").read_text()
    acct: dict[str, int] = {}
    pat = re.compile(
        r"\('(\d{10})',\s*'\d{8}',\s*'[A-Z]{3}',\s*'[+-]',\s*(\d+),")
    for m in pat.finditer(text):
        acct[m.group(1)] = int(m.group(2))
    if not acct:
        die("seed.sql: no account rows parsed")
    return acct


def read_records(path: Path, width: int) -> list[str]:
    raw = path.read_bytes()
    if not raw.endswith(b"\n"):
        die(f"{path.name}: no final LF")
    lines = raw.split(b"\n")[:-1]
    out = []
    for line in lines:
        if len(line) != width:
            die(f"{path.name}: record width {len(line)} != {width}")
        out.append(line.decode())
    return out


def oracle_snapshot() -> None:
    cid_order = lambda r: r[0]
    rows = sorted(
        (r for r in parse_seed_customers() if r[4] == "20261009"),
        key=cid_order)
    expected = "".join(
        f"{cid}{name:<10}{bal:08d}{st}\n"
        for cid, name, bal, st, _ in rows).encode()
    actual = (LAB / "expected/snapshot-20261009.dat").read_bytes()
    if actual != expected:
        die("snapshot oracle mismatch:\n"
            f"  expected={expected!r}\n  file    ={actual!r}")


def oracle_balances() -> None:
    opening = parse_seed_accounts()
    balance = dict(opening)
    for rec in read_records(LAB / "fixtures/transactions-20261009.dat", 55):
        account = rec[0:10]
        direction = rec[40:41]
        amount = int(rec[41:54])
        if account not in balance:
            die(f"transaction references unknown account {account}")
        balance[account] += amount if direction == "C" else -amount
    derived = ",".join(str(balance[k]) for k in sorted(balance))
    expected_txt = (LAB / "expected/db-after-first.txt").read_text()
    m = re.search(r"^BALANCES=(.*)$", expected_txt, re.M)
    if not m or m.group(1) != derived:
        die(f"balance oracle mismatch: derived={derived} "
            f"expected={m.group(1) if m else None}")


def check_p1_patches() -> None:
    dockerfile = (LAB / "db/Dockerfile").read_text()
    for name in ("gixsql-cursor-null.patch", "gixsql-closed-cursor.patch"):
        if name not in dockerfile:
            die(f"db/Dockerfile does not reference {name}")
        if not (P1 / name).is_file():
            die(f"P1 patch missing: {P1 / name}")


def main() -> None:
    cobols = sorted(LAB.glob("starter/*.COB")) + sorted(
        (LAB / "system").glob("*.COB"))
    instructor = REPO / "instructor/modules/08-database"
    if instructor.is_dir():
        cobols += sorted(instructor.glob("*.COB"))
    if not cobols:
        die("no COBOL sources found")
    for path in cobols:
        check_fixed(path)
    for fx in ("fixtures/customer-upstream-20261009.dat",
               "fixtures/customer-upstream-20261009-nodiff.dat"):
        read_records(LAB / fx, 27)
    read_records(LAB / "expected/snapshot-20261009.dat", 27)
    read_records(LAB / "fixtures/transactions-20261009.dat", 55)
    read_records(LAB / "fixtures/transactions-dup-in-run.dat", 55)
    oracle_snapshot()
    oracle_balances()
    check_p1_patches()
    verify_sums()
    print(f"PASS: module08 offline contracts ({len(cobols)} COBOL sources)")


if __name__ == "__main__":
    main()
