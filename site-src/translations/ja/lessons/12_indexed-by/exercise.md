---
_translated_from: lessons/12_indexed-by/exercise.md
_translated_by: site-src/translation agent
---
# 第 12 課演習：INDEXED BY

この課では第 11～12 課で学んだ内容だけを使用します。固定形式の宣言、`OCCURS` テーブル、通常の数値添字、`INDEXED BY` インデックス、`SET` / `PERFORM UNTIL` を使います。`SEARCH`、`SORT`、ファイル、データベースは使わないでください。

## 変更演習（参考解答は `answer.md`）

基準は本課の元の [`lesson.cob`](./lesson.cob) です。手順2は手順1のソースを引き継ぎ、各手順では指定された変更だけを行います。

### 手順1：口座テーブルを5項目に拡張

`WS-ACCOUNT-ENTRY OCCURS 4 TIMES` と `WS-LAST-ACCOUNT` の初期値をどちらも 5 にします。`1000-LOAD-ACCOUNTS` の末尾に5件目を追加します。口座番号は `0005550001`、残高は `75.00` です。

制約：

- 変更するのはこの3か所（容量、ロード済み件数、追加するロード文）だけです。最初の4口座は変更しません。
- ロード段落では引き続き通常の数値添字を使い、走査段落では引き続き `WS-ACCOUNT-IDX` を使います。ループ構造は変更しません。

次の順に実行してください。

```sh
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
```

実際の標準出力全体と終了コードを示し、最初の4行がバイト単位で変わらない理由を説明してください。

### 手順2：範囲外境界を観察

手順1の結果から、`WS-LAST-ACCOUNT` **だけ**を `6` に変更します（`OCCURS` は5のまま、5件目も最後のロード済み口座のままです）。

まず予測（標準出力の行数、最後の行の内容、終了コード）を書き、次のコマンドで確かめてください。

```sh
cobc -x -Wall -o build/lesson_12 lesson.cob
./build/lesson_12
cobc -x -fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT -o build/lesson_12_checked lesson.cob
./build/lesson_12_checked
```

`-fsubscript-check=full -fec=EC-BOUND-SUBSCRIPT` は、実行時に添字／インデックスの範囲を検査するよう GnuCOBOL に指示します。既定のコンパイルではこの検査は有効になりません。

2回の実行それぞれについて、標準出力全体、標準エラー、終了コードを示してください。検査を有効にしない場合にプログラムが成功したように見える理由と、このオプションが実行時に問題を検出できる理由を説明してください。

## 学んだことを応用する（解答なし）

5項目の口座テーブルを作り、`INDEXED BY` インデックスを宣言してください。

1. 通常の数値添字を使い、口座番号と残高を選んで少なくとも3口座をロードします。
2. インデックスで先頭から最後のロード済み項目まで走査し、口座番号、残高、処理件数を表示します。
3. テーブル容量、ロード済み件数、インデックスの現在位置、ループ終点の関係を説明します。
4. 終点が容量を超えた場合に検出できることを、どのコマンドで確認するか述べ、実際の結果を記録します。

制約：第 11～12 課の構文だけを使い、`SEARCH`、`SORT`、ファイル、データベースは使いません。コンパイルコマンド、実際の出力、終了コード、検証方法を記録してください。
