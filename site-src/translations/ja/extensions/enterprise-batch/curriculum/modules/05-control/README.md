# 05 プログラム制御とデータクレンジング（4時間）

推奨4時間。モジュール04修了後に取り組みます。カリキュラム05.1 IF/EVALUATE/PERFORM、05.2 SEARCH/SEARCH ALLおよびSTRING/UNSTRING/INSPECT/INITIALIZE、05.3 顧客ステータスの正規化と拒否理由分類に対応します。

業務要件：夜間バッチは顧客マスタを取り込む前に、上流から届くCUSTOMER v1の生ファイルをクレンジングする必要があります。上流は大文字小文字、必須項目、値の範囲を保証しないため、JOB002は各27バイトレコードを「受理」または「拒否」に分類し、拒否ごとに理由を記録し、**読込 = 受理 + 拒否**を証明します。クレンジング後の27バイトファイルが後続モジュールで使う顧客マスタになります。成果物はクレンジングプログラム`CLEANSE.COB`です。

## 1. 入力、形式、前提

- 入力はLF終端のASCII CUSTOMER v1ファイルです。各論理レコードは**27バイト**（**LFを除く**）：位置1–8 `customer_id`、9–18 `customer_name`、19–26 `balance_demo`、27 `status`。
- 前提：ファイルは`customer_id`昇順です（本モジュールはソートを担当しません。降順は契約違反です）。
- `status`は大文字小文字が混在する場合があります（クレンジング時に大文字の`A`/`D`へ正規化）。`balance_demo`は0から50,000,000までの合成実験用金額で、最終台帳ではありません。
- 業務日はマシンの現在日付ではなく、コマンドライン引数で渡します。`ACCOUNT/TRANSACTION`契約と同じ業務日である必要があります。形式は`YYYYMMDD`で、実在する日付でなければなりません。
- 境界/異常の前提：空ファイルは許可（0レコード）、欠落/読取不能ファイルはシステム障害です。短い行、長い行、CRLF、最終LF欠落、キー降順はファイル契約違反で、バッチ全体が失敗し公開されません。

## 2. clean checkoutからのビルド、実行、リセット

必要環境はLinux x86-64、GnuCOBOL 3.2、Bash、GNU coreutils、Python 3（受入確認のみ）です。macOS/WSLは未検証です。

```bash
lab=curriculum/modules/05-control
bash "$lab/scripts/build.sh" /tmp/cleanse      # 演習/参考実装をコンパイル
bash "$lab/scripts/run.sh" "$lab/fixtures/normal/clean.dat" \
  /tmp/bank-cleanse-normal 20261009            # 正式なJOB入口
bash "$lab/scripts/check.sh"                    # 全受入確認
bash "$lab/scripts/reset.sh" /tmp/bank-cleanse-normal   # リセット
```

`run.sh`が受け付けるのは、まだ存在しない新しい出力ディレクトリだけです。まず非公開のstageディレクトリに書き込み、検証に通った後で結果全体を公開します。派生ファイルはすべて出力ディレクトリ内にあります：`accepted.dat`、`rejected.dat`、`report.txt`、`run.txt`、`source.sha256`、`compiler.txt`、`inputs.sha256`、`outputs.sha256`、`customer.input.dat`（不変の入力snapshot）。`fixtures/`の原本や他モジュールの成果物を上書きしません。`reset.sh`はコース標識（`run.txt`/`inputs.sha256`/`outputs.sha256`/`report.txt`）があり、リポジトリ外にあるディレクトリのみを削除します。

## 3. 期待出力、RC、件数、金額

`report.txt`は入力レコードごとに1行、末尾にcontrol行を出力します。

```text
CUST|<id>|ACCEPT|<A|D>|<8桁金額>
CUST|<id>|REJECT|<reason>
CONTROL|BUSINESS-DATE=<YYYYMMDD>|READ=n|ACCEPT=n|REJECT=n|AMOUNT=18桁
```

`accepted.dat`は正規化済み27バイトレコード（ステータスは大文字）、`rejected.dat`は元の27バイト + `|` + 理由です。RC方針：

| RC | 意味 | 出力方針 |
|---:|---|---|
| 0 | 業務拒否なし。読込 = 受理 + 拒否 | 公開 |
| 4 | 業務拒否あり（下記）。ファイル契約は完全 | 拒否明細を含む検証済み結果を公開 |
| 8 | ファイル契約エラー：長さ、CRLF、最終LF欠落、降順、無効な業務日 | 全体を失敗させ、公開しない |
| 12 | ファイル/権限/システム障害 | 全体を失敗させ、公開しない |

