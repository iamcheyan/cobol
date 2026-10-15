      *帐号中的前导零仍然很重要。
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
             10 WS-STATUS PIC X VALUE "A".
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
           DISPLAY "客户编号="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "客户姓名="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "账户号码="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
           DISPLAY "账户状态=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "交易编号=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "交易类型=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "交易金额="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "交易状态=" WS-STATUS OF WS-TXN-INFO
           DISPLAY "组记录=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      *用其父组限定重复的名称。
      *可以显示叶子而不显示其父组。
