# Boss L3：顧客日次集計 N:N 突合

## 業務意味と段階境界

L3は顧客を集計業務キーにします。1顧客にはN口座があり、各口座に当日のM取引がありえます。N口座とM取引は同じ顧客グループに属しますが、口座×取引で個別に対応付けず、直積も作りません。取引は`ACCOUNT.customer_id`を通して1顧客にのみ帰属し、口座金額と顧客のaccepted取引をそれぞれ1度だけ集計します。Snapshotとprevious-dayは顧客ごとに各1レコードです。

JOB入口はACCOUNT v1、TRANSACTION v1、REVERSAL-LINK v1、CUSTOMER-SNAPSHOT v1、PREVIOUS-DAY v1を受け付けます。runnerは生ACCOUNT/TRANSACTION/REVERSAL-LINKを、検証済みB01実L2 JOBへ先に渡します。L2が凍結/閉鎖、金額0、当座貸越/overflow、別口座、任意の過去取引への取消を含む既存方針を担当します。L3はL2のaccepted元取引、rejected元取引、closing master候補のみ消費し、再計上しません。L2がRC0/RC4で候補検証を通過すればL3を続行します。L2 RC8/12ならbatch全体を停止します。B03は顧客突合と「後で更新可能」な隔離候補を生成するのみで、DBを更新しません。CUSTOMER-SNAPSHOTはオフライン固定バイトseedで、DB由来やモジュール08完了を主張してはいけません。

## 日付とバージョン

ACCOUNTはcanonical v1 layout `001`で今回のBUSINESS_DATEと一致が必須です。TRANSACTIONは独立版フィールドを持たない既存の固定TRANSACTION v1 55B契約を使用し、BUSINESS_DATEと一致が必要です。Snapshot日付はBUSINESS_DATEと等しく、Previous-DayはJOB日の前のGregorian暦日です。**銀行営業日カレンダーを適用しません**。入力は厳密幅ASCII+LF、正しいフィールド、キー一意かつ昇順でなければなりません。新規CUSTOMER-SNAPSHOT v1 36BとPREVIOUS-DAY v1 39Bフィールドは[FIELDS](FIELD-CATALOG.md)と独立Copybookを参照してください。日付/版/構造/順序/重複キーの誤りはRC8で、公開せずbatch全体を失敗させます。欠落/古いsnapshotを過去snapshotで代替してはいけません。

## 集計、N:N照合、隔離方針

顧客`c`について次を定義します。

- `A(c)`：ACCOUNT v1で`c`に関連する口座集合。期首`opening(c)`と口座数`accounts(c)`を集計します。件数と残高はACCOUNT status A/F/Cすべてを含みます。凍結/閉鎖はL2取引受理方針に影響しますが、顧客集計から口座を除外しません。
- `T(c)`：L2 acceptedのうちACCOUNT account_idを介して`c`に関連する取引集合。各件を1度だけ数え、`credit(c)`、`debit(c)`、`tx_count(c)`を計算します。
- `P(c)`：PREVIOUS-DAY内の昨日の顧客サマリー1件。`previous_accounts(c)`と符号付き`previous_close(c)`を持ちます。
- `S(c)`：CUSTOMER-SNAPSHOT内の顧客レコード1件。statusおよび顧客口座/残高上限を持ちます。

構造的に完全でS/Pが存在し、顧客statusがAの場合、以下が必要です。

1. 現在の口座期首集計が前日顧客closingと一致し、口座数もA/F/Cを含む前日の全関連口座数と一致。
2. `expected_close = previous_close + accepted_credit - accepted_debit`。
3. L2の口座別closingを顧客単位で再集計した値が`expected_close`と一致。
4. 現口座数は` snapshot.max_account_count`以下、顧客closingは`snapshot.max_customer_balance`以下。
5. すべてのACCOUNT/L2 accepted TXが唯一の顧客に対応し、Snapshot/Previous各行を1度だけ消費するか孤児差異として出力。

Snapshot/Previous欠落、Snapshot顧客status D、口座数/上限差異、期首と前日不一致、集計額とL2 closing不一致は顧客単位の業務拒否RC4です。その顧客の関連口座/取引をすべて隔離reportへ出し、`eligible-master.dat`/`eligible-transaction.dat`から除外します。JOB006 DB更新へ渡してはいけません。他の構造的に有効な顧客は公開可能です。孤児Snapshot/Previous行は独立したsource差異として消費し、レコードキーを示します。RC4出力には理由、customer_id、source key/件数/金額が必要で、業務拒否をstdoutのみにしてはいけません。

元ACCOUNTとL2 closing masterを順次1行ずつ対応させ、残高以外の元47Bバイトはすべて一致しなければなりません。当日accepted取引による残高変化は許可しますが、口座ごとにopening + accepted credit - accepted debit = L2 closingを独立確認します。その後顧客単位で期首/期末を集計します。重複/降順行、幅/ASCII/日付/版不正、口座/顧客重複、全体transaction ID重複、唯一のACCOUNTに対応しないaccepted TX、残高以外のバイト変更、保存不一致は構造/実行契約エラーRC8/12で、公開しません。L2 `rejected.dat`は元取引バイトと理由をB01業務controlとして保持し、L3 accepted取引金額には含めません。全体では個別に以下を照合：元ACCOUNT数 = eligible master数 + 隔離口座数；L2 accepted件数 = eligible accepted TX件数 + 隔離accepted TX件数；accepted貸方/借方合計 = 各eligible額 + 隔離額。L2 rejected件数は別に保ち、acceptedや隔離額に含めません。

