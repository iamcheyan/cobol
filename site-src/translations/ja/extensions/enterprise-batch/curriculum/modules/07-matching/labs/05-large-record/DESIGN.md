# B04 / 07.6 Boss L4：企業顧客拡張レコードのフィールド単位比較

## 業務境界

B04は2バッチ間で同一CUSTOMER-IDの企業顧客拡張snapshotを比較し、各業務フィールドの変更箇所を特定します。既存interfaceを置き換えません。CUSTOMER27は基礎教材レコード、ACCOUNT v1は47B口座master、TRANSACTION v1は55B取引のままです。本課では独立した固定バイナリ`ENTERPRISE-CUSTOMER-V1`を追加します。175以上の業務属性をACCOUNTへ詰め込まず、B03のオフラインCustomer Snapshotとも称しません。

V1は独立した1バイト`CUSTOMER_CLASSIFICATION`基準（A retail、B business、C private、D public-sector）を保持します。`RECORD_STATUS`は別の業務意味（A active/I inactive）で、顧客classificationとして誤用してはいけません。**V2フィールドをV1の横に配置したり、1バイト値と2バイト値が異なる分類意味だと主張しないでください。**まずV1影響を調査し、次に独立した`ENTERPRISE-CUSTOMER-V2`を設計します。同じclassificationフィールドをPIC XからPIC X(2)に広げ、layout版を001から002にし、V2コード対応/offset変化/上下流移行は別途レビューします。例：A→A1、B→B1、C→C1、D→D1。V1ファイルを直接上書きしてはいけません。

本提案はHeader/Identity/Classification/Address/Contact/Bank relationship/Risk compliance/Limits/Channel/Auditにわたる、名前付き業務leaf field 175個を持ちます。field ID、物理offset、比較規則は同directoryの`FIELD-CATALOG.csv`にあります。FILLERはなく、group itemはバイトを占めません。V1はREDEFINESも可変OCCURSも使わないためaliasを二重計上せず、実行時可変長レコードもありません。

## 提案する物理レコード配置

- Encoding：固定単バイトASCII。すべてのDISPLAYテキスト/code/数値はASCII 1バイト/文字です。非ASCII入力はRC8で拒否します。本演習はローマ字の合成顧客データで、実運用Unicode/EBCDIC変換は扱いません。
- Framing：旧/新ファイルとも区切りやLFのない連続固定幅バイナリレコードで、**1件1,778バイト**です。Copybook宣言順に密着しalignment paddingなし。LINE SEQUENTIAL、`splitlines()`、テキスト変換で読み込んではいけません。空ファイルは0レコード、完全な追加レコードは追加業務キーであって「長すぎる行」ではありません。
- Layoutフィールド：先頭の`LAYOUT_VERSION=X(3)`は`001`固定。続く`BINARY_ABI_CODE=X(8)`は`GCOB32BE`固定で、本版のGnuCOBOL 3.2/Linux x86-64 PIC COMP big-endian ABIを示します。その後offset 12にASCII数字10桁の`CUSTOMER_ID`キーがあります。
- 表現：通常のテキスト/code/dateはDISPLAY `PIC X`。符号なしcount/revisionはASCII DISPLAY `PIC 9(n)`。18個のlimit金額は非負`PIC S9(9)V99 COMP-3`、6バイト、小数2桁、PRIMARY_CURRENCYのmajor unit。`RISK_SCORE_ADJUSTMENT`も6バイトCOMP-3ですがrisk point単位で範囲−9999.99..9999.99です。両単位は混同できません。`RISK_SCORE`は`PIC S9(9) COMP`、4バイトで、GnuCOBOL実測big-endian（例0x01020304は01 02 03 04出力）。CPU native endianから推定してはいけません。COMP-5は本環境実測でnative little-endianですがV1では使用しません。V1に暗黙alignmentはありません。
- Packed有効バイト：各数字nibbleは0–9でなければなりません。本コース契約で認めるsign nibbleは正C、負Dのみです。実GnuCOBOL primitive probeではPIC SのF sign nibbleに対する`IS NUMERIC`がfalseだったため、Fを有効としません。parse前に各nibbleを検証し、不正packedを計算に使いません。正負ゼロのC/D表現はいずれも数値ゼロで、生バイトは異なっても数値比較では等価です。実行担当者のローカルprobeでは両方が`IS NUMERIC`かつ比較等価と実測しました（primitive証拠であり最終フィールド/layout受入ではありません）。
- ファイル/環境制限：GnuCOBOL 3.2、Linux x86-64 host、PIC COMPが実測big-endianであるbuildのみを受け入れます。Copybook、compiler option、ABI tagを一致させます。別compiler、endianness、PIC/optimization optionには新ABI版と独立実測が必要です。COMP値は比較前にbinary rangeを検証します。
- 版と生長さgate：runnerはlock内で入力snapshotを作り、総バイト数が1,778の倍数か検査します。部分末尾レコードはRC8です。その後COBOL固定レコード読込で各行の版、ABI、キー、必須/code、DISPLAY数値、COMP範囲、packed nibble、厳密昇順keyを確認します。GnuCOBOL固定順次ファイルは短いレコードをPIC Xで黙って補完しstatus 00を返す場合があるため、**バイト長の剰余検査は必須の外側raw-byte境界**です。FILE STATUSだけで短レコードを検出できると主張しません。1バイト挿入/削除は剰余検査に失敗し、完全な追加レコードはキー/基数意味で分類します。

