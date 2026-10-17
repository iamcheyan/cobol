---
_translated_from: lessons/27_logging/answer.md
_translated_by: site-src/translation agent
---

# 第 27 課の変更練習：参考解答

本解答は `exercise.md` の変更練習だけを扱い、応用練習には答えません。2 つの課題とも `build/` 作業ディレクトリで行います。

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

## 1. 2 件目の取引金額を有効値に修正する

`build/transactions.txt` の 2 行目を次のように変更します。

```text
A00002|00150
```

`(cd build && ./lesson_27)` を実行すると、このレコードの業務イベントは拒否から受理に変わります。

```text
EVENT=RECORD_READ NO=002 ACCOUNT=A00002
EVENT=RECORD_ACCEPTED NO=002 ACCOUNT=A00002
```

元の `EVENT=BUSINESS_REJECT ... REASON=BAD_AMOUNT` は出なくなり、`BATCH_END` は次のようになります。

```text
EVENT=BATCH_END INPUT=005 ACCEPTED=003 REJECTED=002 SYSTEM_ERROR=N
```

標準出力も連動して `集計 入力=005 受理=003 拒否=002` と `システムエラー=N` になり、終了コードは `0` のままです。`accepted.txt` は 3 行になり（`A00002|00150` が追加）、`rejected.txt` は 2 行になります。

不変条件を確認します。`5 = 3 + 2`、`ACCEPTED=003` は `accepted.txt` の 3 行と、`REJECTED=002` は `rejected.txt` の 2 行と一致します。

業務拒否は、すでに処理が完了した結果です。拒否が 1 件減ったのは受理が 1 件増えただけです。入力、出力、ログのファイル操作に失敗はないため、`SYSTEM_ERROR=N`、終了コードは `0` です。

## 2. 入力ファイルがない

`build/transactions.txt` を削除し（前の練習で残った結果ファイルも削除して）、`(cd build && ./lesson_27)` を実行します。標準出力は次のとおりです。

```text
エラー=OPEN_INPUT STATUS=35
集計 入力=000 受理=000 拒否=000
システムエラー=Y
```

終了コードは `1` です。`build/batch.log` の全内容は次のとおりです。

```text
EVENT=BATCH_START ID=TRAINING-001
EVENT=SYSTEM_ERROR OP=OPEN_INPUT STATUS=35
EVENT=BATCH_END INPUT=000 ACCEPTED=000 REJECTED=000 SYSTEM_ERROR=Y
```

順序は次のとおりです。ログを正常に開いた後、業務入力を開く前に `BATCH_START` を書きます。状態 `35` で入力を開けなかった後に `SYSTEM_ERROR` を書き、最後に `BATCH_END` を書きます。`SYSTEM_ERROR=Y` がこの実行は未完了だと明示するため、成功した空バッチと誤認しません。入力ファイルを一度も正常に開けなかったので `INPUT=000` です。
