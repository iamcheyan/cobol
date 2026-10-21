# マルチカーソルによる一括編集：multicursor.nvim

COBOL の項目名変更、`PIC` 句の統一、状態コードの一括置換を 1 行ずつやるのは遅く、漏れも起きます。`multicursor.nvim` は必要な位置すべてにカーソルを置き、1 回の操作でまとめて変更します。

本ページはローカルの `lua/plugins/multicursor.lua` にある実際のキー割り当てに沿って説明します。プラグインに VS Code 風の `Ctrl-n`、`Ctrl+Shift+n`、`Ctrl-d` を追加し、行単位の追加やスキップのマッピングも残しています。

---

## 1. なぜ COBOL で特に有効か

COBOL のデータ宣言は本質的に繰り返しです。

```cobol
       01  WS-ACCT-ID          PIC X(10).
       01  WS-ACCT-NAME        PIC X(20).
       01  WS-ACCT-BAL         PIC 9(7)V99.
       01  WS-ACCT-STATUS      PIC X(1).
```

4 項目、ほぼ同じ 4 行です。次のような作業をするとき：

- `WS-ACCT-*` を `WS-ACCOUNT-*` に改名（宣言 4 箇所＋参照 3 箇所）；
- すべての `PIC X(...)` を `PIC X(100)` に広げる；
- 3 レコードの `VALUE "A"` を `VALUE "P"` にする；
- 6 行のプレースホルダに異なる連番を入れる。

単一カーソルでは「1 箇所変更 → `n` で次へ → また変更」になります。マルチカーソルでは「全位置にカーソルを置く → 1 回変更」です。

**違いは速度ではなく、漏れるかどうかです。** 1 箇所だけ漏れた COBOL プログラムは多くの場合コンパイルが通ります。その項目だけ古い幅のまま残り、実行時に初めて壊れます。

---

## 2. ローカル設定とキー割り当て

ローカル設定（`lua/plugins/multicursor.lua`）では、プラグインに VS Code 風のキーを追加しています。`Ctrl+Shift+n` を初回から確実に使えるよう eager load も設定しています。

| キー | モード | 動作 |
|---|---|---|
| `Ctrl-n` | Normal / Visual | カーソル下の単語または選択文字列の次の一致に追加 |
| `Ctrl+Shift+n` | Normal / Visual | 単語または選択文字列の全一致に追加 |
| `Ctrl-d` | Normal / Visual | 次の一致をスキップし、カーソルを追加しない |
| `<up>` / `<down>` | Normal / Visual | 上／下にカーソルを追加 |
| `<leader><up>` / `<leader><down>` | Normal / Visual | 1 行飛ばしてカーソルを追加 |
| `ga` + motion | Normal / Visual | motion に沿って追加。例：`gaip` |
| `<leader>a` | Normal | カーソル列を整列 |
| `<leader>gv` | Normal | 直前のカーソル集合を復元 |
| `<C-q>` | Normal / Visual | ほかのカーソルを一時停止／再開 |
| `<Esc>` | カーソル有効時 | カーソルを解除。停止中なら先に再開 |

プラグインのサンプル設定では `<leader>n`、`<leader>s`、`<leader>N`、`<leader>S` を使いますが、本機の一致検索キーは上表のとおりです。以降は本機の実際の割り当てを使います。

---

## 3. よく使う 5 つの操作

### アクション 1：1 行 1 カーソル（`ga`＋motion）

最も多用します。行を選択 → `ga` → motion。

```text
gg vip gaip
```

意味：先頭へ → ドキュメントを選択 → `ga` でカーソル追加モード → `ip`（段落）で**各行に 1 つ**。

視覚選択だけを対象にすることもできます（`V` で行選択 → `ga`、`mc.addCursorOperator` を割り当てている場合）。

実測（`02-unify-pic.cob` の最初の 4 行）：

```text
変更前                           gaip 後
│ 01 WS-ACCT-ID      PIC X(10). │ 01 WS-ACCT-ID      PIC X(10).
│ 01 WS-ACCT-NAME    PIC X(20). │ 01 WS-ACCT-NAME    PIC X(20).
│ 01 WS-ACCT-BAL     PIC 9(7)V99│ 01 WS-ACCT-BAL     PIC 9(7)V99
│ 01 WS-ACCT-STATUS  PIC X(1).  │ 01 WS-ACCT-STATUS  PIC X(1).
```