フィールド開始offsetは1始まりのバイト位置です。CSV offsetは設計推導値です。Copybookを生成し、実GnuCOBOL layout writerで各フィールド名付きsentinelを出力し、独立byte checkerが175フィールド全slice、全長、catalog一致を確認して初めて検証済みlayoutとできます。compiler `LENGTH OF`は総幅のみ証明し、各leaf offset証拠の代わりになりません。主担当の独立受入も全フィールドを交差確認するため、その受入契約を変えないでください。

## 比較意味

旧/新ファイルはCUSTOMER-ID厳密昇順で、キーごと最大1行です。COBOLは有界2 cursor順次mergeを行います。同じキーは各フィールドを比較し、旧キーが小さければOLD-ONLY、新キーが小さければNEW-ONLYを出力します。片側EOFは有効、両側空はRC0、片側だけレコードがあればレコード単位業務差異RC4です。重複/降順key、版/ABI競合、幅エラー、不正encoding/valueは構造RC8で全batch非公開。tool/disk/lock/output/verification障害はRC12で非公開。有効な業務差異はRC4となり、reportとcounterを独立検証後に公開します。

フィールド規則：

- `RAW`：フィールドバイトを完全一致比較。キー、版、status/code、date、表現保持が必要なIDに使用。
- `TEXT-NORM`：まずASCII printable rangeを検証し、ASCII規則でa–zをA–Zへ変換し、最後に右側ASCII空白だけ除去。左trim、中間空白の畳込み、locale/Unicode変換は禁止。正規化後等価なら業務差異にせず、summaryで「byteは違うが意味は同じ」として数えます。
- `NUMERIC`：元DISPLAY/COMP/COMP-3表現とフィールド範囲を検証し、PIC符号/小数scaleに従いdecodeして浮動小数点なしで正確な10進比較。正当な生バイトが異なっても数値が等しければ業務差異にせず、representation-equalを加算します。
- `IGNORE-AUDIT`：監査保守フィールドの変更を許可し、audit-onlyとして数えてreportにfield_idを記録します。業務差異RCや「field differences」件数は増やしません。

