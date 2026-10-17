# モジュール 04 の期待結果と独立検証

`expected` は構造の意味と実測 ABI から独立して決定し、コンパイル済み COBOL の出力と照合します。プログラム出力を正解とはみなしません。中核となる実測は [../scripts/check.py](../scripts/check.py) が GnuCOBOL の `ADDRESS OF` を使ってフィールドごとに行い（葉フィールド 175 個 + V1/V2 のオフセット）、[../evidence/M04-layout-author.json](../evidence/M04-layout-author.json) に記録します。
公開前に `run.sh` は [../scripts/verify.py](../scripts/verify.py) を使い、同じ意味規則でレポートを再計算して各項目を照合します（04.3 はカタログのオフセットを使って生バイトから直接再計算します）。不一致があれば拒否し、公開しません。

## 04.1 構造の意味

| 項目 | 期待値 | 根拠 |
|---|---|---|
| WRAP の長さ | 18 | PAYLOAD=8+7+3=18；REDEFINES の別名は追加のバイト領域を占有しない |
| PAYLOAD / PAYLOAD-RAW の長さ | 18 / 18 | 同じ記憶領域に対する 2 つのビュー |
| R-AB の長さ | 7 | RENAMES R-A(3) THRU R-B(4) |
| R-AB の値 | `AAABBBB` | R-A=`AAA`、R-B=`BBBB` |
| OCCURS 項目数 / INDEX-3 | 5 / `CCC` | `SET IDX-POS TO 3` で第 3 項目を取得 |
| ODO count=3 の長さ | 17 | 2（カウンター）+ 3×5 |
| ODO count=7 の長さ | 37 | 2（カウンター）+ 7×5 |

## 04.2 COPY REPLACING とオフセットの移動

| 項目 | 期待値 | 根拠 |
|---|---|---|
| LEN,V1 | 1778 | 企業顧客 V1 の canonical 長 |
| LEN,V2 | 1779 | CUSTOMER-CLASSIFICATION のみ X(1) から X(2) に変更 |
| SHIFT | 1 | 1 バイト拡張 |
| 分類フィールドのオフセット | 460（両バージョンで同じ） | 分類フィールド自身は、その後で幅が広がるためオフセット不変 |
| SYNC-STATE のオフセット | V1=1778 / V2=1779 | その後の全フィールドが +1 移動 |
| REFMOD FIRST4/LAST6 | `0000` / `000001` | `CUSTOMER-ID` = `0000000001` |

## 04.3 企業レコードの位置特定

- `normal/enterprise-2.dat`：2 レコード（key 0000000001=A/EXAMPLE/1234、0000000003=B/SAMPLE/-25）。[04.3-normal.txt](04.3-normal.txt) を参照。
- `boundary/enterprise-1.dat`：1 レコード；`boundary/enterprise-empty.dat`：0 レコード（RC0）。
- `invalid/`：長さ不一致 / version `009` / ABI 不一致 / 数字以外の key は、すべて RC8 で何も公開されません。

## モジュール 07 との関係

カタログ、Copybook、1,778 バイトのレイアウトはモジュール 07 L4 と同じソースに由来します。本モジュールでは構造とレコードの位置特定のみを扱い、フィールドごとの業務ドメイン比較は行いません。175 フィールドのオフセットがカタログと一致することは、本モジュールの `check.py` で独立して再検証します。