業務拒否理由の一覧（**固定優先順位**、上から順）：

| 理由 | 発生条件 |
|---|---|
| `MISSING-ID` | `customer_id`が数値でない |
| `DUPLICATE-ID` | 数値IDが直前レコードと同じ（入力は昇順必須。降順はRC8） |
| `MISSING-NAME` | NULL文字を除去した後、`customer_name`が空白のみ |
| `BAD-AMOUNT` | `balance_demo`が数値でない |
| `AMOUNT-RANGE` | 金額は数値だが50,000,000超 |
| `UNKNOWN-STATUS` | 大文字化したstatusが`{A,D}`に含まれない |

**金額保存**：`AMOUNT`は受理された全レコードの金額合計（18桁の正確な10進数）です。拒否レコードの金額はいずれの合計にも含めません。`expected/`内のテキストはプログラム出力から逆算せず、**手計算例と業務規則**から独立に決めています。`check.py`はフィクスチャからaccepted/rejectedを独立に再構築してバイト単位で比較し、`report.txt`全体も比較します（全体trimはしません）。

## 4. 変更箇所と維持するインターフェース

課題：`starter/CLEANSE.COB`にクレンジング処理（ファイル読み込み、長さ判定、拒否分類、2種類の出力、control合計算出）を実装します。CUSTOMER v1の27バイト配置、業務日引数の意味、RC規約、reason codeの綴り、`ACCOUNT v1`/`TRANSACTION v1`契約を**変更しないでください**。参考実装は[`instructor/modules/05-control/CLEANSE.COB`](../../../instructor/modules/05-control/CLEANSE.COB)です。

## 5. 意図的な故障と復旧（再現可能）

1. `fixtures/normal/clean.dat`を一時ディレクトリへコピーし、最終LFを削除します。RC8、stderrに`MISSING-FINAL-LF`、公開なしが期待値です。
2. いずれかのレコードの`status`を`X`に変更します。RC4で`UNKNOWN-STATUS`を公開し、他のレコードは通常どおり処理します。
3. 2レコードのIDを同じ値にします。2件目はRC4 `DUPLICATE-ID`となり、読込 = 受理 + 拒否が保たれます。
4. 2レコードの順番を交換します。RC8 `UNSORTED-INPUT`、公開なし、原フィクスチャ不変が期待値です。

調査順：stderrのreason codeとRCを確認し、`report.txt`が入力レコードごとに対応することを確認し、最後に`sha256sum -c inputs.sha256`で入力snapshotが不変であることを確認します。

## 6. プラグイン操作とターミナルでの代替

- プラグイン：`:CobolGotoCopybook`で`COPY "CUSTOMER-V1.CPY"`を開き、27バイト配置を確認します。`:CobolCalcRecord`で各フィールドのバイト数を調べ、`gd`で段落へ移動し、ローカルルーラーでArea A/Bを確認します。
- ターミナル代替：`rg -n 'REASON|SEARCH|INSPECT|STRING'`、`awk '{print length($0)}'`、`od -An -tc`で改行と生バイトを調べます。どちらの方法でも同じ業務目標を達成できます。

## 7. 受入証跡と失敗条件

ソース、正常ケース、少なくとも1つのRC4ケースとRC8（公開なし）ケース、入力SHA256、読込 = 受理 + 拒否の保存、金額保存を提出します。テンプレートは[evidence/README.md](evidence/README.md)です。**失敗条件**：ログとアサーションが一致しない、RCとreason codeが不一致、失敗ケースで出力ディレクトリが公開された、または原フィクスチャが書き換えられた場合はいずれも失敗です。

## 8. 05.1 制御フローの小実験（PERFORM VARYING / inline / scope / fall-through）