実行可能なdomain規則：必須DISPLAY text/codeの空白のみは不正。nullable text/dateはフィールド全体が空白の場合のみNULLで、部分空白をNULLに見せかけてはいけません。全X fieldで制御バイト/上位bit非ASCIIを拒否し、code fieldはCSVの各フィールド指定コード集合で検証します。flagはY/N/U、MFA/voiceprintはY/N、record statusはA/I、classificationはA/B/C/D、顧客typeはIND/ORG/TRU、製品familyはDEP/CRD/LON/INV、通貨JPY/USD、本課country code JP/USです。review statusはCSVで各fieldごとに指定（例：KYC N/P/C/R、AML C/P/H/R）。日付は19000101..20991231でGregorian検証。audit timestampは実在YYYYMMDDHHMMSSで、HH00..23、MM/SS00..59。CONTACT_TIME_FROM/TOは有効HHMM。各count fieldのPIC幅/上限はCSV参照。全limitは0.00..999999999.99のみで負数不可。risk adjustmentはrisk point単位で正負を許可します。主電話のcountry/area/numberは全て値あり、または全てNULL。nullable=N fieldの空白はdefaultでなく構造エラーです。

差分行にはrun ID、input version、旧/新record sequence、mask済みcustomer key、field_id/name、1始まりoffset、length、rule、差分種別、old/new表示値を含めます。正確なCSV形式（COBOL出力、oracleは独立再計算）：

```text
FIELD,<run_id>,<layout_version>,<old_seq>,<new_seq>,<redacted_key>,<field_id>,<cobol_name>,<offset>,<length>,<rule>[,REDACTED]
AUDIT,<run_id>,<layout_version>,<old_seq>,<new_seq>,<redacted_key>,<field_id>,<cobol_name>,<offset>,<length>,IGNORE-AUDIT
OLD|<old value>
NEW|<new value>
```

`<redacted_key>`は`******`とcustomer ID末尾4桁の連結固定。`<old_seq>`/`<new_seq>`は各ファイル内1始まりrecord位置（`OLD-COUNT`/`NEW-COUNT`）。`<name>`はFIELD-CATALOG.csvのcanonical `cobol_name`（業務名`business_name`はfield_idでcatalogから解決可）。同一matched recordではIGNORE-AUDIT blockを先に、業務field blockを後に出力します。機密fieldの旧/新値は常に`[REDACTED]`とし、stdout/stderr/差分reportへ平文を書きません。raw binaryは安全なhex表現のみreportに出し、機密なら同様にmaskします。日付はYYYYMMDD固定でGregorian検証します。Summaryには少なくともold/new/matched/old-only/new-only件数、business-different fields、audit-only fields、normalized-equal、numeric-representation-equal、構造拒否件数を含めます。全counterはCOBOLが実計数し、独立verifierは生レコードと変更一覧から再計算します。

## 独立受入と公開

中核アルゴリズムはCOBOLです：固定レコードを順次読込み、2キーcursorで比較し、catalogに沿って175 leaf fieldすべてを比較して候補を出力します。Pythonはfixture生成や独立field metadata/手書き変更一覧による検証に使用できますが、フィールド比較を代替しません。検証済みcourse runner方式に従い、input snapshot、lock、private stage、RC mapping、候補byte/count検査、no-clobber atomic publishを実装します。rename前にhashと候補検査を完了し、rename後に失敗し得る検査を実行しません。

独立変更setには完全一致、先頭/中間/末尾field単独、多数field、text case/末尾空白等価、異なる有効packed zero表現で数値等価、数値変化/符号/scale/上下限、ignore audit、機密redaction、不正packed数字/sign、DISPLAY数値/範囲不正、key/version/ABI、空/片側EOF/短/長/重複/降順を最低限含めます。実装前に元hex位置と意味値からexpectedを手作業で作ります。

## 影響調査演習：顧客classificationを1バイトから2バイトへ

移行対象は`RECORD_STATUS`ではありません。V1 `CUSTOMER_CLASSIFICATION PIC X`の読込/比較/sort/出力位置を追い、同じ意味のV2 `PIC X(2)`、layout版002、明示的対応とunknown方針を提案します。顧客master、B03 customer key/snapshot、B04旧新比較、下流notification/channel/limit consumer、batch parameter、復旧点を追跡します。V1は凍結して変更しません。V2では分類幅拡大が以降すべての物理offsetを動かす点、旧file拒否/変換、二重書込/並行比較、切替、rollback、版競合試験を説明します。調査なしにV1中へPICを挿入してファイルを上書きしないでください。