左端の `│` がカーソル表示です（`MultiCursorCursor`、反転表示）。

### アクション 2：桁を揃えた編集（`f`＋`C`）

カーソルを置いた後は、すべてのカーソルが**同じ 1 つの** vim コマンドに反応します。これが最重要のメンタルモデルです。

> **「カーソルごとに実行する」のではなく、「1 つのコマンドを全カーソルで実行する」。**

したがって各カーソルは意味的に同じ位置に置く必要があります。`fP` は「この行で前方の P を探す」なので、各カーソルは自分の行の `PIC` へ飛びます。

```text
gg gaip        " 各行に 1 カーソル（すべて 1 桁目）
fP             " 各自の行の PIC の P へ
C              " ここから行末まで変更
PIC 9(9).      " 新しい内容を入力
<Esc>          " 挿入モードを抜ける。カーソルは残る
```

実測結果：

```text
       01  WS-ACCT-ID          PIC 9(9).
       01  WS-ACCT-NAME        PIC 9(9).
       01  WS-ACCT-BAL         PIC 9(9).
       01  WS-ACCT-STATUS      PIC 9(9).
```

元の 4 つの `PIC` は長さが違います（`X(10)`、`X(20)`、`9(7)V99`、`X(1)`）。それでも `C` は**行末まで**変更するため、長さに関係なく完全に置換できます。

**必ず覚える落とし穴**：`cw`（1 単語だけ変更）を使うと `PIC` の 3 文字だけ置換され、後ろが残ります。`PIC X(10).` は `9(9) X(10).` になり、構文エラーです。

| コマンド | 範囲 | 向いている用途 |
|---|---|---|
| `cw` | 単語末まで | 単一の識別子 |
| `ciW` | 空白区切りの単語全体 | `WS-ACCT-NAME`（ハイフン含む） |
| `C` | **行末まで** | 「ここから先すべて」の置換 |
| `ci"` | 引用符内 | 文字列リテラル |
| `cc` | 行全体 | 行の書き換え |

### アクション 3：識別子を丸ごと置換（`ciW`）

`WS-CUSTOMER-ID` と `WS-CUSTOMER-NAME` は長さが違うため、`cw` はハイフンで止まります。識別子全体を置換するには `ciW` を使います。

```text
gg gaip            " 各行に 1 カーソル
w                  " 各自 2 番目の語（WS-CUSTOMER-xxx）へ
ciW                " 空白区切りの単語全体を選択
WS-CLIENT-XX       " 新しい名前を入力
<Esc>
```

実測：

```text
変更前                                    変更後
       01 WS-CUSTOMER-ID     PIC X(8).  →  01 WS-CLIENT-XX     PIC X(8).
       01 WS-CUSTOMER-NAME   PIC X(10). →  01 WS-CLIENT-XX   PIC X(10).
       01 WS-CUSTOMER-STATUS PIC X(1).  →  01 WS-CLIENT-XX PIC X(1).
```

`-` が `iskeyword` に含まれない場合、`ciw` はハイフンまでしか選択しません。`ciW` は空白境界を使うため、文字列全体を覆えます。

### アクション 4：`Ctrl+Shift+n` で全一致を選択

最初の 3 つは `gaip` で行ごとにカーソルを追加します。対象が繰り返し現れる文字列（例：`CUSTOMER`）なら、一致選択の方が直接的です。

```text
Visual モードで CUSTOMER を選択
Ctrl+Shift+n    " ファイル内のすべての CUSTOMER を選択
c               " すべての選択を変更
CLIENT
<Esc>
```

一部だけ変更する場合は `Ctrl-n` で 1 件ずつ追加し、変更しない一致は `Ctrl-d` でスキップします。

### アクション 5：引用符内の一括置換（`ci"`）

状態コード、区分値、固定リテラルの変更は最も頻度が高い作業です。

```text
gg gaip      " 各行に 1 カーソル
f" l         " 各自の行の最初の引用符へ、さらに 1 文字右へ
ci"          " 引用符内をすべて変更
N            " 新しい値を入力
<Esc>
```

