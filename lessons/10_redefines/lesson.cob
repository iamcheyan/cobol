       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 样例值固定在程序内，无外部输入。
      * 交易码由接口契约保证与负载布局相符；
      * REDEFINES 不校验交易码，也不选择视图。
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
      * 重定义项必须紧邻被重定义项，且不得比它长。
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "入金口座=" WS-ACCOUNT-NUMBER
           DISPLAY "入金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "入金参照番号=" WS-REFERENCE.
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "取引種別=" WS-TRANSACTION-CODE
           DISPLAY "振込元口座=" WS-SOURCE-ACCOUNT
           DISPLAY "振込先口座=" WS-TARGET-ACCOUNT
           DISPLAY "振込金額=" WS-TRANSFER-AMOUNT
      * 故意用存款视图读取转账负载：
      * 同一字节的另一种解释，不是有效存款记录。
           DISPLAY "同じバイト列の入金ビュー:"
           DISPLAY "口座=" WS-ACCOUNT-NUMBER
           DISPLAY "金額=" WS-DEPOSIT-AMOUNT
           DISPLAY "参照番号=" WS-REFERENCE.
