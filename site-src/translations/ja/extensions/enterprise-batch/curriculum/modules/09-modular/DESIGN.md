# モジュール09 設計：呼び出し可能モジュールとインターフェース契約

## 1. 業務上の背景

夜間バッチでは、金額の記帳検証、顧客の有効性確認、統一形式のログ記録が複数のJOBで繰り返し必要になります。JOBごとに独自コピーを持つと、ルール変更のたびに差異が生まれ、障害調査でどのコピーが正しいか判断できません。本モジュールでは、この3つの処理を**呼び出し可能なサブプログラム**に切り出し、呼び出し側が**バージョン付きインターフェース**を介して再利用します。また、インターフェースの長さ/バージョン不一致や、サブプログラム内に未初期化の状態が残る場合に、呼び出し側と被呼び出し側の間で障害がどう伝わるかを示します。

GnuCOBOLの複数プログラムコンパイルでは、`cobc` で複数のソースファイルを一度にリンクできます。`PROCEDURE DIVISION` に `USING` がないプログラムが主プログラムで、それ以外の `PROGRAM-ID` は名前を指定した `CALL` で呼び出せるサブプログラムになります。本モジュールのコマンド：

```bash
cobc -Wall -I curriculum/modules/09-modular/copybooks \
     -I curriculum/bank/copybooks -x -o batch09 \
     BATCH09.COB AMTCALC.COB CUSTVAL.COB LOGGER.COB
```

## 2. ファイル契約（凍結、変更なし）

`BANK-SYSTEM.md` に従い、本モジュールでは次の契約を変更しません。

| レコード | 長さ | 主要フィールド |
|---|---:|---|
| CUSTOMER v1 | 27B | `customer_id`(8) `name`(10) `balance_demo`(8) `status`(1) |
| ACCOUNT v1 | 47B | 口座/顧客/通貨/符号/期首(13)/状態/業務日/`layout_version`(45–47=`001`) |
| TRANSACTION v1 | 55B | 口座/取引ID/業務日/連番/方向/金額(13)/状態 |

すべてASCII、LF終端で、LFは論理幅に含めません。口座は `account_id` の昇順、取引は `account_id`、`sequence_no`、`transaction_id` の厳密な昇順です。`transaction_id` は**業務全体の冪等キー**でもあり、取引全体で重複してはいけません（同一口座で連番が異なる場合も、口座をまたぐ場合も不可）。重複時はJOBがRC8を返し、何も公開しません。本モジュールは07の取消や台帳機能を縮小/除外し、CALLの意味に集中するため「顧客検証 + 金額記帳 + ログ」のみを扱います。

## 3. バージョン付き呼び出しインターフェース（`copybooks/`）

各インターフェースの先頭は固定の**長さヘッダー + バージョンヘッダー**です。呼び出し側は想定するレコード長とバージョンを設定し、被呼び出し側は自身の想定サイズを `LENGTH OF` で測定して比較します。不一致なら業務処理に入らずRC8（インターフェースエラー）を返します。これにより、慣習に頼って不一致時に異常終了するのではなく、引数長/バージョンの不一致を検出できます。

長さは、この環境のGnuCOBOL 3.2デフォルト方言で `LENGTH OF` により実測しました。

| インターフェース | 長さ | フィールド（記載順がオフセット順） | 意味 |
|---|---:|---|---|
| `AMT-CALC-INTERFACE` v1 | 45 | LENGTH(2,`COMP-5`) VERSION(3) OP(3) DIRECTION(1) AMOUNT-IN(13) BALANCE(`S9(13) COMP-3`,7) REASON(16) | 記帳計算。BALANCEは双方向 |
| `CUST-VAL-INTERFACE` v1 | 40 | LENGTH(2) VERSION(3) CUSTOMER-ID(8) NAME(10) STATUS-IN(1) REASON(16) | 顧客検証 |
| `LOG-INTERFACE` v1 | 54 | LENGTH(2) VERSION(3) SEVERITY(1) EVENT(8) MESSAGE(40) | ログ追記 |

`VERSION` は `001` 固定、このレッスンでの `AMT-IFACE-OP` は `PST` 固定です。呼び出し側は `MOVE LENGTH OF <interface> TO <interface>-LENGTH` を使い、障害実験を意図的に行う場合を除き、数値を直接記述してはいけません。

## 4. 引数渡しの意味と戻りコード

