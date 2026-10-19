       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH08.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-CURRENT-BALANCE PIC 9(7)V99 VALUE ZERO.
       01 WS-SAMPLE-INDEX PIC 9(3) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
       01 WS-TRANSACTION-CODE PIC X VALUE SPACE.
       01 WS-TRANSACTION-AMOUNT PIC S9(5)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE ZERO.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-BATCH
           PERFORM 9000-REPORT
           STOP RUN.
       1000-INITIALIZE.
           MOVE WS-OPENING-BALANCE TO WS-CURRENT-BALANCE
           MOVE ZERO TO WS-PROCESSED-COUNT
           MOVE ZERO TO WS-ACCEPTED-COUNT
           MOVE ZERO TO WS-REJECTED-COUNT
           DISPLAY "バッチ=START"
           DISPLAY "期首残高=" WS-OPENING-BALANCE.
       2000-PROCESS-BATCH.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-LOAD-SAMPLE
               PERFORM 2200-CLASSIFY-AND-POST
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM.
       2100-LOAD-SAMPLE.
           EVALUATE WS-SAMPLE-INDEX
               WHEN 1
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE 125.50 TO WS-TRANSACTION-AMOUNT
               WHEN 2
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 40.10 TO WS-TRANSACTION-AMOUNT
               WHEN 3
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 1500.00 TO WS-TRANSACTION-AMOUNT
               WHEN 4
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE -5.00 TO WS-TRANSACTION-AMOUNT
               WHEN 5
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE 25.00 TO WS-TRANSACTION-AMOUNT
               WHEN OTHER
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE ZERO TO WS-TRANSACTION-AMOUNT
           END-EVALUATE
           DISPLAY "レコード=" WS-SAMPLE-INDEX
               " 符号=" WS-TRANSACTION-CODE
               " 金額=" WS-TRANSACTION-AMOUNT.
       2200-CLASSIFY-AND-POST.
      * 規則：Dは入金。Wは残高以内で出金。同額可。
      * 他コード拒否。拒否数を加算し残高不変。
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       COMPUTE WS-CURRENT-BALANCE =
                           WS-CURRENT-BALANCE
                               + WS-TRANSACTION-AMOUNT
                       COMPUTE WS-ACCEPTED-COUNT =
                           WS-ACCEPTED-COUNT + 1
                       DISPLAY "結果=ACCEPTED 理由=DEPOSIT"
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "結果=REJECTED"
                           " 理由=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN "W"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       IF WS-TRANSACTION-AMOUNT
                           <= WS-CURRENT-BALANCE
                           COMPUTE WS-CURRENT-BALANCE =
                               WS-CURRENT-BALANCE
                                   - WS-TRANSACTION-AMOUNT
                           COMPUTE WS-ACCEPTED-COUNT =
                               WS-ACCEPTED-COUNT + 1
                           DISPLAY "結果=ACCEPTED"
                               " 理由=WITHDRAWAL"
                       ELSE
                           COMPUTE WS-REJECTED-COUNT =
                               WS-REJECTED-COUNT + 1
                           DISPLAY "結果=REJECTED"
                               " 理由=INSUFFICIENT_FUNDS"
                       END-IF
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "結果=REJECTED"
                           " 理由=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN OTHER
                   COMPUTE WS-REJECTED-COUNT =
                       WS-REJECTED-COUNT + 1
                   DISPLAY "結果=REJECTED"
                       " 理由=UNKNOWN_TRANSACTION_CODE"
           END-EVALUATE.
       9000-REPORT.
      * 3件数は処理結果であり、会計科目ではない。
           DISPLAY "処理件数=" WS-PROCESSED-COUNT
           DISPLAY "承認件数=" WS-ACCEPTED-COUNT
           DISPLAY "拒否件数=" WS-REJECTED-COUNT
           DISPLAY "最終残高=" WS-CURRENT-BALANCE.
