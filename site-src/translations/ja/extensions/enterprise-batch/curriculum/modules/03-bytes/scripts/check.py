#!/usr/bin/env python3
"""モジュール03（バイト / ABI / Packed Decimal）の独立検査プログラム。

COBOL の出力を信用せず、Python 参照モデルで各 hex 文字列と Packed Decimal の判定を
基本原理から再計算し、コンパイル済み GnuCOBOL プログラムのレポートを再計算値および
コミット済み expected/ ファイルの両方と比較します。
"""
from pathlib import Path
import os
import subprocess
import sys
import tempfile

lab = Path(__file__).resolve().parents[1]
repo = lab.parents[2]
INSTRUCTOR = repo / "instructor/modules/03-bytes"
starter = lab / "starter/M03BYTES.COB"


def reference_source() -> Path:
    """The completed exercise source: an explicit COURSE_SOURCE wins, else the
    instructor reference when present (authoring repo), else the learner's own
    starter (student bundle; completed by the learner)."""
    env = os.environ.get("COURSE_SOURCE")
    if env:
        return Path(env)
    if (INSTRUCTOR / "M03BYTES.COB").is_file():
        return INSTRUCTOR / "M03BYTES.COB"
    return starter


source = reference_source()
fixtures = lab / "fixtures"
expected = lab / "expected"
run = lab / "scripts/run.sh"


def check_format(paths):
    for path in paths:
        for n, line in enumerate(path.read_bytes().splitlines(), 1):
            assert line.isascii(), (path, n, "non-ASCII")
            assert b"\t" not in line, (path, n, "tab")
            assert len(line) <= 72, (path, n, "beyond column 72")


# ---- 独立参照モデル（run.sh の検証プログラムと共有） ----------------------
sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify import lesson2_bytes, lesson3_report  # noqa: E402


# ---- static checks ---------------------------------------------------------
check_format([source, starter])
assert source.read_bytes().splitlines()[:1], "source empty"

sums = subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=fixtures,
                      capture_output=True, text=True)
assert sums.returncode == 0, sums.stderr

# COMP-3 is a GnuCOBOL extension; strict COBOL-85 must reject the source.
# This is the module's documented, reproducible compile fault.
strict = subprocess.run(
    ["cobc", "-std=cobol85", "-fsyntax-only", str(source)],
    capture_output=True, text=True)
assert strict.returncode != 0, "strict -std=cobol85 unexpectedly accepted"

