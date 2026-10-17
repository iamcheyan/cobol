# 07.6 Boss L4：企業顧客大レコードのフィールド単位比較

本課では企業顧客snapshotの2バッチを比較し、どの名前付き業務フィールドが変わったかを調査します。V1は独立した1,778バイト固定バイナリインターフェースであり、CUSTOMER 27バイト、ACCOUNT v1 47バイト、TRANSACTION v1 55バイトは変更しません。推奨4時間。07.5を修了し、PIC、COMP、COMP-3、順次ファイル、RCに慣れておいてください。

## 実習手順

```bash
cd curriculum/modules/07-matching/labs/05-large-record
scripts/build.sh /tmp/batchl4
scripts/run.sh fixtures/old.dat fixtures/new.dat /tmp/b04-result
cat /tmp/b04-result/report.txt
(cd /tmp/b04-result && sha256sum -c manifest.sha256)
```

2ファイルは区切りのない固定レコードストリームで、総バイト長は1778の倍数でなければなりません。`fixtures/old.dat`には顧客1と3、新batchには顧客1、2、3があります。顧客2はNEW-ONLY、顧客1はrevision番号とclassificationが変化し、reportはfield IDを示します。FIELD/AUDIT差分行にはrun ID、入力版、旧/新レコードsequence、マスク済み顧客キー、field_id、canonical COBOLフィールド名が含まれます。同じフィールドへの変更が複数顧客にあっても対象レコードを特定できます。RC4は有効な業務差分、RC0は差分なし、RC8は入力構造エラー、RC12はbuild/lock/ファイル/公開障害です。targetは存在しない必要があり、実行は上書きしません。

## 先に計算し、その後プログラムを変更

`FIELD-CATALOG.csv`を開き、1始まりoffsetで`CUSTOMER_CLASSIFICATION`と`LEGAL_SURNAME`を手計算で切り出します。顧客1の旧/新レコード番号と差分フィールドを`evidence/student-template.md`に記録します。次に末尾の`SYNC_STATE`だけ変更したレコードを作ります。これは`IGNORE-AUDIT`なのでaudit-only件数は増えますが、業務差分RCは変わりません。姓の大文字小文字と右側空白だけを変更してTEXT-NORM上同値になることを試します。`starter/BATCHL4.COB`のTODOを実装し、`COURSE_SOURCE=/path/to/BATCHL4.COB`で実行します。未完成starterはRC12で終了し、公開してはいけません。

## バイトと配置

`DESIGN.md`はframing、ABI、NULL、比較規則、版方針を定義します。`copybooks/ENTERPRISE-CUSTOMER-V1.CPY`にgroup/leafフィールドがあり、canonical参考Copybookは`instructor/modules/07/05-large-record/`にあります。GnuCOBOL 3.2/Linux x86-64の実測ではPIC COMPはbig-endianです。COMP-5はこのインターフェースに含まれません。COMP-3は変換/比較前に各digit nibbleとC/D signを検証します。正負ゼロは数値上等価です。バイナリバイトをASCIIテキストとして検査しないでください。

## 変更調査：顧客classificationを1バイトから2バイトへ

このインターフェースではV1の1バイト`CUSTOMER_CLASSIFICATION`（A/B/C/D）を維持します。全consumer、sort/compare key、ファイル版、復旧経路を調べた後、独立したV2を設計します：フィールド幅PIC X(2)、layout版002、マッピングA1/B1/C1/D1。V1ファイルを直接書き換えてはいけません。旧batch拒否または変換、並行比較、切替、rollbackを説明します。`RECORD_STATUS`は別の意味なのでclassificationとして使えません。

## ツール経路

プラグイン利用者はCopybookとBATCHL4を開き、`gd`でフィールドへ移動、`K`でCOPY preview、Aerialで階層を見られます。ターミナルのみの代替は`rg -n 'CUSTOMER-CLASSIFICATION|COPY|READ|PERFORM' instructor/modules/07/05-large-record curriculum/modules/07-matching/labs/05-large-record`を使い、その後`awk`/Pythonでカタログoffsetに従って切り出します。Neovimプラグインは不要です。

`scripts/init-workspace.sh /tmp/b04-work`で新しい学習者directoryを初期化します。`scripts/reset.sh /tmp/b04-work`はファイル集合が完全で入力/結果hashが検証できた場合に限り`output/`を削除します。lock、未知ファイル、改変、symlinkがあれば拒否し、ソースと他の学習者ファイルは保持します。全受入入口は`bash scripts/check.sh`で、実フィールドoffset検査と比較意味のmatrixを含みます。
