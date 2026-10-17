---
_translated_from: lessons/04_if-conditions/answer.md
_translated_by: site-src/translation agent
---
# 第 04 課変更演習：解答例

この解答は [`exercise.md`](./exercise.md) の変更演習のみを扱い、応用演習の解答は含みません。

## 変更方法

各シナリオは元の `lesson.cob` から始め、次の2つの `VALUE` 句だけを変更します。`PIC`、`SIGN IS LEADING SEPARATE CHARACTER`、上限金額、関係演算子、ネスト順、`DISPLAY` 文言はそのままです。

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

```sh
mkdir -p build
cobc -fsyntax-only lesson.cob
cobc -x -Wall -o build/lesson_04 lesson.cob
./build/lesson_04
echo $?
```

コンパイラーの各コマンドと実行の終了コードはすべて `0` です。業務上の拒否はプロセスの終了コードに影響しません。

## シナリオ1：金額 `0.00`、状態 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

最外層の `IF WS-TRANSACTION-AMOUNT <= ZERO` が真です。ゼロはゼロより大きくないため、最外層の分岐で拒否され、`ELSE` 内の検査には進みません。

## シナリオ2：金額 `-0.01`、状態 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=-0000000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

同じ比較が真になります。`SIGN IS LEADING SEPARATE CHARACTER` を指定した `S9(7)V99` は負値を保持し、先頭の `-` を表示します。数値比較なので `-0.01 <= ZERO` も真です。

## シナリオ3：金額 `0.01`、状態 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 0.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0000000.01
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

`0.01 <= ZERO` は偽なので下限を通過します。`0.01 > 1000.00` も偽で、状態も `"A"` のため、すべての規則を通過します。シナリオ1・2との分岐を決めるのは `<=` です。

## シナリオ4：金額 `1000.00`、状態 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.00.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.00
上限金額=0001000.00
判定=ACCEPTED
理由=WITHIN_RULES
```

上限判定は厳密な `>` です。`1000.00 > 1000.00` は偽なので端点は含まれ、状態検査でも受理されます。

## シナリオ5：金額 `1000.01`、状態 `"A"`

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 1000.01.
```

```text
取引参照番号=TXN-00000001
口座状態=A
取引金額=+0001000.01
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_OVER_LIMIT
```

正数判定を通過した後、`1000.01 > 1000.00` が真になります。2段目で拒否されるため、状態検査は行われません。

## シナリオ6：金額は `125.50` のまま、状態を `"I"` に変更

変更するのは状態だけです。

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
```

金額句は元のままです。

```cobol
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=+0000125.50
上限金額=0001000.00
判定=REJECTED
理由=ACCOUNT_INACTIVE
```

金額の2つの検査を通過し、`IF WS-ACCOUNT-STATUS = "A"` に到達します。`"I"` は `"A"` と等しくないので、最も内側の `ELSE` が `ACCOUNT_INACTIVE` を表示します。`A` 以外の状態には同じ理由が使われます。

## シナリオ7：金額 `-5.00`、状態 `"I"`

```cobol
       01 WS-ACCOUNT-STATUS PIC X VALUE "I".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE -5.00.
```

```text
取引参照番号=TXN-00000001
口座状態=I
取引金額=-0000005.00
上限金額=0001000.00
判定=REJECTED
理由=AMOUNT_NOT_POSITIVE
```

両方の条件が不適合ですが、判定はネストされています。外側の `<= ZERO` が真になるとその理由を表示し、最内層の状態比較には到達しません。ネスト順が最初に報告される失敗を決めます。

## 問いへの回答

1. `IF WS-TRANSACTION-AMOUNT <= ZERO` です。`0.00` と `-0.01` では真、`0.01` では偽になります。
2. どちらも `WITHIN_RULES` です。上限条件は厳密な `>` なので、`1000.00 > 1000.00` は偽となり端点を含みます。
3. `IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT` です。`1000.01` では真、`1000.00` では偽です。
4. 金額検査を通過して状態条件に進みます。`"I"` は `"A"` ではないため、最内層の `ELSE` が `ACCOUNT_INACTIVE` を返します。
5. 条件分岐がネストされており、外側が真ならその理由を表示して終了します。状態条件には到達しないので、理由は1つだけです。
