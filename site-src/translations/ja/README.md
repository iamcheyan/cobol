---
_translated_from: README.md
_translated_by: site-src/translation agent
---

# GnuCOBOL 実践コース

**最初の COBOL 文から、実際に動く銀行夜間照合システムまで。**

コースサイト：[cobol.iamcheyan.com](https://cobol.iamcheyan.com)（GitHub Actions がこのリポジトリの Markdown から静的ページを自動生成します）。

このリポジトリのトップページがコースの入口です。全32課を通じて、COBOL の基礎、データ配置、ファイル処理、ソート・マージ照合、データベース、モジュール化バッチを順に学び、最後に銀行照合の卒業プロジェクトを完成させます。

## 受講を始める

1. GnuCOBOL と Make をインストールします。
   ```sh
   sudo apt install gnucobol make
   cobc --version
   ```
2. [第01課](lessons/01_hello-cobol/README.md)から始めます。各課には解説、ソースコード、練習、参考解答があります。
3. [コース総目録](lessons/DIRECTORY.md)で全32課の順序、目標、所要時間の目安を確認します。

全32課の成果物を確認し、第01～28課の構文を検査して、第01課をコンパイル・実行するには、次を実行します。

```sh
make course-check
```

第29～32課では GixSQL + SQLite ツールチェーンを使います（最初に第29課で `install-toolchain.sh` を実行してください）。プリコンパイラーの検査と第32課のエンドツーエンドシナリオには、次のターゲットを使います。

```sh
make course-check-sql
```

## コース構成

- [`lessons/`](lessons/README.md)：全32課の本コース。第32課は実行可能な銀行照合の卒業プロジェクトです。
- [`extensions/`](extensions/README.md)：旧版コース、企業向け上級モジュール、独立サンプル、Neovim プラグインチュートリアルなどの任意教材です。
- [`Makefile`](Makefile)：本コースのチェックと、独立した拡張サンプルのチェック・実行用の入口です。

本コースの32課を修了すれば、コースを完了できます。拡張教材によって本課の順序や前提条件が変わることはありません。