実測（演習 `03-split-selection.cob`）：

```text
変更前                             ci" と N の後
01 WS-FLAG-A PIC X(1) VALUE "A".  →  ... VALUE "N".
01 WS-FLAG-B PIC X(1) VALUE "B".  →  ... VALUE "N".
01 WS-FLAG-C PIC X(1) VALUE "C".  →  ... VALUE "N".
01 WS-FLAG-D PIC X(1) VALUE "D".  →  ... VALUE "N".
```

4 つの異なる値が 1 回で同じ値になります。**`ci"` の範囲は「引用符内」なので、内容の長さは関係ありません。**

---

## 4. カーソルの管理とトラブルシュート

### カーソル数を確認する

```vim
:lua require("multicursor-nvim.core").action(function(ctx) vim.print("cursors=" .. ctx:numCursors()) end)
```

### よくある状態

| 表示 | 意味 | 復帰方法 |
|---|---|---|
| マーカーが `│` | 有効 | — |
| マーカーが `┃`（塗りつぶし） | `<c-q>` で無効化され、主カーソルだけ動く | `<c-q>` か `<Esc>` |
| マーカーが消えた | 全カーソルが解除された | 追加し直す |
| 1 行しか変わらない | 他のカーソルが想定位置にない | `:call cursor(行,桁)` で合わせてやり直す |

### `<c-q>` の本当の役割

「マルチカーソルを切る」のではなく、**他のカーソルを凍結して主カーソルだけを動かす**機能です。よくある使い方：3 つ追加したが 4 つ目の位置が違う → `<c-q>` で凍結 → 主カーソルを正しい位置へ → `<Esc>` で再開。

### `<Esc>` の 2 つの動作

ローカル設定では `<Esc>` は次のとおりです。

```lua
if not mc.cursorsEnabled() then
  mc.enableCursors()   -- 無効だった → 再開
else
  mc.clearCursors()    -- 通常状態 → 全解除
end
```

つまり**`<Esc>` を 1 回押すと全カーソルが消えます**。結果を確認したいときは反射的に押さないでください。

---

## 5. 5 つの演習

演習ファイルは [`exercises/multicursor/`](../exercises/multicursor/) にあり、すべて `cobc -fsyntax-only` を通過します。

### 演習 1：項目名の接頭辞を変更

`01-rename-field.cob` — `WS-CUSTOMER-*` を `WS-CLIENT-*` に変更（宣言 4 箇所＋`DISPLAY` 参照 4 箇所、計 8 箇所）。

```sh
cd extensions/neovim-tooling/exercises/multicursor
nvim 01-rename-field.cob
```

手順：Visual モードで `CUSTOMER` を選択 → `Ctrl+Shift+n` で全一致を選択 → `c` → `CLIENT` を入力 → `<Esc>`。

**合格条件**：8 箇所すべて変更され、`cobc -fsyntax-only 01-rename-field.cob` が通ること。

### 演習 2：PIC の統一

`02-unify-pic.cob` — 長さの異なる 4 つの `PIC` を `PIC 9(9).` に統一。

手順：`gg` → `gaip` → `fP` → `C` → `PIC 9(9).` → `<Esc>`。

**合格条件**：4 行すべてが `PIC 9(9).` で終わること。

**落とし穴の確認**：`cw` を使うと `9(9) X(10).` のような壊れた結果になります。元に戻して `C` を使ってください。

### 演習 3：リテラルの一括変更

`03-split-selection.cob` — 4 つの `VALUE "A"` `"B"` `"C"` `"D"` をすべて `"N"` に。

手順：`gg` → `gaip` → `f"` → `l` → `ci"` → `N` → `<Esc>`。

**合格条件**：4 行すべてが `VALUE "N".` になること。

### 演習 4：変更しない一致をスキップ

`01-rename-field.cob` で Visual 選択とスキップを練習します。

1. `WS-CUSTOMER` の `C` にカーソルを置き、Visual モードで `CUSTOMER` を選択します。
2. `Ctrl-n` で次の一致を追加します。
3. 変更しない一致では `Ctrl-d` を押してスキップします。
4. 残りの一致で `c` を押し、`CLIENT` と入力して `<Esc>` を押します。

