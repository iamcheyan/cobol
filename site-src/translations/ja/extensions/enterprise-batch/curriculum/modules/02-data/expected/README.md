# 独立した期待結果と手計算（モジュール 02）

期待結果は CUSTOMER v1 契約と COBOL の `MOVE` 規則から手作業で導出したもので、プログラムの出力ではありません。`check.py` は制御レポートと
`movelab.txt` をバイト単位で比較し、元のフィクスチャから `accepted.dat`/`rejected.dat` を独立して導出します。

## CUSTOMER v1 ロードの計算

規則：1レコード27バイト、IDは8桁の数字で厳密な昇順、名前は全て空白であってはならない、`balance_demo` は8桁の数字（単位はセント、
符号なし）、状態は `A`/`D`。拒否理由の優先順位は `NAME-MISSING` > `BAD-AMOUNT` > `UNKNOWN-STATUS`。
`BALANCE-TOTAL` は受理したレコードのみを加算します。

**normal**：`ALICE 12345` + `BOB 50` + `CAROL 9999999`。状態 A/D/A はすべて有効です。
12345 + 50 + 9999999 = **10012394**；受理3件、拒否0件。

```text
READ=3  ACCEPTED=3  REJECTED=0  BALANCE-TOTAL=10012394
```

**empty**：0バイト。空を許容 → すべて0。

**single**：`SOLO 500` → 1件受理、合計500。

**max-balance**：`MAX 99999999`（8桁の上限）→ 1件受理、合計99999999。

**name-full**：名前がちょうど10文字の `ABCDEFGHIJ` → 1件受理、合計1000。

**name-missing**：名前が10個の空白 → 1件拒否、理由 `NAME-MISSING`、合計0。

**bad-amount**：`balance_demo` = `00000A00`（英字 A を含む）→ 1件拒否、理由 `BAD-AMOUNT`、合計0。

**unknown-status**：状態が `Z` → 1件拒否、理由 `UNKNOWN-STATUS`、合計0。

拒否レコードの形式は元の27バイト + `|` + 理由です。例：

```text
00000006          00000000A|NAME-MISSING
00000007BADBAL    00000A00A|BAD-AMOUNT
00000008STATUS    00000000Z|UNKNOWN-STATUS
```

## 構造フィクスチャ（RC8、正式な期待結果なし）

`short`(26B)、`long`(28B)、`crlf`、`bad-id`、`duplicate-id`、`unsorted`、`no-final-lf` はすべて
インターフェース契約に違反します。契約では**バッチ全体を失敗させ、出力ディレクトリを一切生成しない**ことを求めるため、正式なレポートはありません。合格条件は「出力ディレクトリがなく、元フィクスチャの SHA256 が変わっていないこと」です。

## MOVE 実験表（`expected/movelab.txt`）

規則の根拠：COBOL 固定小数点数の**小数点位置合わせ**と、英数字の**左寄せ・右側空白埋め**の意味。

| ケース | 式 | 期待バイト列 | 根拠 |
|---|---|---|---|
| A | `PIC 9(3)V99 VALUE 41.5` 表示 | `A|041.50|` | 暗黙の小数点を表示時に補い、3+2桁 |
| B | `41.5 → PIC 9(5)` | `B|00041|` | 小数点位置を合わせた後、整数の41を取る |
| C | `PIC 9(5) 41 → PIC X(5)` | `C|00041|` | 数値→英数字では表示上の5桁を保持 |
| D | `'AB' → PIC X(5)` | `D|AB   |` | 英数字の右側に空白を3つ補う |
| E | `S9(3) LEADING SEPARATE -12` | `E|-012|` | 分離符号が1バイトを占める |
| F | `S9(3)V99 LEADING SEPARATE -1.25` | `F|-001.25|` | 符号 + 暗黙の小数点 |
| G | `'ABCDEFGH' → PIC X(5)` | `G|ABCDE|` | 右側を切り詰め、左の5文字を保持 |
| H | `12345 → PIC 9(3)` | `H|345|` | 数値の上位桁を切り詰め、下位桁を保持 |
| I | `12345.67 → PIC 9(3)V99` | `I|345.67|` | 上位桁を切り詰め、小数部を保持 |

## 型と階層の実験表（`expected/typeslab.txt`）

入力 `fixtures/types/typeinput.dat`：5バイトのレコードが3件、`ABCDE` / `AB123` / `AB CD`。規則の根拠：
`IS ALPHABETIC` は英字と空白に対して真、数字に対して偽です。`MOVE` は項目のデータ分類を検査しません。

| レコード | `PIC X(5)` の元値 | `PIC A(5)` への移動後 | `IS ALPHABETIC` | 分類 |
|---|---|---|---|---|
| `ABCDE` | `ABCDE` | `ABCDE` | 真 | `A` |
| `AB123` | `AB123` | `AB123` | 偽 | `M` |
| `AB CD` | `AB CD` | `AB CD` | 真 | `A` |

`78 WS-LIMIT VALUE 25` は `25` を表示し、`77 WS-COUNT` は各レコードを数えて `00003` になります。期待出力の全文（バイト単位）：

```text
TYPESLAB|V1
LIMIT|25|
00001|ABCDE|ABCDE|A|
00002|AB123|AB123|M|
00003|AB CD|AB CD|A|
COUNT|00003|
```

再現可能な失敗例：数字を含む `X` データを `PIC A` に移しても、自動的には拒否されません（レコード2を参照）。数値項目を
`MOVE` で `PIC A` に移すとコンパイル時に直接失敗し、`check.py` はその `MOVE` が非ゼロで終了することを確認します。

## レイアウト実験

canonical Copybook に対して `LENGTH-PROBE` は `CUSTOMER-RECORD=27`、`NAME-LENGTH=10` を出力します。**意図的に
誤記した非契約**の `X(11)` 変種では `28`、`11` を出力します。単一フィールドの `PIC` を変更するとレコード全体の長さと
後続のオフセットが移動することを示します。この変種は誤ったレイアウトのデモであり、CUSTOMER v1 契約や27→28の移行ではありません。

## リリース条件

`control.txt` が2行であり、件数と合計が上記の計算に一致し、`accepted.dat`/`rejected.dat` がバイト単位で一致し、
`movelab.txt` と `typeslab.txt` が実験出力とバイト単位で一致した場合に合格です。
