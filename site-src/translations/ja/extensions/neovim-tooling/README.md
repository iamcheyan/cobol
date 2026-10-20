# Neovim エディター補助チュートリアル

本シリーズは**あなたのローカル Neovim 設定で実際に使っているツール**を扱います。2 種類に分かれます。

- **COBOL 専用**（01–07）：`cobol.nvim` が提供する固定形式ルーラー、構造ナビゲーション、PIC 計算、GnuCOBOL 診断。
- **汎用エディター機能**（08–23）：検索、ジャンプ、一括編集、コード理解、Git、セッション管理。

両者は補完関係にあります。COBOL 専用ツールは桁位置とコピーブックを扱い、汎用ツールは「数百行から目的を探す」「複数箇所を一度に変える」を扱います。

**メインコースの前提条件ではありません。** 必要に応じて参照する任意のツール資料です。チュートリアルは `extensions/standalone-examples/` と `lessons/` の実ファイルを使います。

## 動作環境

| 依存 | 用途 |
|---|---|
| Neovim 0.10+ | 全体 |
| `cobol.nvim` | 01–07、および COBOL の構造・診断 |
| Tree-sitter パーサー | ハイライトと折りたたみ（**COBOL は未対応**、16 参照） |
| GnuCOBOL（`cobc`） | 構文診断、コンパイル |
| Aerial、blink.cmp | 任意。無くても他機能は動作 |

## チュートリアル一覧

### 1. COBOL 専用：`cobol.nvim`

| # | テーマ | 学べること |
|---|---|---|
| [01](tutorials/01-punchcard-and-ruler.md) | 固定形式の列ルールとルーラー | 7/8/12/73 桁の意味、桁あふれ警告 |
| [02](tutorials/02-structure-and-navigation.md) | 構造概要・アウトライン・定義ジャンプ | `gd` / `gf` / `K`、Aerial アウトライン |
| [03](tutorials/03-pic-and-memory-calculator.md) | PIC とメモリ計算 | `:CobolCalcRecord` によるバイト数見積り |
| [04](tutorials/04-syntax-check-and-diagnostics.md) | 構文チェックと診断 | `cobc` 診断をエディターへ取り込み |
| [05](tutorials/05-compilation-and-workflow.md) | コンパイルとワークフロー | ビルド、実行、エラー特定 |
| [06](tutorials/06-practical-examples-guide.md) | 実践的なサンプル | 独立した 4 サンプルとプラグイン |
| [07](tutorials/07-cobol-nvim-plugin-lab.md) | プラグイン演習 | 総合演習 |

### 2. 検索とジャンプ

| # | テーマ | 学べること |
|---|---|---|
| [09](tutorials/09-snacks-picker.md) | ファイルと内容の検索（snacks picker） | `ff`/`fg`/`fw`、picker 内部キー、quickfix 連携 |
| [10](tutorials/10-flash-jump.md) | 画面内の高速ジャンプ（flash） | `s`/`S`、操作子との組み合わせ |
| [11](tutorials/11-grug-far.md) | ファイル横断の検索置換（grug-far） | `<leader>sr`、一致数の安全確認、段階的な置換 |
| [23](tutorials/23-quicker.md) | quickfix の文脈展開 | `>`/`<` で結果の前後を展開 |

### 3. 一括編集

| # | テーマ | 学べること |
|---|---|---|
| [08](tutorials/08-multicursor-batch-editing.md) | マルチカーソルによる一括編集 | `gaip`、`ciW`、`C`、`ci"`、`g<C-a>` |
| [12](tutorials/12-mini-ai-textobjects.md) | テキストオブジェクト（mini.ai） | 意味的境界での選択、`cia`/`ciq`/`g` |
| [13](tutorials/13-mini-surround.md) | 囲み記号（mini.surround） | `gsa`/`gsd`/`gsr` |
| [14](tutorials/14-smart-paste.md) | スマートペースト | 相対インデントを保ち、現在行に合わせる |

