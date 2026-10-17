# モジュール06設計：ACCOUNT v1ファイル契約とstatus意味

## 1. インターフェースとバイト配置

ACCOUNT v1 = 47バイト、ASCII、LF終端。論理幅にLFは含めません。フィールドは`curriculum/bank/copybooks/ACCOUNT-V1.CPY`と一致します。

| 位置 | 長さ | COBOL名 | 規則 |
|---:|---:|---|---|
| 1–10 | 10 | ACCOUNT-ID | 数値、昇順、一意 |
| 11–18 | 8 | CUSTOMER-ID | 数値、顧客参照 |
| 19–21 | 3 | ACCOUNT-CURRENCY | 初期対応は`JPY` |
| 22 | 1 | BALANCE-SIGN | `+` / `-` |
| 23–35 | 13 | OPENING-BALANCE | 最小通貨単位の数値整数 |
| 36 | 1 | ACCOUNT-STATUS | `A`有効 / `F`凍結 / `C`閉鎖 |
| 37–44 | 8 | ACCOUNT-DATE | `YYYYMMDD`、JOB業務日と一致 |
| 45–47 | 3 | ACCOUNT-LAYOUT | `001` |

`TRANSACTION v1`（55B）は本モジュールでは変更せず、下流モジュール07の契約としてのみ扱います。

## 2. 読込モデル（なぜ1バイトずつか）

`FILEVAL.COB`は`ORGANIZATION IS SEQUENTIAL`、`01 A-BYTE PIC X`を使用して1バイトずつ読み、`X'0A'`を自ら識別します。

- 論理レコード長は1..47バイト。短い → `SHORT-RECORD`；47バイト後にLF以外 → `LONG-RECORD`；`X'0D'` → `CRLF-NOT-ALLOWED`；未終端バイトが残ったままEOF → `MISSING-FINAL-LF`。
- 以上はすべてファイル契約エラーでRC8です。
- `LINE SEQUENTIAL`は呼出し側から改行を取り除くため、論理幅からLFが有効か見抜けません。モジュール06.2で`scripts/line-seq-probe.COB`によりバイト差を実測します（第5節参照）。

## 3. 処理状態と順序

```text
OPEN INPUT/OUTPUT/LOG → status table {A,C,F}をロード
  loop: READ-RECORD（構造検証）→ PROCESS-RECORD
  1. layout ≠ 001 → RC8
  2. idが数値でない → BAD-ACCOUNT-ID；数値なら降順判定(RC8)/重複判定(DUPLICATE-ID)
  3. REASONが空なら → customer_idが非数値？ BAD-CUSTOMER-ID
  4. → currency ≠ JPY？ UNKNOWN-CURRENCY
  5. → sign ∉ {+,-}？ BAD-SIGN
  6. → balanceが非数値？ BAD-BALANCE
  7. → dateが非数値/暦日不正？ BAD-DATE；有効だが業務日と不一致？ DATE-MISMATCH
  8. → status SEARCH ALL {A,C,F}；未検出 → UNKNOWN-STATUS
  9. 理由が空 → acceptedへ書込み符号付き残高加算；それ以外はrejectedへ
CLOSE → READ = ACCEPT + REJECTを確認 → CONTROL出力、filestatus.logへ記録
```

## 4. 拒否優先順位とRC

1. `BAD-ACCOUNT-ID` → 2. `DUPLICATE-ID` → 3. `BAD-CUSTOMER-ID` →
4. `UNKNOWN-CURRENCY` → 5. `BAD-SIGN` → 6. `BAD-BALANCE` → 7. `BAD-DATE` /
`DATE-MISMATCH` → 8. `UNKNOWN-STATUS`。

`UNSORTED-INPUT`および長さ/改行/layoutエラーは1レコードごとの業務拒否でなく、**契約エラーRC8**です。

| RC | 意味 |
|---:|---|
| 0 | 業務拒否なし。読込 = 受理 + 拒否 |
| 4 | フィールド単位の業務拒否あり。公開は継続 |
| 8 | 契約エラー（長さ/CRLF/LF欠落/降順/layout/不正業務日）。公開しない |
| 12 | ファイル/権限/システム障害（欠落ファイルFILE STATUS 35を含む）。公開しない |

## 5. 実測FILE STATUSと索引/相対ファイル（ローカル環境）

環境：Linux x86-64、GnuCOBOL 3.2.0、`cobc -info` → `indexed file handler : BDB`。下記はすべて`scripts/*-probe.COB`を実行して得た結果です（生RC/statusはevidence参照）。

### 5.1 順次ファイル（本モジュールの中核）