| 意味 | 本モジュールでの使用 | 観察点 |
|---|---|---|
| `BY REFERENCE`（デフォルト） | AMTCALC、CUSTVALのインターフェース | 被呼び出し側がインターフェース内のBALANCE/REASONを書き戻し、呼び出し側から変更が見える |
| `BY CONTENT` | LOGGERインターフェース | 被呼び出し側はコピーを受け取り、呼び出し側のフィールドを変更できない |
| `BY VALUE` | `scripts/ifaceprobe.COB` のみで実演 | 数値引数を値渡しし、被呼び出し側の変更は返らない |
| `RETURNING` | 3モジュールの各呼び出し位置で `... RETURNING WS-SUB-RC` | 被呼び出し側が設定した `RETURN-CODE` を受け取る |

**GnuCOBOL 3.2での実測事項**：被呼び出し側が `PROCEDURE DIVISION` に `RETURNING <item>` を記述すると、コンパイル時に `warning: program RETURNING is not implemented` が出て、実行時には不正なメモリへアクセスします。そのため被呼び出し側は `MOVE <rc> TO RETURN-CODE` の後に `GOBACK` し、呼び出し側は `RETURNING` で値を受け取ります。これはリポジトリ内の既存実装と同じ方式です。`BY VALUE` にも `-Wunfinished` 警告が出るため、本番モジュールでは使用せず、プローブだけで実演します。

RCの規約（コース共通）：

| RC | 意味 | 公開方針 |
|---:|---|---|
| 0 | すべて受理され、整合性検査に合格 | 公開 |
| 4 | 取引ごとの業務拒否がある | 検証済み結果を公開。呼び出し元JOBはRC4を明示的に許可する |
| 8 | インターフェース長/バージョン/操作、ファイル配置/日付/順序などの契約エラー | バッチ全体を失敗とし、公開しない |
| 12 | ファイルシステム、open/write、ビルド、公開などのシステム障害 | バッチ全体を失敗とし、公開しない |

主プログラムは各CALLの直後に `EVALUATE` で戻り値を検査します。8/12の場合は `STOP RUN` するため、失敗状態は**被呼び出し側で生成され、呼び出し側によってプロセスの終了コードへ正確に伝えられます**。

## 5. WORKING-STORAGEのライフサイクルと状態漏れ

- サブプログラムの `WORKING-STORAGE SECTION` は**デフォルトで静的**です。同一プロセス内の複数CALL間で値が保持されます。LOGGERはこれを意図的に利用し、`WS-SEQ` を増加させます。
- 毎回新しい状態が必要な処理まで静的領域に置くと、2回目の呼び出しで前回の値が残り、「2回目の呼び出しで未初期化残留が起きる」障害になります。`IS INITIAL` は各呼び出し前にそのプログラムの `WORKING-STORAGE` をリセットします。
- `scripts/ifaceprobe.COB` では最小のサブプログラム2つを比較します。`STATIC-ACC` は1回目/2回目に `0001/0002` を返し、`INIT-ACC`（`IS INITIAL`）は両方とも `0001` を返します。これが状態漏れの再現と最小修正です。
- 3つの業務モジュールにCALL間で共有する業務状態はありません（AMTCALC/CUSTVALは毎回再計算）。`check.py` の反復呼び出しケースで、隠れた共有状態なしに繰り返し結果が正しいことを確認できます。

## 6. 業務規則

**CUSTVAL**（戻り値0/4）：IDが数字でない場合は `BAD-ID`、氏名がすべて空白なら `CUST-NO-NAME`、状態 `A` は合格、`D` は `CUST-DISABLED`、その他は `CUST-BAD-STATUS`。インターフェース不一致は8です。

**AMTCALC**（戻り値0/4）：インターフェース不一致は8、金額が数値でない場合は `AMT-NOT-NUMERIC`、金額0は `ZERO-AMOUNT`、方向が `C/D` 以外なら `BAD-DIRECTION`、`new = balance ± amount` が13桁（`±9999999999999`）を超える場合は `OVERFLOW`、出金後に負数なら `OVERDRAFT`。それ以外は新しい残高と `OK` を書き戻します。金額は円の最小単位を整数で表し、浮動小数点は使いません。