[`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB)はカリキュラム05.1の4つの制御点を測る自己完結型プログラムです。`check.sh`が実際にコンパイル/実行し、各出力行をアサートします。

```text
VARYING=15    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 5（1+2+3+4+5）
INLINE=20     PERFORM 2 TIMES … END-PERFORM（inline PERFORM、独立したscope）
FIRST         PERFORM 2000-FIRST：この段落だけを実行し、終了時に戻る（scopeは段落境界まで）
SCOPE-DONE
FIRST         PERFORM 2000-FIRST THRU 3000-SECOND：3000-SECOND内の
SECOND        EXITまで実行し、制御が**次の段落へfall-throughする**。典型的なArea Bの落とし穴
THRU-DONE
```

学習者による変更：`PERFORM 2 TIMES`を`3 TIMES`にすると`INLINE`は30になります。`THRU 3000-SECOND`を削除すると`SECOND`行が消え、scopeが段落で終わることを確認できます。`UNTIL I > 5`を`> 3`にすると`VARYING`は6になります。未変更時の行ごとの出力は`check.py::check_control_flow`が固定します。

## 9. 05.2 言語の小実験（要素数とソート前提）

- [`scripts/language-probe.COB`](scripts/language-probe.COB)：未ソートの`raw=canonical` status mapを`UNSTRING`で読み込み、`INSPECT`で名前を正規化し、`SEARCH`でstatusを検索（線形検索は未ソートでも使用可）、`INITIALIZE`で出力を初期化し、`STRING`でレポート行を組み立てます。
- [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB)：同じキーをソート済み/未ソートで配置し、二分探索の`SEARCH ALL`では**宣言済みキー順にテーブルが実際に整列している必要がある**ことを示します。満たさないと存在するキーを見落とす場合があります。

両方とも`check.sh`がコンパイル/実行して出力を確認します。

## 10. カリキュラム要件 ↔ 実行可能な実習

各行は空ファイルやキーワードだけの例でなく、`check.sh`が確認する実在の実行可能なソース/フィクスチャを指します。

| カリキュラム要件 | ソース | 入力 | 学習者の変更/故障 | expected / check | 証跡 |
|---|---|---|---|---|---|
| 05.1 IF/EVALUATE | `instructor/.../CLEANSE.COB` `4000-PROCESS`（入れ子IF）、`3000-READ-RECORD`（EVALUATE） | `fixtures/*` | レコードの`status`を`X`へ変更 | `expected/invalid-unknown-status.txt`、`run_case`がバイト単位比較 | `evidence/README.md` |
| 05.1 PERFORM段落 | `CLEANSE.COB`のPERFORM 3000/4000/5000/6000 | `fixtures/normal/clean.dat` | `PERFORM 5000-EMIT-ACCEPT`をコメントアウト | 契約不変でなければ`check_protection`/`run_case`が失敗 | 同左 |
| 05.1 PERFORM UNTIL | `CLEANSE.COB` `1000-MAIN`、`3000-READ-RECORD`の読込ループ | 同左 | 終端条件`UNTIL EOF-FLAG = 1`を削除 | 無限読込/件数不一致で失敗 | 同左 |
| 05.1 PERFORM VARYING | [`scripts/control-flow-probe.COB`](scripts/control-flow-probe.COB) | なし（自己完結） | `UNTIL I > 5`を`> 3`に変更 | `check_control_flow`：`VARYING=15` | `evidence/README.md` |
| 05.1 inline PERFORM | 同上 | 同上 | `2 TIMES`を`3 TIMES`に変更 | `INLINE=20` | 同左 |
| 05.1 scopeと次段落へのfall-through | 同上（`PERFORM 2000-FIRST`と`THRU 3000-SECOND`） | 同上 | `THRU`を削除 | `FIRST/SCOPE-DONE/FIRST/SECOND/THRU-DONE` | 同左 |
| 05.2 SEARCH（線形、未ソート可） | [`scripts/language-probe.COB`](scripts/language-probe.COB) | 一時的な`map.txt`/`names.txt` | 未登録statusへ変更 | `NORM...UNMAPPED` | `check_probes` |
| 05.2 SEARCH ALL（ソート前提） | [`scripts/search-all-probe.COB`](scripts/search-all-probe.COB) | 自己完結 | `S-KEY`の順番を乱す | `SORTED=FOUND` / `UNSORTED=MISS` | 同左 |
| 05.2 STRING/UNSTRING/INSPECT/INITIALIZE | `language-probe.COB` | 同上 | `INSPECT … REPLACING`を削除 | `NORM|00000001|Alice|ACTIVE` | 同左 |
| 05.3 status正規化/必須項目/金額範囲/拒否分類 | `instructor/.../CLEANSE.COB` | `fixtures/normal`、`invalid`、`boundary` | status/名前/上限超過金額を変更 | `expected/*.txt`、`run_case`と`verify-publish.py`が独立再計算 | `evidence/README.md` |
