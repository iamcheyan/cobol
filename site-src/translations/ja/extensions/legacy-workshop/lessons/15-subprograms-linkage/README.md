# サブプログラム、CALL、引数の受け渡しと LINKAGE

## 学習目標

独立したプログラム単位、CALL USING、BY REFERENCE/CONTENT/VALUE、PROCEDURE DIVISION USING、LINKAGE SECTION、RETURNING。

このレッスンを終えると、上記の用語を自分の言葉で説明し、小さなプログラムの中から該当する宣言箇所や実行箇所を見つけられるようになります。構文を暗記するだけでなく、まず入力、出力、状態の変化を観察しましょう。

## サンプルコード

[`L15.COB`](./L15.COB) を開きます。このレッスンのソースファイルは固定形式を使用します。Division と段落は Area A から始まり、宣言文や実行文は Area B に記述します。主プログラム `L15.COB` は 7 を `DOUBLE-NUM.COB` に渡し、サブプログラムは LINKAGE で引数を受け取り、共有結果フィールドを通じて 14 を返します。

## コンパイルと実行

リポジトリのルートディレクトリから次を実行します。

```sh
mkdir -p build
cobc -fsyntax-only extensions/legacy-workshop/lessons/15-subprograms-linkage/L15.COB extensions/legacy-workshop/lessons/15-subprograms-linkage/DOUBLE-NUM.COB
cobc -x -Wall -o build/l15 extensions/legacy-workshop/lessons/15-subprograms-linkage/L15.COB extensions/legacy-workshop/lessons/15-subprograms-linkage/DOUBLE-NUM.COB
./build/l15
```

期待される出力は、まず `INPUT=0007`、続いて `RESULT=00014` です。

コンパイラが形式や桁位置のエラーを報告した場合は、まず 7、8、12、72 桁目を確認します。次にピリオド、変数の PIC、スコープ終端文を確認してください。`-Wall` は追加の警告を表示します。警告についても内容を理解してから対処するか判断しましょう。

## 順を追って理解する

1. `IDENTIFICATION DIVISION` はプログラム単位を宣言し、`PROGRAM-ID` はコンパイラが認識するプログラム名です。
2. `DATA DIVISION` はプログラムの実行時に使うデータを記述します。このレッスンにフィールド宣言がある場合は、レベル番号と PIC を確認しましょう。
3. `PROCEDURE DIVISION` は実行の入口です。`0000-MAIN` は読みやすさのための段落名にすぎず、自動的に繰り返し実行されることはありません。
4. 各文はソースコードの順序に従って実行されます。制御フロー文で経路が変わるか、`STOP RUN` でプロセスが終了するまで続きます。

## 変更の練習

サブプログラムを 3 倍の計算に変更します。無効な入力のチェックも追加しましょう。

変更するたびに、構文チェック、コンパイル、実行をやり直します。一度に変更する概念は一つに絞り、変更前後の出力を記録してください。

## cobol.nvim で学ぶ

プラグインの gd で CALL の呼び出し先に移動し（同じプロジェクトとして開いている場合）、アウトラインで入口と引数領域を確認します。

プラグインが反応しない場合は、まず現在のファイルタイプを確認します。`:set filetype?` を実行し、次に `cobc --version` を確認してください。プラグインは移動、レイアウトのヒント、診断に使います。プログラムをコンパイルできるかどうかの根拠となるのは、GNUCOBOL による実際のコンパイル結果です。

## 自己確認

- このレッスンの概念が何行目で宣言され、何行目で使われているか指摘できますか？
- 入力やフィールドの値が変わると、出力はどう変化しますか？
- このレッスンのテーマに関係する小さなエラーを意図的に起こし、コンパイラのメッセージを説明できますか？
- このサンプルを実際のバッチ処理プロジェクトに組み込む場合、どのような入力や失敗時の経路を追加で検証する必要がありますか？
