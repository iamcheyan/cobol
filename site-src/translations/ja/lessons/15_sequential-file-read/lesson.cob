       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      * 1行を1レコードとして上流から受け取る。
      * 長い行は分割。最大長は上流で制限。
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
      * FDは100文字固定。短い行は右を空白で埋める。
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
      * 件数は2桁。99件超で桁あふれ。
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
      * ファイルなしは状態35。READせず終了コード1。
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "オープン=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=はい レコード数=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "クローズ=OK"
           ELSE
               DISPLAY "クローズ=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
      * EOFは正常終了。フラグのみ設定し、件数外。
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
      * TRIMは表示のみ。レコード領域は100文字。
                   DISPLAY "レコード="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
