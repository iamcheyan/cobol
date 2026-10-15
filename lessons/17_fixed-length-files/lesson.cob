      * 契约：accounts.dat 无换行，27 字节定长记录。
      * 总字节数须为 27 的整数倍，偏移才对齐。
      * OPEN OUTPUT 替换原 balances.dat，不追加。
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
      * 01 级从 Area A 第 8 列起，05 级缩进到第 11 列；层级号决定父子关系。
      * 输入偏移：账户号 1-10、客户号 11-18、
      * 余额 19-27。V 不占字节，9 个数字 = 7 位 + 2 位。
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
      * 输出同为 27 字节：客户号 1-8、账户号 9-18、
      * 余额 19-27。MOVE 按名，WRITE 按声明次序落盘。
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
      * 两位计数够本课 3 条；100 条时显示回绕。
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "入力ファイルを開けません STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "出力ファイルを開けません STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "ファイルを開きました"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 定长 READ 不核对总字节数：末条不足 27 字节时
      * GnuCOBOL 3.2.0 仍返回状态 00，保留上条残留字节。
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
               DISPLAY "出力 口座番号=" FD-OUT-ACCOUNT-NUMBER
                   " 顧客番号=" FD-OUT-CUSTOMER-ID
                   " 残高=" FD-OUT-BALANCE
           ELSE
               DISPLAY "書き込み失敗 STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "入力ファイルのクローズ失敗 STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "出力ファイルのクローズ失敗 STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "クローズ完了 件数=" WS-RECORD-COUNT.