### 4. コード理解

| # | テーマ | 学べること |
|---|---|---|
| [15](tutorials/15-lsp-code-intelligence.md) | LSP によるコード理解 | ジャンプ/参照/リネーム、**COBOL に LSP は無い** |
| [16](tutorials/16-treesitter-and-folding.md) | Treesitter と折りたたみ | Treesitter の限界、COBOL の折りたたみの出所 |
| [17](tutorials/17-aerial-outline.md) | コードアウトライン（aerial） | `<leader>cs`、COBOL 専用 backend |
| [18](tutorials/18-conform-formatting.md) | コード整形（conform） | `<leader>F`、**自動整形は既定でオフ** |

### 5. Git

| # | テーマ | 学べること |
|---|---|---|
| [19](tutorials/19-gitsigns.md) | 行単位の Git 操作 | hunk のステージ／リセット、blame |
| [20](tutorials/20-diffview.md) | 完全な差分と履歴 | 並列 diff、ファイル履歴 |

### 6. セッションと発見

| # | テーマ | 学べること |
|---|---|---|
| [21](tutorials/21-auto-session.md) | セッションの保存と復元 | ディレクトリ単位のレイアウト |
| [22](tutorials/22-which-key.md) | キーの発見 | `<leader>`＋間、階層を順に展開 |

## おすすめの順序

**時間が限られている場合**、次の 4 本で日常作業の 8 割をカバーできます。

1. **[22 which-key](tutorials/22-which-key.md)** — まず他のキーの探し方を覚える
2. **[09 snacks picker](tutorials/09-snacks-picker.md)** — ファイル検索と内容検索
3. **[19 gitsigns](tutorials/19-gitsigns.md)** — 自分が何を変えたか確認する
4. **[08 マルチカーソル](tutorials/08-multicursor-batch-editing.md)** — 複数箇所を一度に変更

**COBOL コードを扱う場合**は、さらに：

5. [01 列ルール](tutorials/01-punchcard-and-ruler.md) — 固定形式の基礎
6. [17 aerial](tutorials/17-aerial-outline.md) — COBOL の段落構造

**コース文書を編集する場合**は、さらに：

7. [11 grug-far](tutorials/11-grug-far.md) — ファイル横断の一括置換
8. [20 diffview](tutorials/20-diffview.md) — 変更のレビュー

## 読み方の約束

各ページは同じ構成です。

| 節 | 内容 |
|---|---|
| 何を解決するか | 使わない場合のコストを比較表で示す |
| 実際の設定 | `lua/plugins/*.lua` から抜き出した実際の設定 |
| キー表 | あなたの設定で実際に使えるキー |
| 実測記録 | 実際のセッションでの観察（「実測」と明記） |
| 演習 | **合格条件**つきの具体的手順 |
| つまずきやすい点 | よくある失敗原因 |
| 公式ドキュメント | `:help` トピックとリポジトリ |
| 範囲と限界 | どの制約が設定由来か、プラグイン既定か |

**「実測」は実際に実行した操作にのみ付けています。** 未検証の手順は「まず練習してください」「未検証」と明記します。

## メインコースとの関係

32 課のメインコースは COBOL 言語そのものを教えます。本チュートリアルは**エディターで効率よく COBOL を書き換える方法**を教えます。

- メインコースは本チュートリアルに依存しません。
- ただし本チュートリアルはメインコースのファイルを頻繁に使います（第 17 課の定長レコード、第 20 課の照合、第 32 課の卒業プロジェクト）。
- 推奨：**先にメインコースの該当章を読み、その後チュートリアルで練習する**と最も効果的です。

## 参考

- Neovim 公式ドキュメント：`:help`
- あなたの設定リポジトリ：`~/nvim`
- プラグインごとの簡易リファレンス：`~/nvim/docs/plugins/PLUGINS.md`（47 プラグイン、各 5 小節。本チュートリアルより浅いが広くカバー）
