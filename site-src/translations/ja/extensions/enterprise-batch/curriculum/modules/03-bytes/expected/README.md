# モジュール 03 の期待結果と独立した計算

すべての期待結果は、まず**独立した参照モデル**で計算し、コンパイル済み COBOL の出力と比較します。プログラムの出力を答えとして保存することはありません。参照モデルは [../scripts/verify.py](../scripts/verify.py) にあります（Python、リリース前に `run.sh` から呼び出されます）。テストのエントリーポイント [../scripts/check.py](../scripts/check.py) も同じモデルを再利用します。COBOL の実装は `instructor/modules/03-bytes/M03BYTES.COB` です。

## 03.1 宣言した桁数と ABI

| 名前 | USAGE | 論理桁数 | バイト数 | 根拠 |
|---|---|---:|---:|---|
| AMT-DISPLAY | DISPLAY | 7 | 7 | 1 桁につき 1 バイト |
| AMT-SIGN-SEP | SIGN LEADING SEPARATE | 7 | 8 | 数字 + 独立した符号 1 バイト |
| AMT-PACKED | COMP-3 | 7 | 4 | ceil((7+1)/2) |
| AMT-PACKED-BIG | COMP-3 | 13 | 7 | ceil((13+1)/2) |
| AMT-BINARY-4 | COMP | 4 | 2 | 値域 S9(4) |
| AMT-BINARY-9 | COMP | 9 | 4 | 値域 S9(9) |
| AMT-BINARY-18 | COMP | 18 | 8 | 値域 S9(18) |

バイト順：`16909060 = 0x01020304` を `S9(9) COMP` に格納すると `01 02 03 04`（ビッグエンディアン）になります。`S9(9) COMP-5` に格納すると `04 03 02 01`（x86-64 のネイティブなリトルエンディアン）になります。

## 03.2 同じ金額 12345.67 の生バイト

| フィールド | 値 | 生バイト | 説明 |
|---|---|---|---|
| AMT-DISPLAY | +12345.67 | `31323334353637` | ASCII `1234567`、小数点は暗黙、正符号 = オーバーパンチ `0x30` |
| AMT-SIGN-SEP | +12345.67 | `2b31323334353637` | 先頭に独立した `+` |
| AMT-DISPLAY-NEG | -12345.67 | `31323334353677` | 最終バイト `0x77`=`0x70|7` は負数のオーバーパンチ |
| AMT-SIGN-SEP-NEG | -12345.67 | `2d31323334353637` | 先頭に独立した `-` |
| AMT-PACKED-POS | +12345.67 | `1234567c` | 7 桁 + C 符号 |
| AMT-PACKED-NEG | -12345.67 | `1234567d` | 7 桁 + D 符号 |
| AMT-PACKED-BIG | +12345.67 | `0000001234567c` | 13 桁 + C、7 バイト |
| AMT-BINARY-4 | +1234 | `04d2` | 0x04D2=1234、ビッグエンディアン |
| AMT-COMP-MINOR | +1234567 | `0012d687` | 0x12D687=1234567、整数の「セント」 |
| AMT-BINARY-18 | +123456789012345 | `00007048860ddf79` | ビッグエンディアンの 8 バイト |

`amounts.bin` = 上記 10 フィールドを順番に連結したもの、合計 59 バイト。

## 03.3 パック 10 進数の解析

参照モデル：7 バイトの各レコード → 14 ニブル。先頭 13 ニブルは数字（0–9 であること）、最後のニブルは符号（C/D）です。`<sign><11 位整数>.<小数 2 桁>` としてデコードします。

| フィクスチャ | 生バイト | 判定 |
|---|---|---|
| `normal/mixed-valid.dat` | 正/負/±ゼロ/最大値の 5 レコード | すべて OK、RC0 |
| `boundary/empty.dat` | 0 バイト | TOTAL=0、RC0 |
| `boundary/zero-positive.dat` | `0000000000000c` | `+00000000000.00` |
| `boundary/zero-negative.dat` | `0000000000000d` | `-00000000000.00`（数値は 0） |
| `boundary/max-value.dat` | `9999999999999c` | `+99999999999.99` |
| `invalid/bad-digit-nibble.dat` | `00000a1234567c` | REJECT `DIGIT-NOT-0-9`、RC4 |
| `invalid/bad-sign-nibble.dat` | `0000001234567f` | REJECT `BAD-SIGN-NIBBLE`、RC4 |
| `invalid/truncated.dat` | 6 バイト | RC8、何も公開しない（長さが 7 の倍数ではない） |
| `invalid/trailing-byte.dat` | 8 バイト | RC8、何も公開しない |
