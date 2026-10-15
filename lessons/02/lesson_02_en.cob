      * Lesson 02: bank account field examples.
      * Source is fixed format, Area A and Area B are intentional.
      * The fields are flat now; grouped records come in Lesson 09.
      * VALUE supplies sample initial contents for this demonstration.
      * PIC documents a field's class and width, not business rules.
      * DISPLAY shows the value representation supplied by each PIC.
      * No file, input, MOVE, arithmetic, or branch is used here.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA02.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * X is suitable for identifiers that may contain leading zeroes.
       01 WS-ACCOUNT-KEY PIC X(12) VALUE "000123456789".
      * A documents a field expected to contain alphabetic characters.
       01 WS-CUSTOMER-NAME PIC A(12) VALUE "ADA LOVELACE".
      * Customer category is a one-character alphabetic business code.
       01 WS-CUSTOMER-TYPE PIC A(1) VALUE "P".
      * X accepts a status code; PIC alone is not a status-rule check.
       01 WS-ACCOUNT-STATUS PIC X(1) VALUE "A".
      * 9(4) provides four digit positions for the branch code.
       01 WS-BRANCH-CODE PIC 9(4) VALUE 2048.
      * Currency is text even though its code is usually three letters.
       01 WS-CURRENCY-CODE PIC X(3) VALUE "USD".
      * Digits can encode a date shape but do not validate its calendar.
       01 WS-OPEN-DATE-DIGITS PIC 9(8) VALUE 20261013.
      * X preserves leading zeroes in account number keys.
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0002046819".
      * Product identifiers are codes, not arithmetic quantities.
       01 WS-PRODUCT-CODE PIC X(4) VALUE "SAV1".
      * V marks an implied decimal point; it occupies no digit position.
       01 WS-LEDGER-BALANCE PIC 9(7)V99 VALUE 125000.75.
      * This available balance has the same scale as the ledger balance.
       01 WS-AVAILABLE-BALANCE PIC 9(7)V99 VALUE 123500.25.
      * An amount limit uses two decimal places without storing a dot.
       01 WS-OVERDRAFT-LIMIT PIC 9(7)V99 VALUE 2500.00.
      * S permits a sign; separate leading sign makes DISPLAY legible.
       01 WS-LAST-CREDIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE 1250.50.
      * A negative debit is represented by the signed numeric data item.
       01 WS-LAST-DEBIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE -75.25.
      * Rates have four decimals; this example performs no arithmetic.
       01 WS-INTEREST-RATE PIC 9(2)V9(4) VALUE 0.0125.
      * Fee rate uses the same scale, with its own business meaning.
       01 WS-FEE-RATE PIC 9(2)V9(4) VALUE 0.0030.
      * A count is numeric because the sample represents a quantity.
       01 WS-MONTHLY-TXN-COUNT PIC 9(4) VALUE 18.
      * A numeric sequence is displayed with its declared width.
       01 WS-LAST-BATCH-SEQ PIC 9(6) VALUE 521.
      * Statement day is two numeric positions; it is not a full date.
       01 WS-STATEMENT-DAY PIC 9(2) VALUE 25.
      * Postal codes are text because punctuation and zeroes can matter.
       01 WS-POSTAL-CODE PIC X(9) VALUE "00100-200".
      * Country code contains letters and is modeled as alphabetic data.
       01 WS-COUNTRY-CODE PIC A(2) VALUE "JP".
      * Reference codes are text even when they include date digits.
       01 WS-TRANSFER-REF PIC X(15) VALUE "TRF-20261013-01".
      * Batch ID combines letters, punctuation, and digits.
       01 WS-BATCH-ID PIC X(14) VALUE "BATCH-20261013".
      * Initial is a single alphabetic character.
       01 WS-CUSTOMER-INITIAL PIC A(1) VALUE "A".
      * Language code uses letters and is not a numeric quantity.
       01 WS-LANGUAGE-CODE PIC A(2) VALUE "EN".
       PROCEDURE DIVISION.
      * The first output lines identify what this catalog demonstrates.
           DISPLAY "Account field data types"
           DISPLAY "Text keys preserve their declared characters:"
           DISPLAY "Account key=" WS-ACCOUNT-KEY
           DISPLAY "Customer name=" WS-CUSTOMER-NAME
           DISPLAY "Customer type=" WS-CUSTOMER-TYPE
           DISPLAY "Account status=" WS-ACCOUNT-STATUS
           DISPLAY "Branch code=" WS-BRANCH-CODE
           DISPLAY "Currency code=" WS-CURRENCY-CODE
           DISPLAY "Opening date=" WS-OPEN-DATE-DIGITS
           DISPLAY "Customer number=" WS-CUSTOMER-NUMBER
           DISPLAY "Product code=" WS-PRODUCT-CODE
      * V uses no storage position; DISPLAY shows its decimal point.
           DISPLAY "Numeric account amounts and rates:"
           DISPLAY "Ledger balance=" WS-LEDGER-BALANCE
           DISPLAY "Available balance=" WS-AVAILABLE-BALANCE
           DISPLAY "Overdraft limit=" WS-OVERDRAFT-LIMIT
           DISPLAY "Last credit=" WS-LAST-CREDIT
           DISPLAY "Last debit=" WS-LAST-DEBIT
           DISPLAY "Interest rate=" WS-INTEREST-RATE
           DISPLAY "Fee rate=" WS-FEE-RATE
           DISPLAY "Monthly transaction count=" WS-MONTHLY-TXN-COUNT
           DISPLAY "Last batch sequence=" WS-LAST-BATCH-SEQ
           DISPLAY "Statement day=" WS-STATEMENT-DAY
      * The remaining fields are business codes, not arithmetic values.
           DISPLAY "Other account reference fields:"
           DISPLAY "Postal code=" WS-POSTAL-CODE
           DISPLAY "Country code=" WS-COUNTRY-CODE
           DISPLAY "Transfer reference=" WS-TRANSFER-REF
           DISPLAY "Batch ID=" WS-BATCH-ID
           DISPLAY "Customer initial=" WS-CUSTOMER-INITIAL
           DISPLAY "Language code=" WS-LANGUAGE-CODE
      * These sample fields are initialized by VALUE at program start.
      * VALUE is not a substitute for validating external input.
      * PIC 9 describes digit positions, not calendar or business rules.
      * PIC X retains the characters required by many business keys.
      * PIC A communicates an alphabetic category to maintainers.
      * V defines decimal scale without occupying a storage position.
      * S defines signedness; a separate sign is visible here.
      * A later lesson will change values with MOVE and COMPUTE.
           STOP RUN.
