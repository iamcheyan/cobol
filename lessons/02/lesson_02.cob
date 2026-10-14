      * Lesson 02: bank account field examples.
      * 中文：第02课：银行账户字段示例。
      * 日本語：第02課：銀行口座フィールドの例。
      * Source is fixed format, Area A and Area B are intentional.
      * 中文：源码采用固定格式，A区和B区位置有意安排。
      * 日本語：ソースは固定形式で、A領域とB領域の配置は意図的です。
      * The fields are flat now; grouped records come in Lesson 09.
      * 中文：本课字段尚未分组；第09课介绍记录分组。
      * 日本語：この課では項目を未グループ化。第09課でレコードを扱います。
      * VALUE supplies sample initial contents for this demonstration.
      * 中文：VALUE为本示例提供初始值。
      * 日本語：VALUE句でこの例の初期値を設定します。
      * PIC documents a field's class and width, not business rules.
      * 中文：PIC说明字段类别和宽度，不定义业务规则。
      * 日本語：PICは項目の型と幅を示し、業務規則は定義しません。
      * DISPLAY shows the value representation supplied by each PIC.
      * 中文：DISPLAY显示各PIC规定的值格式。
      * 日本語：DISPLAYは各PICが定める値の表現を表示します。
      * No file, input, MOVE, arithmetic, or branch is used here.
      * 中文：本例不使用文件、输入、MOVE、算术或分支。
      * 日本語：この例ではファイル、入力、MOVE、演算、分岐を使いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA02.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * X is suitable for identifiers that may contain leading zeroes.
      * 中文：X适用于可能含前导零的标识符。
      * 日本語：先頭ゼロを含む識別子にはXが適します。
       01 WS-ACCOUNT-KEY PIC X(12) VALUE "000123456789".
      * A documents a field expected to contain alphabetic characters.
      * 中文：A表示字段预期包含字母字符。
      * 日本語：Aは項目が英字を含むことを示します。
       01 WS-CUSTOMER-NAME PIC A(12) VALUE "ADA LOVELACE".
      * Customer category is a one-character alphabetic business code.
      * 中文：客户类别是单字符字母业务代码。
      * 日本語：顧客区分は1文字の英字業務コードです。
       01 WS-CUSTOMER-TYPE PIC A(1) VALUE "P".
      * X accepts a status code; PIC alone is not a status-rule check.
      * 中文：X可存储状态码；PIC本身不检查状态规则。
      * 日本語：Xは状態コードを格納しますが、PICだけでは規則を検査しません。
       01 WS-ACCOUNT-STATUS PIC X(1) VALUE "A".
      * 9(4) provides four digit positions for the branch code.
      * 中文：9(4)为分行代码提供四位数字。
      * 日本語：9(4)は支店コード用に4桁を確保します。
       01 WS-BRANCH-CODE PIC 9(4) VALUE 2048.
      * Currency is text even though its code is usually three letters.
      * 中文：货币代码虽通常为三字母，仍按文本处理。
      * 日本語：通貨コードは通常3文字ですが、文字列として扱います。
       01 WS-CURRENCY-CODE PIC X(3) VALUE "USD".
      * Digits can encode a date shape but do not validate its calendar.
      * 中文：数字可表示日期格式，但不会验证日历有效性。
      * 日本語：数字で日付形式を表せますが、暦上の妥当性は検証しません。
       01 WS-OPEN-DATE-DIGITS PIC 9(8) VALUE 20261013.
      * X preserves leading zeroes in account number keys.
      * 中文：X会保留账户编号中的前导零。
      * 日本語：Xは口座番号キーの先頭ゼロを保持します。
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0002046819".
      * Product identifiers are codes, not arithmetic quantities.
      * 中文：产品标识符是代码，不是算术数量。
      * 日本語：商品識別子はコードであり、数量ではありません。
       01 WS-PRODUCT-CODE PIC X(4) VALUE "SAV1".
      * V marks an implied decimal point; it occupies no digit position.
      * 中文：V表示隐含小数点，不占数字位。
      * 日本語：Vは暗黙の小数点を示し、桁を占有しません。
       01 WS-LEDGER-BALANCE PIC 9(7)V99 VALUE 125000.75.
      * This available balance has the same scale as the ledger balance.
      * 中文：可用余额与账面余额的小数位数相同。
      * 日本語：利用可能残高は帳簿残高と同じ小数桁です。
       01 WS-AVAILABLE-BALANCE PIC 9(7)V99 VALUE 123500.25.
      * An amount limit uses two decimal places without storing a dot.
      * 中文：金额限额使用两位小数，但不存储小数点。
      * 日本語：金額上限は小数点を格納せず、小数2桁です。
       01 WS-OVERDRAFT-LIMIT PIC 9(7)V99 VALUE 2500.00.
      * S permits a sign; separate leading sign makes DISPLAY legible.
      * 中文：S允许正负号；分离前置符号便于DISPLAY阅读。
      * 日本語：Sは符号を許可し、独立した先行符号でDISPLAYを読みやすくします。
       01 WS-LAST-CREDIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE 1250.50.
      * A negative debit is represented by the signed numeric data item.
      * 中文：负数借记由带符号数值字段表示。
      * 日本語：負の引落額は符号付き数値項目で表します。
       01 WS-LAST-DEBIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE -75.25.
      * Rates have four decimals; this example performs no arithmetic.
      * 中文：利率有四位小数；本例不进行运算。
      * 日本語：利率は小数4桁です。この例では演算しません。
       01 WS-INTEREST-RATE PIC 9(2)V9(4) VALUE 0.0125.
      * Fee rate uses the same scale, with its own business meaning.
      * 中文：费用率使用相同精度，但业务含义不同。
      * 日本語：手数料率も同じ桁数ですが、業務上の意味は別です。
       01 WS-FEE-RATE PIC 9(2)V9(4) VALUE 0.0030.
      * A count is numeric because the sample represents a quantity.
      * 中文：计数使用数值型，因为示例表示数量。
      * 日本語：例では数量を表すため、件数は数値型です。
       01 WS-MONTHLY-TXN-COUNT PIC 9(4) VALUE 18.
      * A numeric sequence is displayed with its declared width.
      * 中文：数值序列按声明的宽度显示。
      * 日本語：数値シーケンスは宣言した幅で表示されます。
       01 WS-LAST-BATCH-SEQ PIC 9(6) VALUE 521.
      * Statement day is two numeric positions; it is not a full date.
      * 中文：账单日占两位数字，并非完整日期。
      * 日本語：請求日は2桁で、完全な日付ではありません。
       01 WS-STATEMENT-DAY PIC 9(2) VALUE 25.
      * Postal codes are text because punctuation and zeroes can matter.
      * 中文：邮政编码用文本保存，因为标点和零可能重要。
      * 日本語：郵便番号は記号やゼロが重要なため文字列です。
       01 WS-POSTAL-CODE PIC X(9) VALUE "00100-200".
      * Country code contains letters and is modeled as alphabetic data.
      * 中文：国家代码含字母，按字母数据建模。
      * 日本語：国コードは英字を含むため英字データとして扱います。
       01 WS-COUNTRY-CODE PIC A(2) VALUE "JP".
      * Reference codes are text even when they include date digits.
      * 中文：参考代码即使含日期数字也按文本处理。
      * 日本語：参照コードは日付の数字を含んでも文字列です。
       01 WS-TRANSFER-REF PIC X(15) VALUE "TRF-20261013-01".
      * Batch ID combines letters, punctuation, and digits.
      * 中文：批次ID由字母、标点和数字组成。
      * 日本語：バッチIDは英字、記号、数字を含みます。
       01 WS-BATCH-ID PIC X(14) VALUE "BATCH-20261013".
      * Initial is a single alphabetic character.
      * 中文：姓名首字母是单个字母。
      * 日本語：イニシャルは1文字の英字です。
       01 WS-CUSTOMER-INITIAL PIC A(1) VALUE "A".
      * Language code uses letters and is not a numeric quantity.
      * 中文：语言代码由字母组成，不是数值数量。
      * 日本語：言語コードは英字で、数値量ではありません。
       01 WS-LANGUAGE-CODE PIC A(2) VALUE "EN".
       PROCEDURE DIVISION.
      * The first output lines identify what this catalog demonstrates.
      * 中文：输出开头说明本目录示例的内容。
      * 日本語：出力冒頭で、この一覧が示す内容を説明します。
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
      * V uses no storage position; DISPLAY shows its decimal point.
      * 中文：V不占存储位；DISPLAY会显示小数点。
      * 日本語：Vは格納桁を使わず、DISPLAYでは小数点が表示されます。
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
      * The remaining fields are business codes, not arithmetic values.
      * 中文：其余字段是业务代码，不用于算术运算。
      * 日本語：残りの項目は業務コードで、演算値ではありません。
           DISPLAY "Other account reference fields:"
           DISPLAY "POSTAL-CODE=" WS-POSTAL-CODE
           DISPLAY "COUNTRY-CODE=" WS-COUNTRY-CODE
           DISPLAY "TRANSFER-REF=" WS-TRANSFER-REF
           DISPLAY "BATCH-ID=" WS-BATCH-ID
           DISPLAY "CUSTOMER-INITIAL=" WS-CUSTOMER-INITIAL
           DISPLAY "LANGUAGE-CODE=" WS-LANGUAGE-CODE
      * These sample fields are initialized by VALUE at program start.
      * 中文：程序启动时，VALUE会初始化这些示例字段。
      * 日本語：プログラム開始時にVALUE句で各項目を初期化します。
      * VALUE is not a substitute for validating external input.
      * 中文：VALUE不能替代对外部输入的验证。
      * 日本語：VALUE句は外部入力の検証の代わりになりません。
      * PIC 9 describes digit positions, not calendar or business rules.
      * 中文：PIC 9描述数字位，不描述日历或业务规则。
      * 日本語：PIC 9は数字桁を示し、暦や業務規則は示しません。
      * PIC X retains the characters required by many business keys.
      * 中文：PIC X保留许多业务键所需的字符。
      * 日本語：PIC Xは多くの業務キーに必要な文字を保持します。
      * PIC A communicates an alphabetic category to maintainers.
      * 中文：PIC A向维护者说明这是字母类别。
      * 日本語：PIC Aは英字区分であることを保守担当者に伝えます。
      * V defines decimal scale without occupying a storage position.
      * 中文：V定义小数精度，但不占存储位。
      * 日本語：Vは格納桁を使わず小数桁を定義します。
      * S defines signedness; a separate sign is visible here.
      * 中文：S定义符号属性；此处符号单独显示。
      * 日本語：Sは符号属性を定め、ここでは符号を別表示します。
      * A later lesson will change values with MOVE and COMPUTE.
      * 中文：后续课程将用MOVE和COMPUTE修改值。
      * 日本語：後の課でMOVEとCOMPUTEによる値の変更を学びます。
           STOP RUN.
