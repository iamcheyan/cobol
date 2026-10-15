      * 读取定长账户主档，并将客户编号放在输出记录首位。
      * 每条记录为27字节：账户号10字节、客户号8字节、余额9字节。
      * 记录之间没有换行；输出记录仍为27字节。
      * 先打开输入和输出，再逐条读取并按新顺序写出。
      * 输出无法打开时先关闭输入，并返回失败状态。
      * READ AT END表示正常EOF；EOF时不写出记录。
      * 只有写入成功才增加计数；读写故障会终止批次。
      * 余额PIC中的V表示隐含小数点，不占用字节。
      * OPEN OUTPUT会覆盖已有文件，请使用可丢弃的输出路径。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXED17.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "accounts.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT BALANCE-FILE
               ASSIGN TO "balances.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BALANCE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD BALANCE-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-BALANCE-RECORD.
          05 FD-OUT-CUSTOMER-ID PIC X(8).
          05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
          05 FD-OUT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-BALANCE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "OPEN=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=INPUT OK OPEN=OUTPUT OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-READ-AND-WRITE.
           READ ACCOUNT-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   PERFORM 1100-WRITE-BALANCE-RECORD
           END-READ.
       1100-WRITE-BALANCE-RECORD.
           MOVE FD-CUSTOMER-ID TO FD-OUT-CUSTOMER-ID
           MOVE FD-ACCOUNT-NUMBER TO FD-OUT-ACCOUNT-NUMBER
           MOVE FD-ACCOUNT-BALANCE TO FD-OUT-BALANCE
           WRITE FD-BALANCE-RECORD
           IF WS-BALANCE-STATUS = "00"
               ADD 1 TO WS-RECORD-COUNT
               DISPLAY "WROTE ACCOUNT=" FD-OUT-ACCOUNT-NUMBER
                   " CUSTOMER=" FD-OUT-CUSTOMER-ID
                   " BALANCE=" FD-OUT-BALANCE
           ELSE
               DISPLAY "WRITE=FAILED STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "CLOSE=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "CLOSE=OK RECORDS=" WS-RECORD-COUNT.
