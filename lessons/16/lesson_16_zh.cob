      *OPEN OUTPUT 替换每个输出文件以前的任何内容。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 接受-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-接受-STATUS.
           SELECT 拒绝-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-拒绝-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 接受-FILE.
       01 FD-接受-RECORD PIC X(35).
       FD 拒绝-FILE.
       01 FD-拒绝-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-接受-STATUS PIC XX VALUE SPACES.
       01 WS-拒绝-STATUS PIC XX VALUE SPACES.
       01 WS-接受-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒绝-COUNT PIC 9(2) VALUE ZERO.
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT 接受-FILE
           IF WS-接受-STATUS NOT = "00"
               DISPLAY "打开=接受 失败 状态="
                   WS-接受-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "打开=接受 成功"
           OPEN OUTPUT 拒绝-FILE
           IF WS-拒绝-STATUS NOT = "00"
               DISPLAY "打开=拒绝 失败 状态="
                   WS-拒绝-STATUS
               CLOSE 接受-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "打开=拒绝 成功"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-接受-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-接受-STATUS = "00"
                       ADD 1 TO WS-接受-COUNT
                       DISPLAY "写入=接受"
                           " 交易=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "写入=接受 失败 状态="
                           WS-接受-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-拒绝-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-拒绝-STATUS = "00"
                       ADD 1 TO WS-拒绝-COUNT
                       DISPLAY "写入=拒绝"
                           " 交易=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "写入=拒绝 失败 状态="
                           WS-拒绝-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN OTHER
                   DISPLAY "写入=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
       9000-CLOSE-OUTPUTS.
           CLOSE 接受-FILE
           IF WS-接受-STATUS = "00"
               DISPLAY "关闭=接受 成功"
           ELSE
               DISPLAY "关闭=接受 失败 状态="
                   WS-接受-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE 拒绝-FILE
           IF WS-拒绝-STATUS = "00"
               DISPLAY "关闭=拒绝 成功"
           ELSE
               DISPLAY "关闭=拒绝 失败 状态="
                   WS-拒绝-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY 接受=" WS-接受-COUNT
               " 拒绝=" WS-拒绝-COUNT.
      *OPEN OUTPUT 创建文件或替换其旧内容。
      *OPEN OUTPUT 不是追加模式；旧数据被替换。