**確認**：選択した `CUSTOMER` だけが `CLIENT` に変わり、スキップした一致は変わりません。
### 演習 5：総合

`05-fixed-format-batch.cob` — 2 回に分けて実施します。

1. 3 つの `VALUE "A"` を `"P"` に（`ci"`）;
2. 3 つの `PIC X(1)` を `PIC X(2)` に（`C`）。

**なぜ 2 回に分けるか**：2 つの操作は範囲が違います（引用符内と行末まで）。1 回に混ぜると互いに干渉します。これがマルチカーソルで最も重要な習慣です — **一度に 1 つのことだけ行う**。

---

## 6. COBOL 固定形式と併用するときの注意

COBOL には桁の規則があるため、次の点に注意します。

1. **`C`（行末まで）は 72 桁目以降の行末コメントも飲み込みます。** 事前に確認してください。
2. **`cc`（行全体）は 7 桁目の指示子を壊します。** コメント行（7 桁目が `*`）に `cc` を使わないでください。
3. **カーソル追加時の桁ずれに注意。** `gaip` は全カーソルを 1 桁目に置くので、`f`／`w` で各自移動させるか、ブロック選択で最初から桁を揃えてください。
4. **変更後は必ずコンパイル。** マルチカーソルは速く直せますが、速く壊れます。

```sh
cobc -fsyntax-only your-file.cob
```

---

## 7. クイックリファレンス

| 操作 | キー | 説明 |
|---|---|---|
| 下にカーソル追加 | `<down>` | 1 行ずつ |
| 上にカーソル追加 | `<up>` | 1 行ずつ |
| 1 行スキップして追加 | `<leader><down>` | 現在行を飛ばす |
| 次の一致に追加 | `Ctrl-n` | 単語／選択範囲の一致 |
| 次の一致をスキップ | `Ctrl-d` | 追加しない |
| 全一致に追加 | `Ctrl+Shift+n` | ファイル全体 |
| motion で追加 | `ga`＋motion | `gaip` で各行 |
| 主カーソル切替 | `<left>` / `<right>` | マルチカーソル時のみ |
| 現在のカーソルを削除 | `<leader>x` | マルチカーソル時のみ |
| 他カーソルを凍結／再開 | `<c-q>` | 主カーソルだけ動かせる |
| 全カーソル解除 | `<Esc>` | 通常状態 |
| マウスで追加 | `<c-leftmouse>` | Ctrl＋左クリック |

### テキストオブジェクトの選択

| コマンド | 範囲 | COBOL での用途 |
|---|---|---|
| `cw` | 単語末まで | 単一の単語 |
| `ciw` | 単語全体 | 識別子（`-` を含まない場合） |
| `ciW` | 空白区切りの単語全体 | `WS-ACCT-NAME`（ハイフンあり） |
| `C` | 行末まで | `PIC` 句全体 |
| `ci"` | 引用符内 | リテラル、状態コード |
| `cc` | 行全体 | 行の書き換え（コメント行には使わない） |
| `c` | 現在の選択 | `Ctrl+Shift+n` 後の一致テキスト置換 |

---

## 8. 公式ドキュメント

本ページはよく使う部分だけを、本機の設定に沿ったキーで扱います。全アクション一覧（`splitCursors`、`transposeCursors`、`alignCursors`、`operator`、診断系など）は同梱ヘルプを参照してください。

```vim
:h multicursor
:h multicursor-actions
:h multicursor-api
```

リポジトリ：<https://github.com/jake-stewart/multicursor.nvim>

---

## 9. 範囲と限界

- 本ページは現在の `lua/plugins/multicursor.lua` に基づいています。一致検索キーは `Ctrl-n`、`Ctrl+Shift+n`、`Ctrl-d` に変更されており、`ga`、`<leader>a`、`<leader>gv` もローカルで割り当てています。
- 「実測」の結果は Neovim 0.10 以降の実ターミナル操作によるもので、推測ではありません。カーソル記号（`│` と `┃`）はバージョンにより多少異なる場合があります。
- マルチカーソルは COBOL の意味を変えません。同じ編集を複数位置に適用するだけです。**最終判断は `cobc` のコンパイル結果に従ってください。**
