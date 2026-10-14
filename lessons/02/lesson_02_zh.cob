      * 中文：第02课：银行账户字段示例。
      * 中文：源码采用固定格式，A区和B区位置有意安排。
      * 中文：本课字段尚未分组；第09课介绍记录分组。
      * 中文：VALUE为本示例提供初始值。
      * 中文：PIC说明字段类别和宽度，不定义业务规则。
      * 中文：DISPLAY显示各PIC规定的值格式。
      * 中文：本例不使用文件、输入、MOVE、算术或分支。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA02.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 中文：X适用于可能含前导零的标识符。
       01 WS-ACCOUNT-KEY PIC X(12) VALUE "000123456789".
      * 中文：A表示字段预期包含字母字符。
       01 WS-CUSTOMER-NAME PIC A(12) VALUE "ADA LOVELACE".
      * 中文：客户类别是单字符字母业务代码。
       01 WS-CUSTOMER-TYPE PIC A(1) VALUE "P".
      * 中文：X可存储状态码；PIC本身不检查状态规则。
       01 WS-ACCOUNT-STATUS PIC X(1) VALUE "A".
      * 中文：9(4)为分行代码提供四位数字。
       01 WS-BRANCH-CODE PIC 9(4) VALUE 2048.
      * 中文：货币代码虽通常为三字母，仍按文本处理。
       01 WS-CURRENCY-CODE PIC X(3) VALUE "USD".
      * 中文：数字可表示日期格式，但不会验证日历有效性。
       01 WS-OPEN-DATE-DIGITS PIC 9(8) VALUE 20261013.
      * 中文：X会保留账户编号中的前导零。
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0002046819".
      * 中文：产品标识符是代码，不是算术数量。
       01 WS-PRODUCT-CODE PIC X(4) VALUE "SAV1".
      * 中文：V表示隐含小数点，不占数字位。
       01 WS-LEDGER-BALANCE PIC 9(7)V99 VALUE 125000.75.
      * 中文：可用余额与账面余额的小数位数相同。
       01 WS-AVAILABLE-BALANCE PIC 9(7)V99 VALUE 123500.25.
      * 中文：金额限额使用两位小数，但不存储小数点。
       01 WS-OVERDRAFT-LIMIT PIC 9(7)V99 VALUE 2500.00.
      * 中文：S允许正负号；分离前置符号便于DISPLAY阅读。
       01 WS-LAST-CREDIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE 1250.50.
      * 中文：负数借记由带符号数值字段表示。
       01 WS-LAST-DEBIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE -75.25.
      * 中文：利率有四位小数；本例不进行运算。
       01 WS-INTEREST-RATE PIC 9(2)V9(4) VALUE 0.0125.
      * 中文：费用率使用相同精度，但业务含义不同。
       01 WS-FEE-RATE PIC 9(2)V9(4) VALUE 0.0030.
      * 中文：计数使用数值型，因为示例表示数量。
       01 WS-MONTHLY-TXN-COUNT PIC 9(4) VALUE 18.
      * 中文：数值序列按声明的宽度显示。
       01 WS-LAST-BATCH-SEQ PIC 9(6) VALUE 521.
      * 中文：账单日占两位数字，并非完整日期。
       01 WS-STATEMENT-DAY PIC 9(2) VALUE 25.
      * 中文：邮政编码用文本保存，因为标点和零可能重要。
       01 WS-POSTAL-CODE PIC X(9) VALUE "00100-200".
      * 中文：国家代码含字母，按字母数据建模。
       01 WS-COUNTRY-CODE PIC A(2) VALUE "JP".
      * 中文：参考代码即使含日期数字也按文本处理。
       01 WS-TRANSFER-REF PIC X(15) VALUE "TRF-20261013-01".
      * 中文：批次ID由字母、标点和数字组成。
       01 WS-BATCH-ID PIC X(14) VALUE "BATCH-20261013".
      * 中文：姓名首字母是单个字母。
       01 WS-CUSTOMER-INITIAL PIC A(1) VALUE "A".
      * 中文：语言代码由字母组成，不是数值数量。
       01 WS-LANGUAGE-CODE PIC A(2) VALUE "EN".
       PROCEDURE DIVISION.
      * 中文：输出开头说明本目录示例的内容。
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
      * 中文：V不占存储位；DISPLAY会显示小数点。
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
      * 中文：其余字段是业务代码，不用于算术运算。
           DISPLAY "Other account reference fields:"
           DISPLAY "POSTAL-CODE=" WS-POSTAL-CODE
           DISPLAY "COUNTRY-CODE=" WS-COUNTRY-CODE
           DISPLAY "TRANSFER-REF=" WS-TRANSFER-REF
           DISPLAY "BATCH-ID=" WS-BATCH-ID
           DISPLAY "CUSTOMER-INITIAL=" WS-CUSTOMER-INITIAL
           DISPLAY "LANGUAGE-CODE=" WS-LANGUAGE-CODE
      * 中文：程序启动时，VALUE会初始化这些示例字段。
      * 中文：VALUE不能替代对外部输入的验证。
      * 中文：PIC 9描述数字位，不描述日历或业务规则。
      * 中文：PIC X保留许多业务键所需的字符。
      * 中文：PIC A向维护者说明这是字母类别。
      * 中文：V定义小数精度，但不占存储位。
      * 中文：S定义符号属性；此处符号单独显示。
      * 中文：后续课程将用MOVE和COMPUTE修改值。
           STOP RUN.
