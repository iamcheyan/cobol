       IDENTIFICATION DIVISION.
       PROGRAM-ID. DATA02.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * X is suitable for identifiers that may contain leading zeroes.
       01 WS-ACCOUNT-KEY PIC X(12) VALUE "000123456789".
       01 WS-CUSTOMER-NAME PIC A(12) VALUE "ADA LOVELACE".
       01 WS-CUSTOMER-TYPE PIC A(1) VALUE "P".
      * X accepts a status code; PIC alone is not a status-rule check.
       01 WS-ACCOUNT-STATUS PIC X(1) VALUE "A".
       01 WS-BRANCH-CODE PIC 9(4) VALUE 2048.
       01 WS-CURRENCY-CODE PIC X(3) VALUE "USD".
      * Digits can encode a date shape but do not validate its calendar.
       01 WS-OPEN-DATE-DIGITS PIC 9(8) VALUE 20261013.
      * X preserves leading zeroes in account number keys.
       01 WS-CUSTOMER-NUMBER PIC X(10) VALUE "0002046819".
       01 WS-PRODUCT-CODE PIC X(4) VALUE "SAV1".
       01 WS-LEDGER-BALANCE PIC 9(7)V99 VALUE 125000.75.
       01 WS-AVAILABLE-BALANCE PIC 9(7)V99 VALUE 123500.25.
       01 WS-OVERDRAFT-LIMIT PIC 9(7)V99 VALUE 2500.00.
       01 WS-LAST-CREDIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE 1250.50.
       01 WS-LAST-DEBIT PIC S9(7)V99 SIGN LEADING SEPARATE
           CHARACTER VALUE -75.25.
       01 WS-INTEREST-RATE PIC 9(2)V9(4) VALUE 0.0125.
       01 WS-FEE-RATE PIC 9(2)V9(4) VALUE 0.0030.
       01 WS-MONTHLY-TXN-COUNT PIC 9(4) VALUE 18.
       01 WS-LAST-BATCH-SEQ PIC 9(6) VALUE 521.
       01 WS-STATEMENT-DAY PIC 9(2) VALUE 25.
       01 WS-POSTAL-CODE PIC X(9) VALUE "00100-200".
       01 WS-COUNTRY-CODE PIC A(2) VALUE "JP".
       01 WS-TRANSFER-REF PIC X(15) VALUE "TRF-20261013-01".
       01 WS-BATCH-ID PIC X(14) VALUE "BATCH-20261013".
       01 WS-CUSTOMER-INITIAL PIC A(1) VALUE "A".
       01 WS-LANGUAGE-CODE PIC A(2) VALUE "EN".
       PROCEDURE DIVISION.
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
      * PIC 9 describes digit positions, not calendar or business rules.
           STOP RUN.
