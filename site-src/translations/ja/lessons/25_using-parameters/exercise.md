---
_translated_from: lessons/25_using-parameters/exercise.md
_translated_by: site-src/translation agent
---

# 第 25 課の演習：CALL パラメーターのデータ方向

本課のソースファイル：主プログラム `lesson.cob`、サブプログラム `add_one_25.cob`（`ADD-ONE`）と `report_binary_25.cob`（`REPORT-BINARY`）、パラメーター宣言 `copybooks/AMOUNT-INTERFACE.CPY`。解説と期待される結果は [`README.md`](./README.md) を参照してください。

変更するたびに、同じコマンドで 3 つのソースファイルを再コンパイルしてください（`-I copybooks` を忘れないこと）。

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

このレッスンの環境では、コンパイラーが `BY VALUE` に対して出す「unfinished」警告は想定どおりです。実行時には 3 つの自己検査すべてに合格し（`集計 合格=003 不合格=000`）、終了コードが `0` になるはずです。

## 変更演習（解答は [`answer.md`](./answer.md)）

どちらも**現在のソース**から始め、互いに独立して行います。`report_binary_25.cob` と Copybook は変更しないでください。

1. **サブプログラムの加算量を 2 にする。**
   - 変更箇所：`add_one_25.cob` の `ADD 1 TO AMOUNT-ARGUMENT` を `ADD 2 TO AMOUNT-ARGUMENT` に変更します。`lesson.cob` の `1100-TEST-REFERENCE` では `WS-EXPECTED` を `11` から `12` に変更します。
   - 制約：ほかの段落、期待値、`WS-MODE` ラベルは変更しません。
   - 期待結果：`BY REFERENCE` の呼び出し後、呼び出し元は `12` を確認します。`BY CONTENT` の節ではサブプログラム内の表示が `22` になりますが、呼び出し元の値は `20` のままです。`BY VALUE` の節は `30` のままです。集計は `集計 合格=003 不合格=000`、終了コードは `0` です。
   - 問い：同じサブプログラム内の表示値は両方の節で変わるのに、呼び出し元のフィールドが変わるのはなぜ片方だけでしょうか。

2. **2 回目の呼び出しを `BY REFERENCE` にする。**
   - 変更箇所：`lesson.cob` の `1200-TEST-CONTENT` で `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` を `... USING BY REFERENCE AMOUNT-ARGUMENT` に変更します。同じ段落の `WS-EXPECTED` を `20` から `21` に、`WS-MODE` を `"BY CONTENT"` から `"BY REFERENCE"` に変更します。
   - 制約：段落 `1100` と `1300` は変更しません。
   - 期待結果：呼び出し後、呼び出し元は `21` を確認し、この合格結果は `BY REFERENCE` に計上されます。集計は `方式 BY REFERENCE=002 BY CONTENT=000 値=001`、`集計 合格=003 不合格=000`、終了コードは `0` です。
   - 問い：`BY CONTENT` を `BY REFERENCE` に変え、`WS-EXPECTED` と `WS-MODE` を変えない場合、プログラムには何が表示されますか。呼び出し方式だけを変えても足りないのはなぜでしょうか。

両方の演習で標準出力全体を保存し、「サブプログラム内の値」と「呼び出し元のフィールド値」を分けて示してください。

## 応用演習（解答なし）

インターフェース Copybook に金額入力フィールドと状態出力フィールド（状態値 `VALID` / `REJECTED`）を追加します。サブプログラムが `BY REFERENCE` で状態を書き戻し、主プログラムが `CALL` 後に状態フィールドを見て分岐するようにします。次に状態パラメーターだけを `BY CONTENT` に変え、呼び出し元が引き続き状態を受け取れるか比較してください。両方の呼び出しでの呼び出し元の結果、パラメーターの位置、両フィールドの `PIC`/`USAGE`、有効ケースと無効ケースの確認に使った入力値を記録します。

境界確認として、状態パラメーターの渡し方とサブプログラムの `PROCEDURE DIVISION USING` 宣言を意図的に不一致にします（例：呼び出し元は `BY VALUE`、サブプログラムは省略時の `BY REFERENCE` で受け取る）。コンパイルでエラーが出るか、実行が正常に終わるか、状態フィールドを信頼できるかを記録してください。この種のインターフェース誤りをプログラムの自己検査で検出できない理由も説明します。

解答はありません。group item や任意長データに `BY VALUE` を使わないでください。また、3 つの渡し方で記憶域レイアウトやクロスプラットフォームでの動作が同じだと仮定しないでください。フィールド設計、パラメーター順序、検証入力値、観察結果は、自分で決めて説明します。
