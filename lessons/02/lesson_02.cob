      * 第02課：銀行口座フィールドの例。
      * ソースは固定形式で、A領域とB領域の配置は意図的です。
      * この課では項目を単独で宣言し、第09課でレコードにまとめます。
      * VALUE句でこの例の初期値を設定します。
      * PICは項目の型と幅を示し、業務規則は定義しません。
      * DISPLAYは各PICが定める値の表現を表示します。
      * この例ではファイル、入力、MOVE、演算、分岐を使いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA02.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 先頭ゼロを含む識別子にはXが適します。
       01 WS-ACCOUNT-KEY PIC X(12) VALUE "000123456789".
      * Aは項目が英字を含むことを示します。
       01 WS-CUSTOMER-NAME PIC A(12) VALUE "ADA LOVELACE".
      * 顧客区分は1文字の英字業務コードです。
       01 WS-CUSTOMER-TYPE PIC A(1) VALUE "P".
      * Xは状態コードを格納しますが、PICだけでは規則を検査しません。
       01 WS-ACCOUNT-STATUS PIC X(1) VALUE "A".
      * 9(4)は支店コード用に4桁を確保します。
       01 WS-BRANCH-CODE PIC 9(4) VALUE 2048.
      * 通貨コードは通常3文字ですが、文字列として扱います。
       01 WS-CURRENCY-CODE PIC X(3) VALUE "USD".
      * 数字で日付形式を表せますが、暦上の妥当性は検証しません。
       01 WS-OPEN-DATE-DIGITS PIC 9(8) VALUE 20261013.
      * Xは口座番号キーの先頭ゼロを保持します。
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0002046819".
      * 商品識別子はコードであり、数量ではありません。
       01 WS-PRODUCT-CODE PIC X(4) VALUE "SAV1".
      * Vは暗黙の小数点を示し、桁を占有しません。
       01 WS-LEDGER-BALANCE PIC 9(7)V99 VALUE 125000.75.
      * 利用可能残高は帳簿残高と同じ小数桁です。
       01 WS-AVAILABLE-BALANCE PIC 9(7)V99 VALUE 123500.25.
      * 金額上限は小数点を格納せず、小数2桁です。
       01 WS-OVERDRAFT-LIMIT PIC 9(7)V99 VALUE 2500.00.
      * Sは符号を許可し、独立した先行符号でDISPLAYを読みやすくします。
       01 WS-LAST-CREDIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE 1250.50.
      * 負の引落額は符号付き数値項目で表します。
       01 WS-LAST-DEBIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE -75.25.
      * 利率は小数4桁です。この例では演算しません。
       01 WS-INTEREST-RATE PIC 9(2)V9(4) VALUE 0.0125.
      * 手数料率も同じ桁数ですが、業務上の意味は別です。
       01 WS-FEE-RATE PIC 9(2)V9(4) VALUE 0.0030.
      * 例では数量を表すため、件数は数値型です。
       01 WS-MONTHLY-TXN-COUNT PIC 9(4) VALUE 18.
      * 数値シーケンスは宣言した幅で表示されます。
       01 WS-LAST-BATCH-SEQ PIC 9(6) VALUE 521.
      * 請求日は2桁で、完全な日付ではありません。
       01 WS-STATEMENT-DAY PIC 9(2) VALUE 25.
      * 郵便番号は記号やゼロが重要なため文字列です。
       01 WS-POSTAL-CODE PIC X(9) VALUE "00100-200".
      * 国コードは英字を含むため英字データとして扱います。
       01 WS-COUNTRY-CODE PIC A(2) VALUE "JP".
      * 参照コードは日付の数字を含んでも文字列です。
       01 WS-TRANSFER-REF PIC X(15) VALUE "TRF-20261013-01".
      * バッチIDは英字、記号、数字を含みます。
       01 WS-BATCH-ID PIC X(14) VALUE "BATCH-20261013".
      * イニシャルは1文字の英字です。
       01 WS-CUSTOMER-INITIAL PIC A(1) VALUE "A".
      * 言語コードは英字で、数値量ではありません。
       01 WS-LANGUAGE-CODE PIC A(2) VALUE "EN".
       PROCEDURE DIVISION.
      * 出力冒頭で、この一覧が示す内容を説明します。
           DISPLAY "ACCOUNT FIELD DATA TYPES"
           DISPLAY "Text keys preserve their declared characters:"
           DISPLAY "ACCOUNT-KEY=" WS-ACCOUNT-KEY
           DISPLAY "CUSTOMER-NAME=" WS-CUSTOMER-NAME
           DISPLAY "CUSTOMER-TYPE=" WS-CUSTOMER-TYPE
           DISPLAY "ACCOUNT-STATUS=" WS-ACCOUNT-STATUS
           DISPLAY "BRANCH-CODE=" WS-BRANCH-CODE
           DISPLAY "CURRENCY-CODE=" WS-CURRENCY-CODE
           DISPLAY "OPEN-DATE-DIGITS=" WS-OPEN-DATE-DIGITS
           DISPLAY "CUSTOMER-NUMBER=" WS-CUSTOMER-NUMBER
           DISPLAY "PRODUCT-CODE=" WS-PRODUCT-CODE
      * Vは格納桁を使わず、DISPLAYでは小数点が表示されます。
           DISPLAY "Numeric account amounts and rates:"
           DISPLAY "LEDGER-BALANCE=" WS-LEDGER-BALANCE
           DISPLAY "AVAILABLE-BALANCE=" WS-AVAILABLE-BALANCE
           DISPLAY "OVERDRAFT-LIMIT=" WS-OVERDRAFT-LIMIT
           DISPLAY "LAST-CREDIT=" WS-LAST-CREDIT
           DISPLAY "LAST-DEBIT=" WS-LAST-DEBIT
           DISPLAY "INTEREST-RATE=" WS-INTEREST-RATE
           DISPLAY "FEE-RATE=" WS-FEE-RATE
           DISPLAY "MONTHLY-TXN-COUNT=" WS-MONTHLY-TXN-COUNT
           DISPLAY "LAST-BATCH-SEQ=" WS-LAST-BATCH-SEQ
           DISPLAY "STATEMENT-DAY=" WS-STATEMENT-DAY
      * 残りの項目は業務コードで、演算値ではありません。
           DISPLAY "Other account reference fields:"
           DISPLAY "POSTAL-CODE=" WS-POSTAL-CODE
           DISPLAY "COUNTRY-CODE=" WS-COUNTRY-CODE
           DISPLAY "TRANSFER-REF=" WS-TRANSFER-REF
           DISPLAY "BATCH-ID=" WS-BATCH-ID
           DISPLAY "CUSTOMER-INITIAL=" WS-CUSTOMER-INITIAL
           DISPLAY "LANGUAGE-CODE=" WS-LANGUAGE-CODE
      * プログラム開始時にVALUE句で各項目を初期化します。
      * VALUE句は外部入力の検証の代わりになりません。
      * PIC 9は数字桁を示し、暦や業務規則は示しません。
      * PIC Xは多くの業務キーに必要な文字を保持します。
      * PIC Aは英字区分であることを保守担当者に伝えます。
      * Vは格納桁を使わず小数桁を定義します。
      * Sは符号属性を定め、ここでは符号を別表示します。
      * 後の課でMOVEとCOMPUTEによる値の変更を学びます。
           STOP RUN.
