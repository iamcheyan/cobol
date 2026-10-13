#!/usr/bin/env python3
"""模块 03 独立语义核验（在 run.sh 发布前调用，不信任被测程序输出）。

对输入记录、解码值/符号、原始字节、记录数与布局做独立核验：
  * 03.1：由声明模型重算逻辑位数与物理字节，核对 report.txt 与 abi.bin 的 8 字节；
  * 03.2：由 Python 参考模型重算 10 个金额字段的原始字节，核对 report.txt 与
          amounts.bin（59 字节）；
  * 03.3：逐半字节重算输入 records 的 OK/REJECT、解码值与符号，核对 report.txt
          的每行、TOTAL/ACCEPTED/REJECTED 计数与 7 字节记录布局。
任何不符（占位报告、跳过记录、错误金额/符号、记录数或布局不符、缺文件）都失败，
调用方不发布。用法：
    verify.py LESSON OUTPUT_DIR
03.3 的输入快照读取 OUTPUT_DIR/input.dat（run.sh 已复制）。
"""
from __future__ import annotations
import sys
from pathlib import Path

EXPECTED = Path(__file__).resolve().parents[1] / "expected"


def fail(msg: str) -> None:
    print(f"FAIL: {msg}")
    sys.exit(8)


# ---- 独立参考模型 -----------------------------------------------------------
def decode(rec: bytes) -> tuple[str, str, str]:
    """7 字节 packed → (verdict, value, reason)。逐半字节，先校验后解释。"""
    nib = []
    for b in rec:
        nib += [b >> 4, b & 0x0F]
    digits, sign = nib[:13], nib[13]
    if any(d > 9 for d in digits):
        return "REJECT", "[INVALID]", "DIGIT-NOT-0-9"
    if sign not in (12, 13):
        return "REJECT", "[INVALID]", "BAD-SIGN-NIBBLE"
    s = "".join(str(d) for d in digits)
    return "OK", ("+" if sign == 12 else "-") + s[:11] + "." + s[11:], ""


def lesson3_report(payload: bytes) -> str:
    lines = ["LESSON,03.3"]
    total = accepted = rejected = 0
    for i in range(0, len(payload), 7):
        rec = payload[i:i + 7]
        total += 1
        verdict, value, why = decode(rec)
        if verdict == "OK":
            accepted += 1
            lines.append(f"REC,{total:04d},{rec.hex()},OK,{value},")
        else:
            rejected += 1
            lines.append(
                f"REC,{total:04d},{rec.hex()},REJECT,[INVALID],{why}")
    lines += [f"SUMMARY,TOTAL,{total:04d}",
              f"SUMMARY,ACCEPTED,{accepted:04d}",
              f"SUMMARY,REJECTED,{rejected:04d}"]
    return "\n".join(lines) + "\n"


def lesson2_bytes() -> bytes:
    """10 个金额字段的原始字节拼接（独立于 COBOL 实现）。"""
    disp = b"1234567"
    sep = b"+1234567"
    neg = b"123456" + bytes([0x70 | 7])          # negative overpunch 'w'
    sepneg = b"-1234567"
    packed = bytes.fromhex("1234567c")
    packneg = bytes.fromhex("1234567d")
    packbig = bytes.fromhex("0000001234567c")
    comp4 = (1234).to_bytes(2, "big")
    comp9 = (1234567).to_bytes(4, "big")
    comp18 = (123456789012345).to_bytes(8, "big")
    return disp + sep + neg + sepneg + packed + packneg + packbig + comp4 \
        + comp9 + comp18


# bytes 布局：[0:7][7:15][15:22][22:30][30:34][34:38][38:45][45:47][47:51][51:59]
_L2_SLICES = [
    ("AMT-DISPLAY", 0, 7), ("AMT-SIGN-SEP", 7, 15),
    ("AMT-DISPLAY-NEG", 15, 22), ("AMT-SIGN-SEP-NEG", 22, 30),
    ("AMT-PACKED-POS", 30, 34), ("AMT-PACKED-NEG", 34, 38),
    ("AMT-PACKED-BIG", 38, 45), ("AMT-BINARY-4", 45, 47),
    ("AMT-COMP-MINOR", 47, 51), ("AMT-BINARY-18", 51, 59),
]


