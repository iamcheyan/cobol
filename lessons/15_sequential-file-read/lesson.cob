       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      * 分行输入：上游按行送达，1 行即 1 条记录。
      * 超长行会拆成多条记录，最大行长由上游限定。
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
      * FD 记录区固定 100 字符，短行右侧补空格。
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
      * 计数两位，超过 99 条会回绕。
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
      * 文件缺失时状态 35；不进入 READ，退出码 1。
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
      * EOF 是正常结束，不是错误；只置标志不计数。
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
      * TRIM 只影响显示，记录区仍是 100 字符。
                   DISPLAY "レコード="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
