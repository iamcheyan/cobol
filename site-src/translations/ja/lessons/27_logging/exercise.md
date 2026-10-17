---
_translated_from: lessons/27_logging/exercise.md
_translated_by: site-src/translation agent
---

# 第 27 課の練習：レコードを特定できるバッチログを作る

本節では、第 15〜27 課で扱った内容だけを使います。順次ファイル I/O、`FILE STATUS`、`STRING`、`EVALUATE`/`IF`、段落、`PERFORM` です。

## 変更練習（参考解答は `answer.md`）

リポジトリ内のフィクスチャを変更せず、`build/` 作業ディレクトリで 2 つの課題を行います。まず次の準備をします。

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_27 lesson.cob
cp transactions.txt build/
```

1. `build/transactions.txt` の `A00002|00X50` を `A00002|00150` に変更します。`(cd build && ./lesson_27)` を実行し、そのレコードのログイベントの変更前後と `BATCH_END` の件数を比較して、業務拒否が減ってもシステム障害ではない理由を説明します。
2. `build/transactions.txt` を削除して `(cd build && ./lesson_27)` を実行します。終了コード、標準出力のエラー行、`build/batch.log` に記録されたバッチ開始・システム障害・バッチ終了イベントの順番を記録します。

制約：`lesson.cob` と課内のフィクスチャは変更しません。どちらの課題でも件数の不変条件を確認します。`BATCH_END` で `INPUT = ACCEPTED + REJECTED` となり、`ACCEPTED`/`REJECTED` がそれぞれ 2 つの結果ファイルの行数と一致すること。参考解答は `answer.md` にあります。

## 応用練習（解答なし）

「口座番号の重複」を業務拒否ルールとして追加し、最初のレコード番号と重複したレコード番号をログに両方書きます。次に、異なるバッチ ID を使う 2 回連続の実行を設計します。ログだけで特定のバッチが完了したと判断する方法と、`BATCH_END` があってもすべての出力が原子的に納品された証拠にはならない理由を説明してください。

ソース、コンパイルと実行のコマンド、2 回分の `batch.log`、終了コードを提出します。顧客のプライバシー情報を丸ごとログに書かず、失敗したバッチの終了状態も省略しないでください。解答はありません。