# ---- 実行時検査：lesson 1 --------------------------------------------------
with tempfile.TemporaryDirectory(prefix="m03-check-") as td:
    root = Path(td)
    out = root / "l1"
    result = subprocess.run(["bash", str(run), "03.1", str(out)],
                            capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stderr)
    report = (out / "report.txt").read_text()
    assert report == (expected / "03.1-declare.txt").read_text(), report
    assert (out / "abi.bin").read_bytes() == bytes.fromhex("0102030404030201")

    # ---- 実行時検査：lesson 2 --------------------------------------------------
    out = root / "l2"
    result = subprocess.run(["bash", str(run), "03.2", str(out)],
                            capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stderr)
    report = (out / "report.txt").read_text()
    assert report == (expected / "03.2-hexdump.txt").read_text(), report
    assert (out / "amounts.bin").read_bytes() == lesson2_bytes()

    # ---- 実行時検査：lesson 3 --------------------------------------------------
    cases = [
        ("normal/mixed-valid.dat", "03.3-mixed-valid.txt", 0),
        ("boundary/empty.dat", "03.3-empty.txt", 0),
        ("boundary/zero-positive.dat", "03.3-zero-positive.txt", 0),
        ("boundary/zero-negative.dat", "03.3-zero-negative.txt", 0),
        ("boundary/max-value.dat", "03.3-max-value.txt", 0),
        ("invalid/bad-digit-nibble.dat", "03.3-bad-digit-nibble.txt", 4),
        ("invalid/bad-sign-nibble.dat", "03.3-bad-sign-nibble.txt", 4),
    ]
    for name, exp, want_rc in cases:
        payload = (fixtures / name).read_bytes()
        out = root / ("l3-" + Path(name).name)
        result = subprocess.run(
            ["bash", str(run), "03.3", str(out), str(fixtures / name)],
            capture_output=True, text=True)
        assert result.returncode == want_rc, (
            name, result.returncode, result.stderr)
        report = (out / "report.txt").read_text()
        assert report == lesson3_report(payload), (name, report)
        assert report == (expected / exp).read_text(), (name, report)

    # Structural length faults: published nothing, RC8.
    for name in ("invalid/truncated.dat", "invalid/trailing-byte.dat"):
        out = root / ("s-" + Path(name).name)
        result = subprocess.run(
            ["bash", str(run), "03.3", str(out), str(fixtures / name)],
            capture_output=True, text=True)
        assert result.returncode == 8, (name, result.returncode)
        assert not out.exists(), (name, "published on structural fault")
        assert not Path(str(out) + ".lock").exists(), (name, "lock leaked")

    # ---- starter が安全側で失敗すること（RED） -------------------------------
    # 作成者専用の不変条件です。参照実装と未変更の starter が必要です。
    # 学生用パッケージには学習者が完成させるソースが入るため、ここでは検査を省略します。
    if INSTRUCTOR.exists():
        out = root / "starter"
        result = subprocess.run(
            ["bash", str(run), "03.3", str(out),
             str(fixtures / "normal/mixed-valid.dat")],
            env=dict(os.environ, COURSE_SOURCE=str(starter)),
            capture_output=True, text=True)
        assert result.returncode == 12, (result.returncode, result.stderr)
        assert not out.exists(), "starter published output"

        # ---- R05：完了フラグ/プレースホルダー/誤バイト/レコード飛ばしを公開しない ----
        # (a) WS-EXERCISES-DONE だけを 'Y' に変更（TODO の仮レポート）→ 拒否して未公開
        flag = root / "starter-flag.COB"
        flag.write_text(starter.read_text().replace(
            "WS-EXERCISES-DONE PIC X VALUE 'N'",
            "WS-EXERCISES-DONE PIC X VALUE 'Y'"))
        assert "VALUE 'Y'" in flag.read_text()
        for lesson, extra in (("03.1", []),
                              ("03.3",
                               [str(fixtures / "normal/mixed-valid.dat")])):
            out = root / ("flag-" + lesson)
            result = subprocess.run(
                ["bash", str(run), lesson, str(out), *extra],
                env=dict(os.environ, COURSE_SOURCE=str(flag)),
                capture_output=True, text=True)
            assert result.returncode == 8, (
                "flag-only", lesson, result.returncode, result.stderr)
            assert not out.exists(), ("flag-only", lesson, "published")

    # (b) 生バイト/金額の誤り（abi.bin を変更）→ 拒否して未公開
    wr_bytes = root / "wrong-bytes.COB"
    wr_bytes.write_text(source.read_text().replace(
        "MOVE WS-ABI TO ABI-OUT",
        "MOVE X'0102030504030201' TO ABI-OUT"))
    assert "MOVE X'" in wr_bytes.read_text()
    out = root / "wrong-bytes"
    result = subprocess.run(
        ["bash", str(run), "03.1", str(out)],
        env=dict(os.environ, COURSE_SOURCE=str(wr_bytes)),
        capture_output=True, text=True)
    assert result.returncode == 8, (result.returncode, result.stderr)
    assert not out.exists(), "wrong-bytes source published"

    # (c) レコードを飛ばす（先頭だけ処理）→ 件数/内容不一致、拒否して未公開
    skip = root / "skip-records.COB"
    skip.write_text(source.read_text().replace(
        "PERFORM UNTIL WS-IN-STATUS = '10'",
        "PERFORM UNTIL WS-IN-STATUS = '10' OR WS-TOTAL >= 1"))
    assert "OR WS-TOTAL >= 1" in skip.read_text()
    out = root / "skip-records"
    result = subprocess.run(
        ["bash", str(run), "03.3", str(out),
         str(fixtures / "normal/mixed-valid.dat")],
        env=dict(os.environ, COURSE_SOURCE=str(skip)),
        capture_output=True, text=True)
    assert result.returncode == 8, (result.returncode, result.stderr)
    assert not out.exists(), "skip-records source published"

    # (d) 符号判定の誤り（有効レコードを誤拒否）→ デコード/符号不一致、拒否して未公開
    wrong_sign = root / "wrong-sign.COB"
    wrong_sign.write_text(source.read_text().replace(
        "IF WS-NIB = 12", "IF WS-NIB = 99"))
    assert "IF WS-NIB = 99" in wrong_sign.read_text()
    out = root / "wrong-sign"
    result = subprocess.run(
        ["bash", str(run), "03.3", str(out),
         str(fixtures / "normal/mixed-valid.dat")],
        env=dict(os.environ, COURSE_SOURCE=str(wrong_sign)),
        capture_output=True, text=True)
    assert result.returncode == 8, (result.returncode, result.stderr)
    assert not out.exists(), "wrong-sign source published"

    # ---- 独立検証器による新しい参照実行も成功すること -----------------------
    out = root / "verified-ref"
    result = subprocess.run(
        ["bash", str(run), "03.3", str(out),
         str(fixtures / "normal/mixed-valid.dat")],
        capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stderr)
    assert (out / "report.txt").read_text() == lesson3_report(
        (fixtures / "normal/mixed-valid.dat").read_bytes())

    # ---- パスに空白がある場合、任意の cwd -----------------------------------
    spaced = root / "dir with spaces"
    spaced.mkdir()
    dest = spaced / "out dir"
    result = subprocess.run(
        ["bash", str(run), "03.1", str(dest)], cwd=str(root),
        capture_output=True, text=True)
    assert result.returncode == 0, (result.returncode, result.stderr)
    subprocess.run(["bash", str(lab / "scripts/reset.sh"), str(dest)],
                   check=True, capture_output=True, text=True)
    assert not dest.exists()

    # ---- 上書き防止 / ロック保護 --------------------------------------------
    existing = root / "existing"
    existing.mkdir()
    (existing / "keep.txt").write_text("preserve\n")
    refused = subprocess.run(["bash", str(run), "03.1", str(existing)],
                             capture_output=True, text=True)
    assert refused.returncode == 12
    assert (existing / "keep.txt").read_text() == "preserve\n"

    locked = root / "locked"
    Path(str(locked) + ".lock").mkdir()
    locked_run = subprocess.run(["bash", str(run), "03.1", str(locked)],
                                capture_output=True, text=True)
    assert locked_run.returncode == 12 and not locked.exists()

print("PASS: module 03 declarations, raw bytes, packed parse and fail-closed")