| 操作 | status | 意味 |
|---|---|---|
| 既存ファイルを`OPEN INPUT` | `00` | 成功 |
| EOF読込 | `10` | EOF（at end） |
| 欠落ファイルを`OPEN INPUT` | `35` | file not found → RC12 |
| 空ファイルの最初の読込 | `10` | 0件として有効 |

`SD`（Sort Description）と`SORT … USING/GIVING`の対応は`scripts/sort-sd-probe.COB`で確認できます（06.1宣言演習。突合アルゴリズムはモジュール07の範囲）。

### 5.2 LINE SEQUENTIALと固定バイト

| 方法 | 生ファイルバイト | 論理レコード幅 |
|---|---:|---|
| `LINE SEQUENTIAL`で`HELLO`を書込 | 6（`HELLO\n`） | 5（LFを隠す） |
| 固定`SEQUENTIAL`で`HELLO`を書込 | 5 | 5 |

line fileを1バイトずつ読めば`X'0A'`が見え、LFは存在するが論理幅には含まれないと分かります。

### 5.3 索引ファイル（BDB）

| 操作 | status |
|---|---|
| `OPEN OUTPUT`で新規作成 | `00` |
| 新キーを`WRITE` | `00` |
| 重複キーを`WRITE` | `22`（duplicate key） |
| `READ KEY`で発見 | `00` |
| `REWRITE` | `00` |
| `READ KEY`で不在 | `23`（record not found） |
| 既存行を`DELETE` | `00` |
| 削除後に`READ` | `23` |
| 同一プロセスでopen済みfileを再度`OPEN INPUT` | `41`（already open） |
| 欠落fileを`OPEN INPUT` | `35` |

### 5.4 相対ファイル

| 操作 | status |
|---|---|
| `OPEN OUTPUT`で新規作成 | `00` |
| `WRITE`（`RELATIVE KEY` 1、2） | `00` |
| 重複キーの再`WRITE` | `22` |
| `READ`で発見 | `00` |
| `REWRITE` | `00` |
| 範囲外キー9 / キー0を`READ` | `23` |
| `DELETE` | `00` |
| 削除後の`READ` | `23` |

### 5.5 適用限界（重要）

- **既定ではプロセス間排他なし（文書からの推測でなくローカル実測）**：`scripts/indexed-hold-probe.COB`で2プロセスが同じBDB索引ファイルを同時に`OPEN I-O`すると、**両方とも`00`**でした（`check.py::check_cross_process_lock`が並行実行）。同一プロセス内の再`OPEN`が`41`でも、2プロセス時の動作を示す**ものではありません**。結果を相互推論できません。GnuCOBOL/BDBは既定でファイル全体を排他lockしないため、JOB層の外部lockで並行整合性を保証します。本課`run.sh`は`output.lock` directoryで単一起動を保護します（`check_protection`は2つの`run.sh`を起動し、一方を`RC0`、他方をstderr `Run locked`付き`RC12`とし、両結果directory/lockがcleanであると確認）。これらの保護は目的が異なり互換ではありません。
- 索引/相対fileは本モジュールの**読解実験**とモジュール07の一時台帳にのみ使用し、主検証経路は順次読込のままです。DB JOIN、Python、全量配列は使いません。

## 6. 手計算例（`fixtures/invalid/mixed.dat`）

| レコード | 主なフィールド | 判定 |
|---:|---|---|
| 1 | id1、JPY、+、1000、A、20261009 | ACCEPT +1000 |
| 2 | id2、USD | REJECT UNKNOWN-CURRENCY |
| 3 | id3、符号`*` | REJECT BAD-SIGN |
| 4 | id4、status `Z` | REJECT UNKNOWN-STATUS |
| 5 | id5、日付20261008 | REJECT DATE-MISMATCH |
| 6 | id6、JPY、+、100、A | ACCEPT +100 |

読込6件 = 受理2件 + 拒否4件、BALANCE = 1000 + 100 = 1100。`normal/valid.dat`：
+1000 + +50 − 500 = **550**。

## 7. 境界条件と制限

- 空ファイルは有効（READ=0、RC0）。欠落ファイルはRC12で公開しません。
- `BALANCE`は符号付き正確な18桁10進数、1レコード金額は13桁です。小数換算はしません。
- ASCII、単一通貨の整数金額のみ。マルチバイト/EBCDICは別演習です。
- 実検証環境：Linux x86-64、GnuCOBOL 3.2（BDB）。他platformは未検証です。
- 実行時の`libcob: warning`（libxml版通知）は業務RCと無関係な環境noiseです。
