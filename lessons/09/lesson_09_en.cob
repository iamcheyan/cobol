      *Duplicate STATUS names need parent qualification.
      *Leading zeroes remain significant in the account number.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-RECORD.
          05 WS-CUSTOMER-INFO.
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
      *STATUS is also used below, so references qualify its parent.
             10 WS-STATUS PIC X VALUE "A".
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
           DISPLAY "CUSTOMER ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "CUSTOMER NAME="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "ACCOUNT NUMBER="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
           DISPLAY "ACCOUNT STATUS=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "TRANSACTION ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "TRANSACTION CODE=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "TRANSACTION AMOUNT="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "TRANSACTION STATUS=" WS-STATUS OF WS-TXN-INFO
           DISPLAY "GROUP DATA=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      *This demonstration is not a portable interchange format.
