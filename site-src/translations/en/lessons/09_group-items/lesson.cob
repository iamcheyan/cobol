       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Levels define parent-child structure; indentation aids reading.
      * Group items occupy consecutive bytes in order, no separators.
       01 WS-TRANSACTION-RECORD.
          05 WS-CUSTOMER-INFO.
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
             10 WS-STATUS PIC X VALUE "A".
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
      * External record buffer; fixed at 58 bytes like this record.
       01 WS-EXPORT-LINE PIC X(58).
       PROCEDURE DIVISION.
      * WS-STATUS is duplicated; use OF to specify the parent group.
           DISPLAY "顧客ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "顧客名="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "口座番号="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
           DISPLAY "口座状態=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "取引ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "取引コード=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "取引金額="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "取引状態=" WS-STATUS OF WS-TXN-INFO
      * Decimal point appears only when amount is displayed alone.
      * Group display outputs stored bytes without a decimal point.
           DISPLAY "グループデータ=[" WS-TRANSACTION-RECORD "]"
      * Group moves copy bytes without numeric conversion.
      * The receiving PIC sets width; both items are 58 bytes.
           MOVE WS-TRANSACTION-RECORD TO WS-EXPORT-LINE
           DISPLAY "外部記録=[" WS-EXPORT-LINE "]"
           STOP RUN.
