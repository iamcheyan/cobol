---
_translated_from: lessons/03_move-compute/answer.md
_translated_by: site-src/translation agent
---

# 第 03 課 修正演習 参考解答

この解答は `exercise.md` の修正演習のみをカバーし、発展演習の解答は含みません。

元の `lesson.cob` から、初期値 2 件だけを変更し、他の宣言と文はそのままにします：

```cobol
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 200.65.
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0150.
```

再チェック、コンパイル、実行（`exercise.md` と同じコマンド）：

```sh
cd lessons/03_move-compute
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_03 lesson.cob
./build/lesson_03
echo $?
rm -rf build
```

## 手計算による照合

1. 利息計算前残高：`1000.00 + 200.65 − 40.10 − 5.25 = 1155.30`（足してから引く、単位は元）。
2. 利息中間値：`1155.30 × 0.0150 = 17.3295`、受信項目 `WS-INTEREST-RAW` は `9(5)V9999`（4 桁小数）で、完全に保持できる。
3. `MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE`：`WS-INTEREST-MOVE` は `9(5)V99`、`ROUNDED` なしは切捨てと同義、`17.3295 → 17.32`。`WS-INTEREST-RAW` 自体は依然 `17.3295`。
4. `COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW`：`ROUNDED` なし、同じ切捨てルール、結果 `17.32`。
5. `COMPUTE WS-INTEREST-ROUNDED ROUNDED = WS-INTEREST-RAW`：デフォルト `NEAREST-AWAY-FROM-ZERO`、3 桁目が `9`、繰上げで `17.33`。
6. 期末残高：本課の計上ルールで丸め後の利息を計上、`1155.30 + 17.33 = 1172.63`。

## 完全な期待出力

```text
期首残高=0001000.00
預入額=0000200.65
払戻額=0000040.10
手数料=00005.25
期間利率=0.0150
利息加算前残高=0001155.30
利息（4桁）=00017.3295
MOVE後利息（2桁）=00017.32
COMPUTE切捨て利息=00017.32
COMPUTE四捨五入利息=00017.33
期末残高=0001172.63
```

基準出力との比較では、`期首残高`、`払戻額`、`手数料` の 3 行は不変。他の 8 行は `exercise.md` の期待差分表に従って変化。`cobc -fsyntax-only`、`cobc -x`、プログラム実行の終了コードはすべて `0`、標準エラーは環境付属の libxml バージョン警告のみ、コンパイル警告なし。

## 問いへの回答

- 切捨てと丸めに共通するソース値は `WS-INTEREST-RAW`、つまり `17.3295`。`9(5)V9999` で 4 桁小数を保持。
- `MOVE` の結果は受信項目 `WS-INTEREST-MOVE`（`9(5)V99`）で決定。`ROUNDED` なしの `COMPUTE` は `WS-INTEREST-TRUNC`（`9(5)V99`）で決定。`ROUNDED` ありの `COMPUTE` は `WS-INTEREST-ROUNDED`（`9(5)V99`）で決定。3 者は同じソース値、同じ受信項目目盛で、差は「`ROUNDED` を書くか否か」だけ。
