<div align="center">

<img src="site-src/shire_200.png" width="160" alt="GnuCOBOL のシャイヤー種馬マスコット">

# GnuCOBOL 実践コース

**最初の COBOL 文から、実際に動く銀行夜間照合システムまで。**

[![Live site](https://img.shields.io/badge/live-cobol.iamcheyan.com-76319f?style=flat-square)](https://cobol.iamcheyan.com/en/)
[![Lessons](https://img.shields.io/badge/lessons-32-2563eb?style=flat-square)](lessons/DIRECTORY.md)
[![Languages](https://img.shields.io/badge/languages-EN%20%C2%B7%20JA%20%C2%B7%20ZH-0d9488?style=flat-square)](#read-this-in-your-language)
[![Compiler](https://img.shields.io/badge/GnuCOBOL-3.2-d97706?style=flat-square)](https://gnucobol.sourceforge.io/)

[简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [English](README.md)

</div>

---

## このリポジトリについて

このリポジトリは、単なるサンプルプログラムの置き場ではなく、**コースサイトのソース**です。

[cobol.iamcheyan.com](https://cobol.iamcheyan.com/en/) で読める各課は、ここで Markdown として作成され、
3言語に翻訳されます。GitHub Actions で毎回の push 時に実行されるビルドスクリプトが静的サイトを生成します。
サイトで見られるものと、このリポジトリ内のファイルは同じ内容です。

コースは固定形式 GnuCOBOL の全32課で構成され、実行可能な銀行照合バッチの作成まで進みます。ファイル処理、
ソート、照合、Embedded SQL、モジュール化バッチ設計、エラー処理、ログ記録を学び、最後に卒業プロジェクトに取り組みます。

<table>
<tr>
<td width="50%"><img src="docs/screenshots/en-home.png" alt="コースのホームページ"></td>
<td width="50%"><img src="docs/screenshots/en-lesson01.png" alt="タブ付きの課ページ"></td>
</tr>
<tr>
<td align="center"><sub>コースホーム — 6段階、32課</sub></td>
<td align="center"><sub>すべての課を一つのワークスペースで：講義、練習、解答、ソース</sub></td>
</tr>
</table>

## このコースを作った理由

日本の銀行、保険、自治体の基幹システムでは、今も COBOL のバッチジョブが動いています。それを安全に変更できる
エンジニアは、後任が育つより速いペースで退職しています。必要なのは「COBOL の構文を学ぶ」だけではありません。
「固定形式のバッチプログラムを読み、データに何をするかを理解し、夜間処理を壊さずに変更できる」ことです。

そのため、各課は実際のバッチ処理に即した課題を中心に構成し、説明内容はコンパイルして実行できるコードで裏付けています。

- **曖昧な説明はありません。** 各課の期待出力は、プログラムを実際にコンパイル・実行して得たものです。解説中のバイト数も推定ではなく計測値です。
- **扱う範囲を明記します。** 課で扱わない機能については、コード以上の能力があるように見せず、README にその旨を記します。
- **失敗も教材の一部です。** 正常系とともに、終了コード、`FILE STATUS` の値、Copybook がない場合の動作も学びます。

## コースサイト

サイトは言語ごとに `zh-cn/`、`en/`、`ja/` の完全なページツリーを生成します。言語切り替え、ライト／ダークテーマに対応し、
モバイルではコース一覧を折りたためます。各課のページには講義、練習、解答、ソースファイルをまとめ、ファイルごとのプレビューとダウンロードを用意しています。

<table>
<tr>
<td width="60%"><img src="docs/screenshots/en-plugins.png" alt="連携エディタープラグインのページ"></td>
<td width="40%" valign="top">

**Markdown に加えてサイトが提供するもの**

- 32課 · 3言語 · 生成ページ562ページ
- 課ごとのタブ：ガイド、練習、解答、コード
- バイト配置、制御フロー、データ移動を示すインライン SVG 図
- 実際のスクリーンショット付き [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim) 紹介ページ
- COBOL とは何か、その歴史、GnuCOBOL 入門、リファレンスシート、用語集などの解説ページ

</td>
</tr>
</table>

## クイックスタート

```sh
# 1. GnuCOBOL と make
sudo apt install gnucobol make
cobc --version          # GnuCOBOL 3.2.x が表示されることを確認

# 2. 最初の課を読む
open lessons/01_hello-cobol/README.md

# 3. コース全体を確認
make course-check       # 全32課の成果物 + 01〜28課の構文検査 + 第01課の実行
```

第29〜32課では Embedded SQL ツールチェーン（GixSQL + SQLite）を使用します。第29課の `install-toolchain.sh` で一度インストールしてから、次を実行します。

```sh
make course-check-sql   # 29〜32課のプリコンパイル検査と第32課のエンドツーエンドシナリオ
```

## ローカルでサイトをビルド

```sh
python3 -m pip install 'Markdown==3.7'
python3 scripts/build_site.py        # build/site/{zh-cn,en,ja} を生成
python3 -m http.server -d build/site 8000
```

ビルドには通常の Python と Markdown を使い、Node ツールチェーンやフレームワークは不要です。`build/site/` は Git の対象外です。
GitHub Actions が `main` への push ごとにビルドしてデプロイします。

## リポジトリ構成

```text
lessons/            32課 — コース本編
  01_hello-cobol/     README.md · exercise.md · answer.md · lesson.cob · assets/
   ...
  32_bank-reconciliation-project/
  DIRECTORY.md      全課のシラバス：段階、前提知識、所要時間の目安
  DIAGRAM-SPEC.md   課の図の作成方法
extensions/         任意教材 — 旧版ワークショップ、企業向けバッチ、エディターチュートリアル
scripts/
  build_site.py       3言語の静的サイトを生成
  check_translations.py  翻訳カバレッジレポート + 構造忠実性チェック
  diagram_i18n.py     各課の図について zh-cn/ja 版を生成
site-src/
  site.css, theme.css, site.js   サイトのスタイルと動作
  translations/                  課のテキストの en/ja 版
  diagram-i18n.json              SVG 図のラベル翻訳
 docs/screenshots/   この README で使う画像
Makefile            コース検査と拡張教材の実行入口
```

## 各言語について

コースは中国語、英語、日本語で提供されています。各課の本文、コメント、解答は3言語で用意しています。
一方、ソースコードの識別子とプログラム出力は、コンパイラーとバッチ処理が実際に扱う内容なので変更しません。

- `README.md` — 英語（このファイル）
- `README.zh-CN.md` — 简体中文
- `README.ja.md` — 日本語

翻訳カバレッジは想定に頼らず、`scripts/check_translations.py` で管理しています。各翻訳の見出し数、コードフェンス、
表の行数、リンク先、COBOL の非コメント行を原文と比較し、誤った言語で書かれたファイルも失敗として報告します。

## コースの検査

| コマンド | 内容 |
| --- | --- |
| `make course-check` | 全課の成果物を確認し、01〜28課を構文検査して、第01課をコンパイル・実行 |
| `make course-check-sql` | 29〜32課のプリコンパイル検査と第32課のエンドツーエンド実行 |
| `make legacy-course-check` | 任意の旧版ワークショップを検査 |
| `make standalone-check` / `standalone-run` | `extensions/` の独立した4つのサンプル |

## コントリビュート

各課はコードであると同時にドキュメントでもあります。そのため、説明の誤りを直すことも有意義な貢献です。

- **プログラムが動いて初めて課は完成です。** コンパイルして実行し、出力が説明と一致することを確認してください。
- **固定形式の規則を守ってください。** 1〜6桁目は空白、第7桁目はコメントの `*`、Area A は第8桁目から、Area B は第12桁目から始まり、プログラム本文を第72桁より後に置かないでください。
- **`-std=cobol85` を追加しないでください。** このコースは厳密な COBOL 85 に含まれない `COMP-3` と `FUNCTION TRIM` を使います。通常の `cobc -x` でビルドしてください。
- **翻訳は原文に忠実に保ってください。** 翻訳を提出する前に `python3 scripts/check_translations.py` を実行してください。

## クレジット

[GnuCOBOL](https://gnucobol.sourceforge.io/) を使用しています。GnuCOBOL は **Keisuke Nishida** が2002年に公開した OpenCOBOL として始まり、
現在は Simon Sobisch らが率いる GNU Project のもとで開発されています。シャイヤー種の馬のマスコットは GnuCOBOL プロジェクトに由来します。

連携する Neovim プラグイン [`cobol.nvim`](https://github.com/iamcheyan/cobol.nvim) は、各課に取り組む際に使える固定形式の桁ガイド、
構造ナビゲーション、Copybook プレビュー、レコードサイズ計算、コンパイラー診断を提供します。