def lesson2_report() -> str:
    raw = lesson2_bytes()
    lines = ["LESSON,03.2", "AMOUNT,12345.67"]
    for name, a, b in _L2_SLICES:
        lines.append(f"HEX,{name},{raw[a:b].hex()}")
    lines.append(f"TOTAL,{len(raw)}")
    return "\n".join(lines) + "\n"


def _ceil2(n: int) -> int:
    return (n + 1) // 2


# (名称, USAGE, 逻辑位数, 物理字节, 依据)
_L1_FIELDS = [
    ("AMT-DISPLAY", "DISPLAY", 7, 7, "1B/digit"),
    ("AMT-SIGN-SEP", "SIGN-LEADING-SEPARATE", 7, 8, "digits+1"),
    ("AMT-PACKED", "COMP-3", 7, _ceil2(8), "ceil((7+1)/2)"),
    ("AMT-PACKED-BIG", "COMP-3", 13, _ceil2(14), "ceil((13+1)/2)"),
    ("AMT-BINARY-4", "COMP", 4, 2, "range-fit"),
    ("AMT-BINARY-9", "COMP", 9, 4, "range-fit"),
    ("AMT-BINARY-18", "COMP", 18, 8, "range-fit"),
]


def lesson1_report() -> str:
    lines = ["LESSON,03.1", "ABI,LINUX-X86-64,GCOB32BE,DEFAULT-DIALECT"]
    for name, usage, digits, byt, why in _L1_FIELDS:
        lines.append(f"DECL,{name},{usage},{digits:02d},{byt:02d},{why}")
    lines += [
        "ABI,COMP,01020304,01020304",
        "ABI,COMP-5,NATIVE,04030201",
        "ABI,COMP-BIG-ENDIAN,YES",
        "ABI,COMP5-LITTLE-ENDIAN,YES",
    ]
    return "\n".join(lines) + "\n"


def lesson1_abi() -> bytes:
    # S9(9) COMP 大端 16909060 = 01 02 03 04；COMP-5 本机小端 = 04 03 02 01
    return bytes([1, 2, 3, 4, 4, 3, 2, 1])


def lesson2_expected_report() -> str:
    return (EXPECTED / "03.2-hexdump.txt").read_text()


def lesson1_expected_report() -> str:
    return (EXPECTED / "03.1-declare.txt").read_text()


# ---- CLI --------------------------------------------------------------------
def verify(lesson: str, outdir: Path) -> None:
    report = outdir / "report.txt"
    if not report.is_file():
        fail(f"report.txt missing in {outdir}")
    text = report.read_text()

    if lesson == "03.1":
        if text != lesson1_report():
            fail(f"03.1 report mismatch\n--- got ---\n{text}"
                 f"--- want ---\n{lesson1_report()}")
        if text != lesson1_expected_report():
            fail("03.1 report differs from committed expected")
        abi = outdir / "abi.bin"
        if not abi.is_file():
            fail("03.1 abi.bin missing")
        raw = abi.read_bytes()
        if raw != lesson1_abi():
            fail(f"03.1 abi.bin bytes {raw.hex()} != {lesson1_abi().hex()}")
    elif lesson == "03.2":
        if text != lesson2_report():
            fail(f"03.2 report mismatch\n--- got ---\n{text}"
                 f"--- want ---\n{lesson2_report()}")
        if text != lesson2_expected_report():
            fail("03.2 report differs from committed expected")
        amt = outdir / "amounts.bin"
        if not amt.is_file():
            fail("03.2 amounts.bin missing")
        raw = amt.read_bytes()
        if raw != lesson2_bytes():
            fail(f"03.2 amounts.bin {raw.hex()} != {lesson2_bytes().hex()}")
        if len(raw) != 59:
            fail(f"03.2 amounts.bin length {len(raw)} != 59")
    elif lesson == "03.3":
        inp = outdir / "input.dat"
        if not inp.is_file():
            fail("03.3 input.dat snapshot missing")
        payload = inp.read_bytes()
        if len(payload) % 7:
            fail(f"03.3 input length {len(payload)} not a multiple of 7")
        if text != lesson3_report(payload):
            fail("03.3 report mismatch (records/values/signs/counts)\n"
                 f"--- got ---\n{text}--- want ---\n{lesson3_report(payload)}")
    else:
        fail(f"unknown lesson {lesson}")


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: verify.py LESSON OUTPUT_DIR", file=sys.stderr)
        sys.exit(12)
    verify(sys.argv[1], Path(sys.argv[2]))
    print("PASS: module03 independent semantic verification")


if __name__ == "__main__":
    main()
