# 構造の概要、アウトライン、定義への移動

大型機の COBOL プログラムは、多数の `PERFORM` 段落と Copybook（`.CPY`）で構成されます。コードを読むときは、業務フローとデータ定義の関係をたどる必要があります。

最新の IDE 機能がなければ、段落名を `/` で手動検索し、複数のファイルを頻繁に切り替えることになり、思考が中断されがちです。このチュートリアルでは `cobol.nvim` を使い、Neovim でアウトラインを確認し、定義へ移動して元の場所に戻り、浮動ウィンドウでその場でプレビューする方法を紹介します。

---

## 1. COBOL の階層構造

COBOL プログラムは 4 つの Division で構成され、上から下へ決められた順に記述します。

```text
IDENTIFICATION DIVISION.       <-- 程序的身份证：程序名、作者、编写日期
ENVIRONMENT DIVISION.          <-- 运行环境与外部实体文件映射（SELECT ... ASSIGN TO）
DATA DIVISION.                 <-- 全局数据字典：文件记录结构（FILE SECTION）、工作变量（WORKING-STORAGE）
PROCEDURE DIVISION.            <-- 执行逻辑区：各种节（SECTION）与过程段落（PARAGRAPH）
```

`PROCEDURE DIVISION` の中では、次のように構成されます。
- **SECTION** は、関連する複数の Paragraph をまとめます。
- **PARAGRAPH** は、名前を持つ最小の実行単位です（関数に似ていますが、引数やローカル変数はなく、データはすべてグローバルフィールドで共有します）。
- 制御には `PERFORM <paragraph-name>`（サブルーチン呼び出しに相当）または `GO TO <paragraph-name>`（無条件ジャンプ）を使います。

---

## 2. プラグインのナビゲーション機能

1. **Winbar の動的パンくず**：ウィンドウ上部に、現在位置の Division / Section / Paragraph の階層を常時表示します。
2. **Aerial の構造アウトライン**：Aerial は任意で導入する Neovim 用アウトラインプラグインです。このプラグインの Aerial バックエンドは Division、Section、Paragraph、FD/SD、レベル 01 のレコードを表示します。`:AerialToggle` で開きます。このプラグインは `<leader>cs` を既定で割り当てません。
3. **段落やデータ定義へ移動（`gd`）**：`PERFORM 1000-INITIALIZE` や変数名にカーソルを置いて `gd` を押すと、定義へ移動します。
4. **移動元へ戻る（`<C-o>` / `<C-i>`）**：Neovim 標準の jumplist を使って前後に移動します。
5. **Copybook のプレビュー（`K`）**：`COPY "EMP-REC.CPY".` にカーソルを置いて `K` を押すと、浮動ウィンドウで内容を確認できます。`q` または `<Esc>` で閉じます。
6. **Copybook ファイルを開く（`gf`）**：`gf` を押すと、現在の `COPY` 文が参照する `.CPY` ファイルを開きます。
7. **データの親項目ヒント**：深くネストしたデータ項目の横に親項目名を表示します。
8. **Tree-sitter の構造範囲表示**：パーサーが利用できる場合、カーソルを含む最も内側の対応構造の開始・終了キーワードを強調し、接続線を描きます。`ELSE` / `WHEN` 分岐にもマーカーを表示できます。
9. **構造移動とテキストオブジェクト**：`%` で開始・終了キーワード間を移動します。`af`/`if`、`ae`/`ie`、`ap`/`ip` では、それぞれ IF、EVALUATE、PERFORM ブロックの内側または外側を選択します。

![IF、ELSE、END-IF の範囲マーカーと構造アウトライン](images/structure-scope.png)

Neovim の実画面です。Syms のアウトライン、Winbar のパンくず、現在の IF ブロックの開始・分岐・終了マーカーと接続線が表示されています。スクリーンショットにある Syms は外部のアウトライン UI です。プラグイン標準の Aerial バックエンドは下の画像を参照してください。

![Aerial の COBOL 構造アウトライン](images/aerial-outline.png)

Aerial は任意の依存関係です。画像ではアウトラインと COBOL ソースの連動を示しています。このプラグインは `<leader>cs` を既定で割り当てません。`:AerialToggle` でアウトラインを開くか、独自のショートカットを設定してください。

---

## 3. 実践演習

サンプルソースを開きます。

```bash
cd <仓库根目录>
nvim extensions/standalone-examples/INPUTCSV.COB
```

### 演習 2.1：Winbar の動的パンくず
1. ウィンドウ上部のパンくずが、カーソル移動に応じて変わることを確認します。
2. `IDENTIFICATION DIVISION` に移動すると、Winbar は `[ IDENTIFICATION DIVISION ]` と表示します。
3. `WORKING-STORAGE SECTION` 内のデータ項目に移動すると、`[ DATA DIVISION ]` と表示します。
4. `2100-PROCESS-RECORD` に移動すると、`[ PROCEDURE DIVISION > 2000-PROCESS-SECTION > 2100-PROCESS-RECORD ]` と表示します。
5. **ポイント**：コードを速くスクロールしていても、現在のコードがプログラム階層のどこにあるかをすぐに把握できます。

