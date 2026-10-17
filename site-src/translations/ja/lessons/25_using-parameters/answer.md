---
_translated_from: lessons/25_using-parameters/answer.md
_translated_by: site-src/translation agent
---

# 第 25 課の変更演習：参考解答

この解答が扱うのは [`exercise.md`](./exercise.md) の 2 つの変更演習だけです。応用演習の解答はありません。どちらも現在のソースから始め、毎回同じコマンドで 3 つのソースファイルを再コンパイルしてください。

```sh
mkdir -p build
cobc -x -Wall -I copybooks -o build/lesson_25 \
  lesson.cob add_one_25.cob report_binary_25.cob
./build/lesson_25
echo $?
rm -rf build
```

以下の標準出力は実際の実行結果です（各演習は元のソースから始めるため、互いに独立しています）。どちらの解答でも `BY VALUE` の `-Wunfinished` 警告はそのまま表示されますが、業務動作とは無関係です。

## 1. サブプログラムの加算量を 2 にする

変更箇所：

- `add_one_25.cob`：`ADD 1 TO AMOUNT-ARGUMENT` → `ADD 2 TO AMOUNT-ARGUMENT`
- `lesson.cob` の `1100-TEST-REFERENCE`：`MOVE 11 TO WS-EXPECTED` → `MOVE 12 TO WS-EXPECTED`

標準出力（11 行、終了コード `0`）：

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000012
呼出側=呼出後 方式=BY REFERENCE 値=000000012 確認=合格
呼出側=呼出前 方式=BY CONTENT 値=000000020
被呼出側=加算後 値=000000022
呼出側=呼出後 方式=BY CONTENT 値=000000020 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=001 BY CONTENT=001 値=001
```

元の出力からの違いは 3 か所だけです。2 つの `被呼出側=加算後` の行が `011`/`021` から `012`/`022` に変わり、`BY REFERENCE` の呼び出し後の値が `011` から `012` に変わります。`ADD-ONE` が受け取るのは、引き続き同じパラメーター領域（`BY REFERENCE`）またはその一時コピー（`BY CONTENT`）です。加算量を 1 から 2 にすると、どちらの場合もサブプログラム内で見える値が変わります。ただし、呼び出し元自身の領域を書き換えるのは `BY REFERENCE` の場合だけなので、その値は 10 から 12 に変わり、`BY CONTENT` の呼び出し元の値は 20 のままです。`BY VALUE` の節は別のサブプログラムを呼ぶため、影響を受けません。

## 2. 2 回目の呼び出しを BY REFERENCE にする

変更箇所（すべて `lesson.cob` の `1200-TEST-CONTENT` 内）：

- `CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT` → `CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT`
- `MOVE 20 TO WS-EXPECTED` → `MOVE 21 TO WS-EXPECTED`
- `MOVE "BY CONTENT" TO WS-MODE` → `MOVE "BY REFERENCE" TO WS-MODE`

標準出力（11 行、終了コード `0`）：

```text
呼出側=呼出前 方式=BY REFERENCE 値=000000010
被呼出側=加算後 値=000000011
呼出側=呼出後 方式=BY REFERENCE 値=000000011 確認=合格
呼出側=呼出前 方式=BY REFERENCE 値=000000020
被呼出側=加算後 値=000000021
呼出側=呼出後 方式=BY REFERENCE 値=000000021 確認=合格
呼出側=呼出前 方式=BY VALUE 値=000000030
被呼出側=受取値=000000030
呼出側=呼出後 方式=BY VALUE 値=000000030 確認=合格
集計 合格=003 不合格=000
方式 BY REFERENCE=002 BY CONTENT=000 値=001
```

違いは次のとおりです。4 行目の方式ラベルが `BY REFERENCE` になり、6 行目の呼び出し後の値が `000000020` から `000000021` に変わり、集計行が `方式 BY REFERENCE=002 BY CONTENT=000 値=001` になります。渡し方を `BY REFERENCE` にすると、サブプログラムが呼び出し元の領域そのものを加算するため、呼び出し元の値は 20 から 21 に変わります。自己検査を通すには期待値も 21 に変える必要があります。`WS-MODE` は合格結果をどの方式の件数に入れるかを決めるので、この 3 か所をまとめて変更します。

**呼び出し方式だけを変え、期待値とラベルを変えない場合（実測）：** `CALL` だけを `BY REFERENCE` にし、`WS-EXPECTED` を `20`、`WS-MODE` を `"BY CONTENT"` のままにすると、`呼出側=呼出後 方式=BY CONTENT 値=000000021 確認=失敗` と表示されます。集計は `集計 合格=002 不合格=001`、方式別件数は `方式 BY REFERENCE=001 BY CONTENT=000 値=001`、終了コードは `1` です。失敗した検査はどの方式の件数にも加算されません。したがって `BY CONTENT=000` は「`BY CONTENT` で呼び出さなかった」という意味ではなく、「`BY CONTENT` のラベルで自己検査に合格した呼び出しがなかった」という意味です。

## 結論

渡し方によって、サブプログラムが呼び出し元の領域に与える影響と、`CALL` 後に呼び出し元が見る値が決まります。どれかを変更する場合は、呼び出し方式、期待値、方式ラベルを一緒に更新してください。そうしないと自己検査が失敗して終了コードが `1` になり、表示や分類別件数が誤解を招くことがあります。呼び出し元の自己検査が見るのは呼び出し元自身の領域だけなので、サブプログラムが正しい引数を受け取ったかは確認できません（README の「テーマの境界」での実測を参照）。
