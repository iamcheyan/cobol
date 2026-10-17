      *Contract: accounts.dat has no line breaks; records are 27 bytes.
      *Total bytes must be a multiple of 27 for aligned offsets.
      *OPEN OUTPUT replaces balances.dat; it does not append.
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
      *01 starts at col 8; 05 indents to col 11; levels set parents.
      *Input offsets: account 1-10, customer 11-18,
      *balance 19-27. V takes no byte; 9 digits = 7 integer + 2 decimal.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
      *Output is 27 bytes: customer 1-8, account 9-18,
      *balance 19-27. MOVE uses names; WRITE follows declaration order.
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
      *Two-digit count covers 3 rows; wraps at 100.
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
      *Fixed READ skips size checks: last row under 27 bytes,
      *GnuCOBOL 3.2.0 returns 00, retaining prior-row leftover bytes.
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
