---
_translated_from: lessons/17_fixed-length-files/answer.md
_translated_by: site-src/translation agent
---
# 第 17 課変更演習の解答例

この解答は [`exercise.md`](./exercise.md) の変更演習だけを扱い、応用演習の解答は含みません。

## 出力 FD で口座番号を先頭にする

変更箇所：`lesson.cob` の `FD BALANCE-FILE` にある `01 FD-BALANCE-RECORD`。

変更前：

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

変更後：

```cobol
       01 FD-BALANCE-RECORD.
           05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
           05 FD-OUT-CUSTOMER-ID PIC X(8).
           05 FD-OUT-BALANCE PIC 9(7)V99.
```

コマンド：

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_17 lesson.cob
cp accounts.dat build/
(cd build && ./lesson_17)
wc -c build/balances.dat
cmp accounts.dat build/balances.dat
rm -rf build
```

**標準出力：** ベースラインと完全に同じ 5 行です。3 つの `MOVE` 文はフィールド名で代入し、フィールド名は変わっていないため、各レコードに表示される口座番号、顧客番号、残高の値も変わりません。

```text
ファイルを開きました
出力 口座番号=0001234567 顧客番号=C0001042 残高=0001000.00
出力 口座番号=0002468101 顧客番号=C0002042 残高=0000020.00
出力 口座番号=0007654321 顧客番号=C0003042 残高=0000250.75
クローズ完了 件数=03
```

**出力ファイル：** `wc -c build/balances.dat` は `81` を出力します。これは `3 × 27` です。`cmp accounts.dat build/balances.dat` は何も出力せず、終了コード 0 となり、出力と入力がバイト単位で一致することを示します（ファイル内に改行はなく、以下の改行は表示のためだけです）：

```text
0001234567C00010420001000000
0002468101C0002042000002000
0007654321C0003042000025075
```

第 1 レコードでは、`0001234567` が出力バイト 1〜10、`C0001042` が 11〜18、`000100000` が 19〜27 を占めます。入力レコードのオフセットと一致しています。

**ベースラインとの完全な差分：**

| レコード | ベースラインの `balances.dat` | 並べ替え後の `balances.dat` |
|---:|---|---|
| 1 | `C00010420001234567000100000` | `0001234567C00010420001000000` |
| 2 | `C00020420002468101000002000` | `0002468101C0002042000002000` |
| 3 | `C00030420007654321000025075` | `0007654321C0003042000025075` |
| ファイル合計サイズ | 81 | 81 |

**理由：** `MOVE` は宣言順とは無関係にデータ名で代入します。`WRITE` は `01` レコード内で宣言された順にレコードの各バイトを書き出します。そのため `05` 宣言の順序を変えると出力上の各フィールドのオフセットが変わりますが、各レコードの幅は `PIC` 句が決める `10 + 8 + 9 = 27` バイトのままです。レコード数とファイル合計サイズ（`3 × 27 = 81`）は変わりません。
