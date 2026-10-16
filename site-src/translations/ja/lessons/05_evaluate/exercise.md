---
_translated_from: lessons/05_evaluate/exercise.md
_translated_by: site-src/translation agent
---

# 第 05 課 演習：EVALUATE

この演習で使うのは第 04〜05 課で学んだ内容だけです：`EVALUATE` / `WHEN` / `WHEN OTHER` による多分岐、`WORKING-STORAGE` の `VALUE` 初期値、`DISPLAY` 出力、`STOP RUN` による終了。入力はすべてプログラム内の定数であり、ファイル・ループ・データベースは扱いません。

## 修正演習（`answer.md` に参考解答があります）

インターフェース契約に取引コード `F`（手数料）が加わり、プログラムでもこれを分類できるようにする必要があります。この課の元の [`lesson.cob`](./lesson.cob) から出発して修正してください。

1. 変更箇所：`EVALUATE WS-TRANSACTION-CODE` の `WHEN "T"` 分岐の最後の `DISPLAY`（`DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"`）のあと、`WHEN OTHER` の前に新しい分岐を挿入します。

   ```cobol
               WHEN "F"
                   DISPLAY "分類=FEE"
                   DISPLAY "処理=CHARGE_FEE"
   ```

2. 固定サンプルで新しい分岐を観察できるようにするため、データ項目の初期値 `01 WS-TRANSACTION-CODE PIC X VALUE "D".` を `VALUE "F"` に変更します。

制約：

- `WHEN "D"`、`WHEN "W"`、`WHEN "T"` の三つの分岐の出力は変更しない。
- `WHEN OTHER` の意味と出力は変更しない。
- 新しい分岐のインデントは隣接する分岐と揃える（Area B は第 12 列から開始）。プログラムのテキストは第 72 列を超えない。

再コンパイルして実行します。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_05 lesson.cob
./build/lesson_05
echo $?
```

期待される差分（元のバージョンと出力を行単位で比較）：

- 第 2 行が `取引コード=D` から `取引コード=F` に変わる。
- 第 3、4 行が `分類=DEPOSIT` / `処理=ADD_TO_ACCOUNT` から `分類=FEE` / `処理=CHARGE_FEE` に変わる。
- 第 1 行の `取引参照番号=TXN-00000001` は変わらない（このフィールドは変更していない）。
- `cobc -fsyntax-only`、`cobc -x`、プロセス終了コードはいずれも `0` のまま、コンパイル診断もなし。

理由：`EVALUATE` は subject（`WS-TRANSACTION-CODE`）と各 `WHEN` の値を厳密に突き合わせるため、初期値 `F` は新しい分岐にヒットし、`WHEN OTHER` には落ちない。参照番号のフィールドは今回の修正には含まれていないので変化しない。

境界チェック：追加した `WHEN "F"` 分岐を残したまま、初期値を `X` に戻して再度実行すると、`分類=UNKNOWN` / `処理=REJECT_FOR_REVIEW` が得られるはずです。これは追加した分岐が `F` にしか効かず、`WHEN OTHER` のフォールバック挙動を変えていないことを確認するためです。このチェックは上記の「`WHEN OTHER` を変更しない」という制約を検証するために行います。

## 発展演習（参考解答はありません）

バッチレコードの支払い方法を分類する問題：`C` 現金、`B` 銀行振込、`K` 小切手。契約外のコードは一律「人手確認待ち」と出力してください。

要件：固定書式の完全プログラムを書き、`EVALUATE` で支払方法コードを分類ラベルと処理推奨にマッピングします。そして以下の各値に対してそれぞれ一度ずつ実行し、実際の出力を記録してください：`C`、`B`、`K`、`Z`（別の文字）、空白（`VALUE " "`）。

制限：この課で扱うプログラム構造、`EVALUATE` / `WHEN` / `WHEN OTHER`、`DISPLAY`、`STOP RUN` のみ使用してください。まだ学んでいない表・ファイル・ループ・サブルーチンは導入しないでください。

ソースコード、コンパイルコマンド、各値の実際の出力を提出し、以下の点について説明してください：マッチした分岐だけが実行されたことをどう確かめたか、未定義の文字と空白がなぜ同じフォールバック経路に入るのか、そして「分類／処理ラベル」が「支払い処理が完了したこと」と等価ではない理由。
