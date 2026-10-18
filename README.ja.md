<div align="center">

<img src="site-src/shire_200.png" width="160" alt="GnuCOBOL のシャイヤー馬マスコット">

# GnuCOBOL 実践コース

**最初の COBOL ステートメントから、動く銀行夜間照合システムまで。**

[![コースサイト](https://img.shields.io/badge/サイト-cobol.iamcheyan.com-76319f?style=flat-square)](https://cobol.iamcheyan.com/ja/)
[![レッスン](https://img.shields.io/badge/レッスン-32-2563eb?style=flat-square)](lessons/DIRECTORY.md)
[![言語](https://img.shields.io/badge/言語-日本語%20%C2%B7%20EN%20%C2%B7%20ZH-0d9488?style=flat-square)](#3-言語)
[![コンパイラ](https://img.shields.io/badge/GnuCOBOL-3.2-d97706?style=flat-square)](https://gnucobol.sourceforge.io/)

[简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [English](README.md)

</div>

---

## このリポジトリについて

**ここはコースサイトのソースです。** サンプルプログラムを置いただけのフォルダではありません。

[cobol.iamcheyan.com](https://cobol.iamcheyan.com/ja/) で読める各レッスンは、このリポジトリの Markdown です。
3 言語に翻訳され、ビルドスクリプトが静的サイトとして描画し、push のたびに GitHub Actions で実行されます。
**あなたが見ているサイトと、このリポジトリのファイルは同じもの**です。

コース自体は固定形式 GnuCOBOL の 32 レッスンで、最後は動く銀行照合バッチに到達します。ファイル処理、ソート、
突合、埋め込み SQL、モジュール化されたバッチ設計、エラー処理、ログ、そして卒業プロジェクトです。

<table>
<tr>
<td width="50%"><img src="docs/screenshots/en-home.png" alt="コースのホームページ"></td>
<td width="50%"><img src="docs/screenshots/en-lesson01.png" alt="タブ付きのレッスンページ"></td>
</tr>
<tr>
<td align="center"><sub>ホーム：6 ステージ・32 レッスン</sub></td>
<td align="center"><sub>各レッスンは 1 つの画面に：講義・演習・解答例・ソース</sub></td>
</tr>
</table>

## なぜこのコースを作ったか

日本の基幹系、保険、自治体のシステムでは、いまも COBOL のバッチが動いています。それを安全に変更できる技術者は、
補充より速く引退しています。足りないのは「COBOL の文法を覚えること」ではなく、**固定形式のバッチプログラムを読み、
データに何をしているか説明し、夜間バッチを止めずに変更できること**です。

だから各レッスンは実際のバッチ処理の形をした問題で組み立ててあり、主張はすべてコンパイルして動かせるコードで
裏づけています：

- **推測で書かない。** 各レッスンの期待出力は実際にコンパイル・実行して得たもので、解説中のバイト数も実測値です。
- **境界を明示する。** そのレッスンが扱わないことは README に明記します。コード以上の能力があるように見せません。
- **失敗も教材にする。** 終了コード、`FILE STATUS` の値、コピーブックが無い場合の挙動を、正常系と並べて扱います。

## コースサイト

サイトは言語ごとに完全なページツリーを生成します（`zh-cn/`、`en/`、`ja/`）。言語切り替え、ライト／ダークテーマ、
スマートフォン向けの折りたたみ式レッスン一覧を備えます。各レッスンでは講義・演習・解答例・ソースを 1 ページにまとめ、
ソースはファイル単位でプレビューとダウンロードができます。

<table>
<tr>
<td width="60%"><img src="docs/screenshots/en-plugins.png" alt="エディタプラグインの紹介ページ"></td>
<td width="40%" valign="top">

**Markdown に加えて、サイトが提供するもの**

- 32 レッスン · 3 言語 · 生成ページ 562
- レッスンごとに 4 つのタブ：講義・演習・解答例・ソース
- バイト配置・制御フロー・データの流れを説明するインライン SVG 図
- [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim) の紹介ページ（実際のスクリーンショット付き）
- 背景資料：COBOL とは、小史、GnuCOBOL 入門、リファレンス、用語集

</td>
</tr>
</table>

## クイックスタート

```sh
# 1. GnuCOBOL と make
sudo apt install gnucobol make
cobc --version          # GnuCOBOL 3.2.x であること

# 2. 最初のレッスンを読む
open lessons/01_hello-cobol/README.md

# 3. コース全体を検査
make course-check       # 32 レッスンの成果物 + 01–28 の構文検査 + 01 の実行
```

レッスン 29–32 は埋め込み SQL のツールチェーン（GixSQL + SQLite）を使います。レッスン 29 で
`install-toolchain.sh` を一度実行してから：

```sh
make course-check-sql   # 29–32 のプリコンパイル検査と、レッスン 32 のエンドツーエンド実行
```

## サイトをローカルでビルドする

```sh
python3 -m pip install 'Markdown==3.7'
python3 scripts/build_site.py        # build/site/{zh-cn,en,ja} を生成
python3 -m http.server -d build/site 8000
```

ビルドは Python と Markdown だけで動きます。Node のツールチェーンもフレームワークも不要です。`build/site/` は
Git の管理外で、`main` への push のたびに GitHub Actions がビルドしてデプロイします。

## リポジトリ構成

```text
lessons/            32 レッスンの本編
  01_hello-cobol/     README.md · exercise.md · answer.md · lesson.cob · assets/
   ...
  32_bank-reconciliation-project/
  DIRECTORY.md      カリキュラム全体：ステージ、前提、所要時間
  DIAGRAM-SPEC.md   図の描き方の規約
extensions/         任意の発展教材：旧版、企業バッチ、エディタのチュートリアル
scripts/
  build_site.py         3 言語の静的サイトを描画
  check_translations.py 翻訳カバレッジと構造の同一性チェック
  diagram_i18n.py       各図の中国語・日本語版を生成
site-src/
  site.css, theme.css, site.js   スタイルと動作
  translations/                  講義の英語・日本語版
  diagram-i18n.json              図中ラベルの翻訳
docs/screenshots/   この README で使う画像
Makefile            コース検査と発展教材の入口
```

## 3 言語

コースは中国語・英語・日本語で書かれています。各レッスンの講義・コメント・解答例は 3 言語そろっており、コードの
識別子とプログラム出力はそのままです。コンパイラとバッチが実際に見るものだからです。

- `README.md` — English
- `README.zh-CN.md` — 简体中文
- `README.ja.md` — 日本語（このファイル）

翻訳のカバレッジは**検証**されるもので、仮定ではありません。`scripts/check_translations.py` が元ファイルと
見出し数・コードフェンス・表の行数・リンク先・COBOL の非コメント行を比較し、誤った言語で書かれていれば失敗します。

## コースの検査

| コマンド | 内容 |
| --- | --- |
| `make course-check` | 全レッスンの成果物、01–28 の構文検査、01 のビルドと実行 |
| `make course-check-sql` | 29–32 のプリコンパイル検査と 32 のエンドツーエンド実行 |
| `make legacy-course-check` | 任意の旧版コースの検査 |
| `make standalone-check` / `standalone-run` | `extensions/` の独立サンプル 4 本 |

## コントリビュート

コースはコードであると同時にドキュメントなので、価値のある変更は機能追加より**説明の修正**であることがよくあります。

- **レッスンは「動く」までが完成ではない。** コンパイルして実行し、出力が講義と一致するか確認してください。
- **固定形式の規則を守る。** 1–6 列は空け、7 列目の `*` はコメント、Area A は 8 列目から、Area B は 12 列目から、
  プログラム本文は 72 列を超えないこと。
- **`-std=cobol85` を付けない。** 本コースは `COMP-3` と `FUNCTION TRIM` を使います。厳格な COBOL 85 には含まれないため、
  `cobc -x` でビルドしてください。
- **翻訳は忠実に。** 翻訳の変更を送る前に `python3 scripts/check_translations.py` を実行してください。

## クレジット

[GnuCOBOL](https://gnucobol.sourceforge.io/) を使っています。GnuCOBOL は 2002 年に日本の開発者 **西田圭介**氏が公開した
OpenCOBOL から始まりました。COBOL ソースを C に変換し、システムの C コンパイラーで実行プログラムを作る方式です。
現在は GNU プロジェクトの下で Simon Sobisch 氏らが開発を続けています。Debian/Ubuntu なら
`sudo apt install gnucobol` で導入でき、自宅の Linux でコースの固定形式コードをコンパイル・実行できます。
メインフレームは必要ありません。ただし、学習用に実行できることは、メインフレームの方言・データ表現・本番環境での動作が
すべて同じという意味ではありません。シャイヤー馬のマスコットは GnuCOBOL プロジェクトのものです。

エディタ用プラグイン [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim) は、固定形式の桁定規、構造ナビゲーション、
コピーブックのプレビュー、レコード長の計算、コンパイラ診断を提供し、このコースと組み合わせて使えます。

> 日本では基幹系システムで COBOL が現役です。なぜ今も必要なのか、GnuCOBOL がどこから来たのかは
> [サイトの背景ページ](https://cobol.iamcheyan.com/ja/about.html) で説明しています。
