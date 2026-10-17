# COBOL サンプルとプラグインの演習ガイド

このガイドでは、リポジトリ内の独立して実行できる COBOL サンプル 4 本を紹介し、それぞれで試せる `cobol.nvim` の機能を示します。サンプルはプラグインのチュートリアルと併せて使えますが、プログラムの利用にプラグインのインストールは必要ありません。

---

## 1. 4 つのサンプルの概要

| サンプルプログラム | 業務シナリオ | 主な COBOL 技術 | プラグインで試せる操作 |
|---|---|---|---|
| **1. `INPUTCSV.COB`** | パイプ区切りテキストを整形して CSV 出力 | • `ORGANIZATION IS LINE SEQUENTIAL`<br>• `UNSTRING ... DELIMITED BY` による分割<br>• `STRING` と `FUNCTION TRIM` による連結と空白除去<br>• Copybook の取り込み（`EMP-REC.CPY`） | `gf` で Copybook を開く、`K` でプレビュー、`gd` / `<C-o>` で Paragraph の定義へ移動して戻る |
| **2. `FIXEDREC.COB`** | 80 列の銀行取引固定長レコードを処理 | • 区切り文字のない物理位置による読み込み<br>• **`REDEFINES` による領域共有と構造の再定義**<br>• レベル 88 の取引状態条件名（`EVALUATE TRUE`）<br>• `COMP-3` による高精度な十進金額の累積 | `<leader>cr` でレイアウト表を確認できます。再定義ブランチはオフセットや合計サイズ上で統合されないため、コンパイラーで確認してください。 |
| **3. `TBLSRCH.COB`** | 為替レート表と二分探索 | • COBOL のメモリ内テーブル（配列）：`OCCURS n TIMES`<br>• 専用ポインターと添字：`INDEXED BY`<br>• **`SEARCH ALL` による言語組み込みの二分探索**<br>• 浮動小数点レートの乗算と丸め | 基本フィールドの OCCURS サイズ推定を確認し、`gd` で定義を検索できます（グループレベルの OCCURS 回数は子フィールドの合計に完全には反映されません）。 |
| **4. `BATCHRPT.COB`** | 2 階層の古典的なコントロールブレーク監査レポート | • **2 階層のコントロールブレークアルゴリズム**<br>• 部門小計と支店合計<br>• 編集形式の通貨出力（`PIC $$$,$$$,$$9.99`、`ZZ9`）<br>• 構造化された改ページと二重区切り線 | `gd` / `<C-o>` で Header、Detail、Break の段落間を移動し、72 列超過ガードを試します。 |

---

## 2. サンプル 1：`INPUTCSV.COB` — テキストデータの分割と整形

### シナリオ
データウェアハウスや外部パートナーから、`|` 区切りの従業員データ `input.txt` が届きます。余分な空白を取り除き、名前を二重引用符で囲み、標準的なカンマ区切りの `output.csv` に出力します。

### 主なコード
* **文字列の分割（`UNSTRING`）**：
  ```cobol
  UNSTRING INPUT-RECORD
      DELIMITED BY "|"
      INTO IN-EMPLOYEE-ID
           IN-FULL-NAME
           IN-AGE
           IN-SALARY
      TALLYING IN WS-FIELD-COUNT
  END-UNSTRING
  ```
* **文字列の連結と空白除去（`STRING` + `TRIM`）**：
  ```cobol
  STRING FUNCTION TRIM(IN-EMPLOYEE-ID) DELIMITED BY SIZE
         "," DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         IN-FULL-NAME DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         INTO CSV-LINE
  END-STRING
  ```

### おすすめの実践手順
1. ファイルを開きます：`nvim extensions/standalone-examples/INPUTCSV.COB`。
2. `COPY "EMP-REC.CPY".` にカーソルを置いて **`K`** を押し、浮動ウィンドウで構造をプレビューします。`q` で閉じます。
3. `PERFORM 1000-INITIALIZE` にカーソルを置いて **`gd`** を押して定義へ移動し、**`<C-o>`** で元に戻ります。
4. `make -C extensions/standalone-examples run-csv` で実行を確認し、ターミナル出力と生成された `output.csv` を見ます。