## 4ストリームの状態と消費表

元ACCOUNTとL2 accepted取引のキーはaccount_idです。`customer_id`はaccount_idと単調関係にないため、口座走査中にcustomer snapshot pointerを直接比較して進められません。本実装ではCOBOLがsource key付きで口座/取引を顧客に関連付け、固定2Mの`COB_SORT_MEMORY`で派生顧客streamをsortし、顧客キーによる有界4方向mergeを行います。中間レコードには元account/transactionバイトとaccount_idを保持してsource証拠にします。4ストリームの顧客グループを消費し終わるまで顧客単位判断はできません。そのためcoreは顧客ごとに口座/取引source recordをディスクspoolへ書き、保存式と上限を確認します。合格時はspoolを順にeligible候補へ再生し、拒否時は各行をsource位置付き隔離記録として再生、spoolを空にして次の顧客へ進みます。メモリ保持はキー、件数/金額累計、現在レコード1件のみです。グループサイズは一時ディスクに影響するだけで、全グループ配列は作りません。

| 比較状態 | 出力/累計 | 進め方 |
|---|---|---|
| 任意streamがEOF | 独立EOF boolean。ゼロ/全9番兵値を使わない | EOF済みはREADせず、残る非EOF sourceを処理 |
| 最小customer keyがAccountのみ | 1件以上の口座opening/件数を合計。Snapshot/Previous欠落ならRC4で隔離 | 対応するaccount streamの現在顧客グループのみ進める |
| 最小keyがAccepted-TXのみ | ACCOUNTと対応できなければRC8。貸方/借方/件数を各1度だけ合計 | 該当streamの現在顧客グループのみ進める |
| 最小keyがSnapshotまたはPreviousのみ | 孤児source差異を出力し、行を捨てない | そのsnapshot streamの単行を進める |
| 複数streamの最小keyが等しい（`=`） | 顧客の全sourceを有界累計器に統合し、保存式を確認。MATCHまたは具体的差異を出力 | 参加streamの同一key行を消費し、グループ後に次行を読む |
| Account/Transaction customer key `<`他stream | この顧客口座/取引グループを完了。source欠落はRC4で隔離 | 小さいkeyのsourceだけ進め、他は進めない |
| Snapshot/Previous customer key `<`他stream | 該当する孤児snapshot/前日行を出力 | 小さいsnapshot streamを進める |
| 顧客keyが複数streamで交差 | 非EOF streamの最小keyを処理。重複全キー/顧客は事前検査RC8 | 消費ごとに唯一source件数が増えること |

**主な手計算trace：**ACCOUNTをaccount_id順に見るとA1→customer02 opening1000、A2→customer01 opening2000、A3→customer02 opening3000です。取引はA1 C50/D20、A2 D100、A3 C70です。customer順sort後、A streamはcustomer01(2000)、customer02(1000+3000)。T streamはcustomer01 D100、customer02 C50/D20/C70。Snapshotはcustomer01 statusA max_account_count1 max_balance8000、customer02 A/2/10000。Previous-Dayはcustomer01 account_count1 close2000、customer02 account_count2 close4000。期末は顧客01が1900、顧客02が4100。全体は口座3件、取引4件、期首6000、貸方120、借方120、期末6000です。各TXは1口座を通して1顧客へ寄与します。customer02 snapshotの件数/金額は1度だけ検査し、A1/A3に別々に複製しません。

4 cursor traceは元account keyでなくcustomer keyを使用します。開始時A=01、T=01、S=00、P=01で、`S<A/T/P`のためSnapshot-only 00を出しSのみ進めます。次に全キー01となり、`=`で各sourceのcustomer01 groupを1度消費します。進めた後は全キー02でcustomer02を処理します。最後はA/T/SがEOFでP=03のためPrevious-only 03だけを出力します。任意streamが先にEOFなら独立EOF状態を保持し、他streamはEOFまで続けます。自動テストはA/T/S/Pの存在/EOF組合せ16種すべてを列挙します。孤立取引（口座なし）は上流L2がNO-ACCOUNTに分類するため、L3 accepted streamには含まれません。

## RCと公開

| RC | 方針 | 正式出力 |
|---:|---|---|
| 0 | 全顧客突合合格、L2拒否およびL3業務差異なし | 検証後に公開 |
| 4 | L2拒否または顧客差異あり。他の合格顧客を継続可 | 元拒否とL3隔離を含め検証後公開。後続JOBはRC4を許可し隔離を除外すること |
| 8 | 入力/版/順序/一意性/対応/保存の構造エラー | 公開なし |
| 12 | build/権限/ディスク/sort work file/lock/検証/公開/予期しないRC失敗 | 公開なし |

出力はlockで保護された非公開候補directoryに書き、独立したbyte/件数/金額検証後に上書きせず公開します。lockがあればresetは拒否し全ファイルを保持します。元入力snapshot SHAは変わりません。候補stdoutは正式結果ではありません。`run.sh`はL2 report、L2 accepted/rejected、顧客突合report、隔離source report、eligible候補、control、入力/出力manifestを保持します。
