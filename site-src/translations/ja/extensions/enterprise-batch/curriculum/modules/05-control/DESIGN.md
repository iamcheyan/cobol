# モジュール05設計：CUSTOMER v1クレンジング契約

## 1. インターフェースとバイト配置

CUSTOMER v1 = 27バイト、ASCII、LF終端。論理幅にLFは含めません。フィールドは`copybooks/CUSTOMER-V1.CPY`と一致します。

| 位置 | 長さ | COBOL名 | 規則 |
|---:|---:|---|---|
| 1–8 | 8 | CUST-ID | 8桁。先頭ゼロを保持し、クレンジング時に昇順を要求 |
| 9–18 | 10 | CUST-NAME | ASCII、右側を空白で埋める。必須 |
| 19–26 | 8 | CUST-BALANCE | 数値、0 ≤ 値 ≤ 50,000,000 |
| 27 | 1 | CUST-STATUS | 入力では大文字小文字を許容し、`A`/`D`に正規化 |

本モジュールは`curriculum/bank/copybooks/ACCOUNT-V1.CPY`（47B）および`TRANSACTION-V1.CPY`（55B）を**変更しません**。クレンジング済み顧客ファイルはそれらと同じ業務日引数を使います。

## 2. 読み込みモデル（なぜ1バイトずつか）

プログラムは`ORGANIZATION IS SEQUENTIAL`と`01 C-BYTE PIC X`を使い、1バイトずつ読み込んでLFを識別します。

- `X'0A'`で論理レコードが終わります。LFより前のバイト数は1..27でなければなりません。
- 27バイト未満 → `SHORT-RECORD`；27バイト到達後にLF以外のバイト → `LONG-RECORD`；`X'0D'` → `CRLF-NOT-ALLOWED`；EOF時に未終端バイトが残る → `MISSING-FINAL-LF`。
- 以上4種類はファイル契約エラーでRC8です。

`LINE SEQUENTIAL`は呼出し側から改行を取り除き、論理幅から超過レコードを検出できないため、本モジュールでは意図的に使いません。モジュール06ではフィクスチャを使って両方式のバイト差を比較します。

## 3. 処理状態と順序

```text
OPEN INPUT/OUTPUT → ステータステーブルを初期化
  loop: READ-RECORD → PROCESS-RECORD
PROCESS-RECORD:
  1. 構造検証（長さ/CRLF）は読み込み時に完了済み
  2. idは数値か？ いいえ → MISSING-ID；はい → 降順か？ RC8；前のレコードと同値か？ DUPLICATE-ID；それ以外はPREV-IDを保存
  3. REASONが空のままなら → 空白除去後にnameが空でないか？ 空ならMISSING-NAME
  4. REASONが空のままなら → amountは数値か？ いいえならBAD-AMOUNT；上限超過ならAMOUNT-RANGE
  5. REASONが空のままなら → INSPECTでstatusを大文字化 → テーブル{A,D}をSEARCH ALL；未一致ならUNKNOWN-STATUS
  6. REASONが空ならaccepted.datへ書き金額を加算。それ以外はrejected.datへ書く
CLOSE → READ = ACCEPT + REJECTを確認 → CONTROLを出力
```

`SEARCH ALL`が調べる`STATUS-TABLE`は`ASCENDING KEY`付きで宣言され、二分探索の前提を満たすA<D順でロードします。未整列テーブルの反例は`scripts/search-all-probe.COB`を参照してください。

## 4. 拒否理由の優先順位（業務方針）

数値IDは名前/金額/statusより先に重複判定します。1レコードが複数ルールに違反する場合、最初に該当した理由を使います。

1. `MISSING-ID` → 2. `DUPLICATE-ID` → 3. `MISSING-NAME` → 4. `BAD-AMOUNT` /
   `AMOUNT-RANGE` → 5. `UNKNOWN-STATUS`。

`UNSORTED-INPUT`（数値IDが直前より小さい）と長さエラーは1件ごとの業務拒否ではなく、**契約エラーRC8**です。

## 5. 出力とRC

| 成果物 | 内容 |
|---|---|
| `accepted.dat` | 正規化された27Bレコード（status大文字）、LF終端 |
| `rejected.dat` | 元の27B + `\|` + 理由、LF終端 |
| `report.txt` | レコードごとの`CUST|...`行 + 最終`CONTROL|...`行 |
| `filestatus`/`compiler.txt`/`source.sha256` | 実行およびソースの証跡 |

RC：0 拒否なし；4 業務拒否あり；8 契約エラー（長さ/CRLF/LF欠落/降順/不正業務日）；12 システム障害。

## 6. 手計算例（`fixtures/invalid/mixed.dat`）

| レコード | 主なフィールド | 判定 | 理由 |
|---:|---|---|---|
| 1 | id 00000001、name "  Alice"、bal 00000050、status `a` | ACCEPT A | status `a`→`A`∈{A,D}、金額50≤上限 |
| 2 | id 00000002、nameは空白のみ | REJECT MISSING-NAME | 必須値が空 |
| 3 | id 00000003、bal 50000001、status `D` | REJECT AMOUNT-RANGE | 50000001 > 50,000,000 |
| 4 | id 00000004、bal `00000XYZ` | REJECT BAD-AMOUNT | 数値ではない |
| 5 | id 00000005、status `Q` | REJECT UNKNOWN-STATUS | `Q`∉{A,D} |
| 6 | id 00000005（重複）、他の項目は有効 | REJECT DUPLICATE-ID | 直前レコードと同一ID |

読込6件 = 受理1件 + 拒否5件、`AMOUNT`=50（合計に含むのはレコード1のみ）。すべての`expected/*.txt`はこの表と同じ規則から手計算し、その後参考実装と照合しています。

## 7. 境界条件と制限

- 空ファイル（0バイト）は有効：READ=0、RC0。
- 上限50,000,000は合成演習の方針です。実システムではフィールドカタログに従い、暗黙に流用してはいけません。
- ASCIIと最小通貨単位の整数のみ。小数換算はしません。マルチバイト/EBCDICは別演習です。
- 実検証済み環境：Linux x86-64、GnuCOBOL 3.2（ローカルBDB backend）。他環境は未検証です。
- 実行時の`libcob: warning`（libxmlバージョン通知）は業務RCと無関係な環境ノイズの場合があります。

## 8. 制御フローの意味（05.1 小実験）

固定形式COBOLでは、段落/節は空行やピリオドではなく次の段落見出しで終了します。

- `PERFORM 2000-FIRST`はその段落だけを実行し、境界で暗黙に戻ります。3000-SECONDへ**fall-throughしません**。
- `PERFORM 2000-FIRST THRU 3000-SECOND`は2000-FIRSTから連続実行し、3000-SECOND内の`EXIT`（または`EXIT PARAGRAPH`）まで進みます。これがscopeを定める一方、fall-throughを書きやすい箇所でもあります。
- `PERFORM VARYING I FROM 1 BY 1 UNTIL …`は実行前に`UNTIL`を評価します。`PERFORM n TIMES … END-PERFORM`はinline loopで、デフォルトはTEST BEFOREです。

これらは`scripts/control-flow-probe.COB`で実測し、`check.py::check_control_flow`が行単位の出力を固定します。
