---
_translated_from: lessons/23_copybooks/exercise.md
_translated_by: site-src/translation agent
---
# 第23課の練習：共有レコード宣言と利用プログラム

この課では `lesson.cob`（`PROGRAM-ID. LESSON23`、取引記帳）と `account_report_23.cob`（`PROGRAM-ID. ACCOUNT-REPORT23`、口座レポート）の2つが `copybooks/ACCOUNT-REC.CPY` を使います。変更はこの課の**作業用複製**で行い、リポジトリー内の元ファイルは変更しないでください。

共通条件：

- すべてのコマンドをこの課のディレクトリから実行します。`-I copybooks` が検索先です。指定しないと、構文確認でも `ACCOUNT-REC.CPY: そのようなファイルやディレクトリはありません` と報告されます。
- **リポジトリーのファイルを直接変更しないこと。** 2つの `.cob` と2つの `.CPY` を `build/work` に複製し、以後のコマンドはそこで実行します。最後に `rm -rf build` で削除します（`build/` はGit対象外）。
- Copybook変更後は実行前に**再コンパイル**します。古い実行ファイルには変更が反映されません。

```sh
rm -rf build && mkdir -p build/work/copybooks
cp lesson.cob account_report_23.cob build/work/
cp copybooks/* build/work/copybooks/
cd build/work          # 以降の確認・コンパイル・実行はここ
```

変更前の基準出力：

```text
入账成功 类型=D 金额=0000125.50
入账成功 类型=C 金额=0000025.25
入账拒绝 原因=INSUFFICIENT
入账拒绝 原因=BAD_TYPE
入账拒绝 原因=NO_ACCOUNT
账户号码=A000000001 客户号码=C0001001 余额=0001100.25
成功笔数=002 拒绝笔数=003
```

レポートプログラムは `口座レポート 口座番号=A000000009 顧客番号=C0001009 残高=0000020.00` を出力します。

## 変更練習（解答は [`answer.md`](./answer.md)）

### 1. 共有宣言の幅を変更する

- **基準：** 元の `copybooks/ACCOUNT-REC.CPY`、`lesson.cob`、`account_report_23.cob` を `build/work` に複製。
- **変更と制約：** `ACCOUNT-REC.CPY` の `05 WS-ACCOUNT-NUMBER PIC X(10).` だけを `PIC X(8).` にします。`MOVE` の文字列と `TRANSACTION-REC.CPY` は変更しません。
- **コマンド：** 両プログラムに `cobc -fsyntax-only -I copybooks` と `cobc -x -Wall -I copybooks` を実行し、[`README.md`](./README.md) のとおり両方を実行します。
- **答えること：**
  1. 各コンパイルは何を表示しますか。構文確認に `-Wall` を付けた場合は結論が変わりますか。
  2. `lesson_23` の7行出力は変わりますか。どの行か、残高と2つの件数はいくつですか。
  3. 口座レコードの物理幅はいくつになり、第17、20、22課の固定長契約に何が起きますか。
  4. 短い英数字オペランドへの空白補完を含め、COBOL比較規則で取引結果を説明してください。

### 2. メインプログラムの業務定数だけを変更する

- **基準：** 演習1とは別に新しい `build/work` 複製を作ります。
- **変更と制約：** `lesson.cob` の `1500-POST-MISSING-ACCOUNT` で `MOVE "A000000099" TO WS-TRANSACTION-ACCOUNT` を `MOVE "A000000001" TO WS-TRANSACTION-ACCOUNT` にします。Copybookや他段落は変更しません。
- **コマンド：** 再ビルドが必要な利用プログラムをコンパイルして実行します。
- **答えること：** 5件目はどこへ行き、残高と2件数はいくつですか。再コンパイルが必要な利用側と既存実行ファイルを使える側を理由とともに説明します。

## 発展課題（解答なし）

月次明細用の第3利用プログラム（例：`monthly_statement_23.cob`）を作り、同じ `ACCOUNT-REC.CPY` を使います。借方残高用に符号付きPICへ変更します。

- `S9(7)V99` または `S9(7)V99 SIGN LEADING SEPARATE` を選び、共有レコード幅を測ります。`FUNCTION LENGTH`、または固定長ファイルと `wc -c` / `od -An -c` を使えます。
- マイナス記号が出る表示項目を選び、元の `PIC 9(7).99` では足りない理由を説明します。
- 実際に借方残高を生じさせます。変更した記帳規則と、課の範囲を超えるかを示します。
- 元と新しい利用側の完全なコンパイルコマンド・標準出力を提出し、27バイト契約が維持されたか結論を示します。

利用プログラムの一方だけを再コンパイルしないでください。コンパイル時の `COPY` を実行時 `CALL` と説明してはいけません。解答はありません。