---

## 3. サンプル 2：`FIXEDREC.COB` — 固定長レコードと REDEFINES

### シナリオ
銀行の取引ファイル `tx_input.dat` は、1 行が厳密に 80 文字で、区切り文字はありません。取引種別によって使用するフィールドが異なります。
- 入金では口座、支店、担当者番号を使用します。
- 振込では送金元口座、送金先口座、チャネルコードを使用します。

2 種類の取引は内容こそ異なりますが、全体の長さは同じです。**`REDEFINES`** を使うと、同じ 42 バイトの物理メモリ領域を共有できます。

### Copybook の基本構造（`TX-REC.CPY`）
```cobol
       01  TX-RECORD.
           05  TX-HEADER.
               10  TX-DATE             PIC 9(08).
               10  TX-TIME             PIC 9(06).
               10  TX-ID               PIC X(10).
               10  TX-TYPE             PIC X(03).
                   88  TX-DEPOSIT      VALUE "DEP".
                   88  TX-WITHDRAW     VALUE "WDR".
                   88  TX-TRANSFER     VALUE "XFR".
           05  TX-AMOUNT               PIC 9(09)V99.
           05  TX-BODY                 PIC X(42).
      *    -- 重定义分支 1：存款/取款专用 --
           05  TX-DEP-INFO REDEFINES TX-BODY.
               10  TX-DEP-ACCOUNT      PIC X(16).
               10  TX-DEP-BRANCH       PIC X(08).
               10  TX-DEP-TELLER       PIC X(06).
               10  FILLER              PIC X(12).
      *    -- 重定义分支 2：跨行转账专用 --
           05  TX-XFR-INFO REDEFINES TX-BODY.
               10  TX-XFR-FROM-ACCT    PIC X(16).
               10  TX-XFR-TO-ACCT      PIC X(16).
               10  TX-XFR-CHANNEL      PIC X(06).
               10  FILLER              PIC X(04).
```

### おすすめの実践手順
1. Copybook を開きます：`nvim extensions/standalone-examples/TX-REC.CPY`。
2. `01 TX-RECORD` にカーソルを置いて **`<leader>cr`** を押すか、`:CobolCalcRecord` を実行します。
3. **レイアウト表を確認**：基本項目がソース順に並び、オフセットが表示されます。たとえば `TX-BODY` は `+38`、`TX-AMOUNT` は `+27` です。
4. **`REDEFINES` の推定上の限界を確認**：現在の計算機能は `TX-DEP-INFO` と `TX-XFR-INFO` を同じオフセットに配置しません。代わりに子フィールドを順番に配置します（計測例では `TX-DEP-ACCOUNT` が `+80`、`TX-XFR-FROM-ACCT` が `+122`）。そのため、表示される `Total Size` は重なったメモリを複数回数えます。
   - つまり、**この合計値を `TX-RECORD` の実際の長さとみなさないでください**。`REDEFINES` ブランチが共有する実際のオフセットは、コンパイラーまたはインターフェース仕様で確認します。
5. メインプログラムを開きます：`nvim extensions/standalone-examples/FIXEDREC.COB`。
6. `TX-DEPOSIT` にカーソルを置いて **`gd`** を押し、`TX-REC.CPY` のレベル 88 定義へ移動します。**`<C-o>`** で戻ります。
7. `make -C extensions/standalone-examples run-fixed` で実行を確認し、生成された精算レポート `tx_report.txt` を確認します。

---

## 4. サンプル 3：`TBLSRCH.COB` — メモリ内テーブルと二分探索（`SEARCH ALL`）

### シナリオ
銀行のリアルタイム外国為替決済センターでは、複数通貨の対 USD 基準レートをメモリ上に保持します。バッチ取引が到着したら、対象通貨のレートをすばやく検索して金額を換算します。

### 主な技術
* **二分探索キーを持つテーブルを定義**：
  ```cobol
  01  WS-CURRENCY-TABLE REDEFINES WS-CURRENCY-TABLE-DATA.
      05  CURR-ENTRY OCCURS 10 TIMES
                     ASCENDING KEY IS CURR-CODE
                     INDEXED BY CURR-IDX.
          10  CURR-CODE           PIC X(03).
          10  CURR-RATE-TO-USD    PIC 9(06)V9(06).
  ```