**主プログラム**（RC4を決定）：取引状態が `N` 以外なら `TX-STATUS`、口座状態が `A` 以外なら `ACCOUNT-STATUS`、口座が見つからなければ `NO-ACCOUNT`。業務拒否は取引ごとに記録し、整合性検査には影響しません。契約エラー（長さ/日付/レイアウトバージョン/順序）は即時RC8です。

業務拒否理由の優先順位：`TX-STATUS` < `ACCOUNT-STATUS` < AMTCALC内部の検査順。インターフェース構造エラーは常にRC8で、取引ごとの拒否へ格下げしません。

**JOB全体での取引一意性**（CALL/記帳前に `run.sh` が実施）：account/sequence/idのストリーム突合で順序は保証できますが、`transaction_id` の全体一意性は**保証できません**。JOBは外部ソート（`cut -c11-26 | sort | uniq -d`。`sort` はメモリ使用量を抑えた外部マージ）で全体重複を検出し、重複があればRC8で公開しません。これは**JOBレベル**の一意性検査です。取引全体をメモリ配列に読み込まず、学習対象の順次突合アルゴリズムを置き換えず、学習者が `COURSE_SOURCE` を差し替えても回避できません。`oracle.py` は独立した集合で同種の重複（同じ口座で連番違い、口座間）を検査します。フィクスチャは `fixtures/invalid/dup-global-txid` と `fixtures/invalid/dup-cross-account` です。

## 7. 出力形式

`report.txt`（標準出力、1項目につき1行）：

```text
CUST|<id>|OK|<name>                       CUST|<id>|REJECT|<reason>
CUST-CONTROL|READ=<12>|OK=<12>|REJECT=<12>
POST|<acct>|<txid>|ACCEPT|<sign13>        POST|<acct>|<txid>|REJECT|<reason>
ACCT|<acct>|<sign13>
POST-CONTROL|ACCTS=<12>|NOTX=<12>|TX=<12>|ACCEPT=<12>|REJECT=<12>
  |OPENING=<sign18>|CLOSING=<sign18>|CREDIT=<18>|DEBIT=<18>
```

件数は12桁ゼロ埋めです。金額 `<sign13>` / `<sign18>` は符号を明示した固定幅数字、CREDIT/DEBITは符号なし18桁です。生成ファイル：`ledger.dat`（47Bの期末Master。符号と期首/残高フィールドのみ変更）、`customers-valid.dat`（27Bの受理レコード）、`customers-rejected.dat`（27Bの元レコード + `|` + 理由）、`batch09.log`、SHA256一覧2種、`run.txt`、`compiler.txt`、`source.sha256`。

`batch09.log` の各行はLOGGERが出力します：`<YYYYMMDD>|<seq:6>|<sev>|<event:8>|<message>`。GnuCOBOLの `LINE SEQUENTIAL` は末尾の空白を取り除くため、行幅は固定されません。独立モデルも同じように末尾を取り除きます。

## 8. 手計算例（normal）

顧客1/2はいずれも状態 `A` で合格します。口座1の期首は1000：T01で500を入金して1500、T02で200を出金して1300。口座2の期首は500：T03で100を入金して600。よって期末残高は1300/600、期首合計1500、貸方600、借方200、期末合計は `1500+600-200=1900` です。入力取引3件=受理3+拒否0、口座2件=取引あり2+取引なし0です。凍結口座のケースでは、その口座に取引が**届いています**（すべて拒否されます）。そのため `NOTX` には数えません。正しい基準は「口座に取引が届いたか」であり、「受理された取引があるか」ではありません。

## 9. 重要なレビュー項目

- インターフェースの長さ/バージョンやその他のマジックナンバーをハードコードしないでください。障害実験ではデータで障害を偽装せず、インターフェースヘッダーを明示的に変更します。
- 被呼び出し側が書き戻せるのはインターフェース項目と `RETURN-CODE` のみです。呼び出し側の非公開WORKING-STORAGEを読み書きしてはいけません。
- すべてのCALL後に戻り値を検査します。8/12を業務拒否として扱うこと、または失敗後に公開することは重大な欠陥です。
- `transaction_id` は**全体で一意**でなければなりません。同じ口座で連番が異なる場合も口座間の重複も、致命的なRC8です。account/sequence/id順の比較だけでは全体重複を見逃します。ファイル全体をメモリ配列に置き換えず、メモリ使用量が制限された方式を使います。
- 状態漏れは `ifaceprobe` で再現でき、`IS INITIAL` または明示的な初期化による最小修正が必要です。
