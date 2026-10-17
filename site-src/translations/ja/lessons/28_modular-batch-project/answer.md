---
_translated_from: lessons/28_modular-batch-project/answer.md
_translated_by: site-src/translation agent
---

# 第 28 課の変更練習：参考解答

本解答は `exercise.md` の 2 つの変更練習だけを扱い、応用練習には答えません。2 つとも `./build.sh run` を実行し、サブプログラムのオブジェクトファイルを再コンパイルしてメインプログラムと再リンクします。そうしないと、ソースだけが変更され、古い実行ファイルが実行されます。

```sh
./build.sh check
./build.sh run
echo $?
./build.sh clean
```

## 1. 残高超過の出金を 1000.00 に変更する

`1300-POST-OVERDRAFT` を次のように変更します。

```cobol
           MOVE 1000.00 TO WS-TRANSACTION-AMOUNT
```

残高は `1000.00 + 125.50 − 25.25 = 1100.25` で、`1000.00 ≤ 1100.25` なので出金は成功し、残高は `100.25` になります。口座報告と件数は次のとおりです。

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0000100.25
集計 記帳=003 拒否=002
```

`build/batch.log` の 3 件目の取引イベントは `STATUS=INSUFFICIENT` から次のように変わります。

```text
EVENT=TRANSACTION NO=003 ACCOUNT=A000000001 TYPE=C STATUS=POSTED
```

不変条件を確認します。`3 + 2 = 5`。制御の流れは次のとおりです。`CALL "POST-TRANSACTION28"` は `2000-CALL-POSTER` で呼ばれ、`GOBACK` はその段落に制御を戻します。計上モジュールは残高を更新して状態を書き、`記帳` の件数はメインプログラムの `2100-REPORT-RESULT` が増やします。

## 2. 未知の取引種別を入金に変更する

元のソースに戻してから、`1400-POST-UNKNOWN-TYPE` を次のように変更します。

```cobol
           MOVE "D" TO WS-TRANSACTION-TYPE
```

金額は `1.00` のままです。この入金は成功し、残高は `1100.25` から `1101.25` になります。

```text
口座=A000000001 CUSTOMER=C0001001 BALANCE=0001101.25
集計 記帳=003 拒否=002
```

`build/batch.log` のイベント番号 `004` はそのままで、種別と状態が次のようになります。

```text
EVENT=TRANSACTION NO=004 ACCOUNT=A000000001 TYPE=D STATUS=POSTED
```

不変条件を確認します。`3 + 2 = 5`。2 つの課題が示すのは同じ点です。モジュールインターフェース（Copybook のフィールド順と状態値）を変えずに**業務入力だけ**を変更するなら、件数やログ形式を調整する必要はありません。逆に Copybook のフィールド幅や順序を変えた場合は、影響するすべてのモジュールを再コンパイルして、ビルドを再実行しなければなりません。