### 演習 2.2：Aerial の 3 階層アウトライン

Aerial は任意の Neovim 用アウトラインプラグインです。インストールして設定した後、`:AerialToggle` でアウトラインを開きます。このプラグインは COBOL のシンボルバックエンドを提供しますが、`<leader>cs` は既定で割り当てません。
1. `:AerialToggle` を実行して Aerial を開きます。
2. **サイドバーを確認します**。
   - 最上位ノード：4 つの Division（モジュールアイコン付き）
   - 2 階層目のノード：`WORKING-STORAGE SECTION`、`1000-INIT-SECTION` など
   - 葉ノード：`0000-MAIN`、`1000-INITIALIZE`、`2100-PROCESS-RECORD` などの Paragraph と、レベル 01 のルートレコード
3. サイドバーで `j` / `k` を使って `3000-PARSE-RECORD` に移動し、**`<CR>`** を押します。
4. **確認**：メインエディターが `3000-PARSE-RECORD.` へ滑らかに移動します。
5. メインウィンドウで `j` / `k` を使ってコード内を移動し、対応するアウトラインノードも連動して強調されることを確認します。
6. もう一度 `:AerialToggle` を実行してアウトラインを閉じます。

### 演習 2.3：段落や変数へ移動（`gd` / `<C-o>`）
日常の作業で特に役立つキー操作の組み合わせです。
1. `PERFORM 1000-INITIALIZE` に移動します。
2. `1000-INITIALIZE` にカーソルを置いて **`gd`**（Go to Definition）を押します。
3. **確認**：カーソルが `1000-INITIALIZE.` の段落定義へ移動します。
4. 処理を確認したら **`<C-o>`** を押します。
5. **確認**：カーソルが元の `PERFORM` 呼び出しに戻ります。
6. `INITIALIZE WS-FLAGS WS-COUNTERS.` に移動します。
7. `WS-FLAGS` にカーソルを置いて **`gd`** を押します。
8. **確認**：カーソルが `01 WS-FLAGS` の宣言行へ移動します。
9. もう一度 **`<C-o>`** を押して元の位置に戻ります。

> 💡 **ヒント**：`gd` と `<C-o>` を組み合わせると、定義間を何度も検索することなく、前後に行き来できます。

### 演習 2.4：Copybook のプレビュー（`K`）とオープン（`gf`）
COBOL では C の `#include` のように、データ構造の再利用に Copybook をよく使います。
1. `COPY "EMP-REC.CPY".` に移動します。
2. ホバープレビューのショートカット **`K`** を押します。
3. **確認**：画面中央に浮動ウィンドウが開き、`EMP-REC.CPY` の内容が表示されます。
   ```cobol
          01  EMP-RECORD.
              05  EMP-ID                   PIC X(05).
              05  EMP-NAME.
                  10  EMP-FIRST-NAME       PIC X(10).
                  10  EMP-LAST-NAME        PIC X(10).
              05  EMP-DEPT                 PIC X(02).
                  88  DEPT-SALES           VALUE "01".
                  88  DEPT-DEV             VALUE "02".
                  88  DEPT-HR              VALUE "03".
              05  EMP-SALARY               PIC S9(7) COMP-3.
              05  EMP-STATUS               PIC X(01).
   ```
4. **`q`** または **`<Esc>`** を押して閉じます。エディターは元の位置に留まります。
5. 同じ行で **`gf`**（Go to File）を押します。Neovim がパスを検索し、編集用に `.CPY` ファイルを開きます。`:bd` または `:b INPUTCSV.COB` でメインファイルに戻ります。
6. `PERFORM 2000-PROCESS-FILE` にカーソルを置いて **`K`** を押すと、その Paragraph のコードをプレビューできます。`q` で閉じます。

### 演習 2.5：ネストしたデータ項目の親ヒントを確認する
1. `10  IN-FULL-NAME         PIC X(80).` に移動します。
2. **行末を確認します**：階層ヒントが有効なら、`← 05 IN-NAME-GROUP (01 WS-INPUT-FIELDS)` のように表示されます。
3. `88  CONVERT-SUCCESS      VALUE "S".` に移動します。
4. **行末を確認します**：同様に親項目のヒントが表示されます。
5. **考えてみましょう**：深くネストした大規模な COBOL レコードでも、インデントを数えて親項目を探す必要がなくなります。

---

![Copybook の浮動プレビューウィンドウ](images/copybook-preview.png)

`COPY` 文で `K` を押すと、現在の編集位置を離れずに Copybook をプレビューできます。

## 4. クイックリファレンス

| キー／コマンド | モード | 動作 |
|---|---|---|
| `:AerialToggle` | コマンドライン | 任意の Aerial アウトラインを開閉（インストールと設定が必要） |
| `gd` | Normal | Paragraph 名、変数、Copybook から定義へ移動 |
| `<C-o>` | Normal | Neovim 標準のジャンプリストで前の位置へ戻る |
| `K` | Normal | Copybook または対象 Paragraph のコードを浮動ウィンドウでプレビュー。`q` で閉じる |
| `gf` | Normal | 参照先の Copybook を編集用に開く |