* **`SEARCH ALL` で検索**：
  ```cobol
  SEARCH ALL CURR-ENTRY
      AT END
          DISPLAY "  [FAIL] Currency not supported: " REQ-CURR (REQ-IDX)
      WHEN CURR-CODE (CURR-IDX) = REQ-CURR (REQ-IDX)
          PERFORM 1100-CALCULATE-USD
  END-SEARCH
  ```
  （注：COBOL コンパイラーは `ASCENDING KEY` に基づく $O(\log N)$ の二分探索を実装するため、探索ループを自分で書く必要はありません。）

### おすすめの実践手順
1. ファイルを開きます：`nvim extensions/standalone-examples/TBLSRCH.COB`。
2. 宣言付近の PIC 推定を確認し、`:CobolCalcRecord` で認識されるフィールドサイズを調べます。計算機能はグループレベルの OCCURS 回数を全メンバーに完全には乗算しません。
3. `SEARCH ALL CURR-ENTRY` にカーソルを置き、COBOL 組み込み二分探索構文の簡潔さを確認します。
4. `make -C extensions/standalone-examples run-table` で実行を確認します。EUR、JPY、CNY、GBP の換算成功と、未対応通貨 `XYZ` が `AT END` 分岐に入ることを確認します。

---

## 5. サンプル 4：`BATCHRPT.COB` — 2 階層の古典的なコントロールブレークレポート

### シナリオ
支店と部門の順にソート済みの入力データから、会社の売上レポートを作成します。プログラムでは次の処理を行います。
1. 売上明細行を出力し、部門、支店、会社の合計に加算します。
2. 部門が変わったら、**部門小計（`* DEPT TOTAL`）**を出力し、部門用累計をリセットします。
3. 支店が変わったら、まず最後の部門小計を確定し、その後に**支店小計（`** BRANCH TOTAL`）**と区切り線を出力して、支店用累計をリセットします。
4. ファイル終端では最後のブレークを確定し、**会社全体の総計（`*** COMPANY GRAND TOTAL`）**を出力します。

### コントロールブレークのアルゴリズム
```cobol
    IF IN-BRANCH NOT = PREV-BRANCH
        PERFORM 2200-DEPT-BREAK
        PERFORM 2300-BRANCH-BREAK
        MOVE IN-BRANCH TO PREV-BRANCH
        MOVE IN-DEPT TO PREV-DEPT
    ELSE
        IF IN-DEPT NOT = PREV-DEPT
            PERFORM 2200-DEPT-BREAK
            MOVE IN-DEPT TO PREV-DEPT
        END-IF
    END-IF
```

### 通貨編集用 Picture（`PIC $$$,$$$,$$9.99`）
* `$$$,$$$,$$9.99`：ドル記号が最初のゼロ以外の数字の左側に移動します。たとえば `12500` は `   $12,500.00` と表示されます。千位のカンマが自動で入り、先頭のゼロは空白になります。

### おすすめの実践手順
1. ファイルを開きます：`nvim extensions/standalone-examples/BATCHRPT.COB`。
2. `FMT-AMOUNT PIC $$,$$$,$$9.99.` を確認します。
3. Aerial をインストールして設定した後、`:AerialToggle` を実行してプログラムのシンボルを確認します。Paragraph 名に `gd` を使って定義を表示することもできます。
4. `make -C extensions/standalone-examples run-report` で実行を確認し、整形された `sales_report.txt` を確認します。

---

![Aerial の COBOL 階層アウトライン](images/aerial-outline.png)

Aerial は COBOL の構造シンボルを表示し、検索やソース内の移動に使えます。任意の依存関係であり、未インストールでも他の主要機能は利用できます。

## 6. すべてのサンプルをまとめて実行

リポジトリのルートから、サンプル用 Makefile を実行します。

```bash
make -C extensions/standalone-examples check
make -C extensions/standalone-examples run
```
