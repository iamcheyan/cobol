      *第16课：将分类交易结果写入两个文件。
      *OPEN OUTPUT 替换每个输出文件以前的任何内容。
      *每个 WRITE 发送一个完整的行顺序结果记录。
      *接受和拒绝的记录将发送到不同的目的地。
      *固定结果字符串的长度正好是 35 个字符。
      *此示例侧重于使用预先分类的记录的输出。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCEPTED-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCEPTED-FILE.
       01 FD-ACCEPTED-RECORD PIC X(35).
       FD REJECTED-FILE.
       01 FD-REJECTED-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
      *在写入任何结果记录之前打开两个输出。
       0000-MAIN.
           OPEN OUTPUT ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS NOT = "00"
               DISPLAY "OPEN=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCEPTED OK"
           OPEN OUTPUT REJECTED-FILE
           IF WS-REJECTED-STATUS NOT = "00"
               DISPLAY "OPEN=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               CLOSE ACCEPTED-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=REJECTED OK"
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
      *加载两个已接受和两个已拒绝的固定结果记录。
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
      *将一个预分类记录路由到其匹配的输出文件。
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-ACCEPTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-ACCEPTED-STATUS = "00"
                       ADD 1 TO WS-ACCEPTED-COUNT
                       DISPLAY "WRITE=ACCEPTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=ACCEPTED FAILED STATUS="
                           WS-ACCEPTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-REJECTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-REJECTED-STATUS = "00"
                       ADD 1 TO WS-REJECTED-COUNT
                       DISPLAY "WRITE=REJECTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=REJECTED FAILED STATUS="
                           WS-REJECTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN OTHER
                   DISPLAY "WRITE=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
      *写循环后关闭两个输出流。
       9000-CLOSE-OUTPUTS.
           CLOSE ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS = "00"
               DISPLAY "CLOSE=ACCEPTED OK"
           ELSE
               DISPLAY "CLOSE=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE REJECTED-FILE
           IF WS-REJECTED-STATUS = "00"
               DISPLAY "CLOSE=REJECTED OK"
           ELSE
               DISPLAY "CLOSE=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY ACCEPTED=" WS-ACCEPTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT.
      *OPEN OUTPUT 创建文件或替换其旧内容。
      *LINE SEQUENTIAL 以换行符结束每个写入记录。
      *FD记录大小和源结果大小都是35字节。
      *每个成功的 WRITE 将其文件状态设置为 00。
      *这两个文件具有独立的文件状态字段。
      *输出表的 A 或 R 标记决定目标文件。
      *结果记录按其原始表顺序写入。
      *仅在成功写入后计数才会增加。
      *失败的 OPEN 将在相应文件写入之前停止。
      *失败的写入会设置错误标志并停止以后的写入。
      *两个已打开的文件在写入循环结束后关闭。
      *摘要报告每个文件成功写入的记录。
      *输出路径是相对于程序的当前目录的。
      *在临时目录中运行使生成的文件保持独立。
      *OPEN OUTPUT 不是追加模式；旧数据被替换。
      *当后面的课程需要追加行为时，请使用 OPEN EXTEND。
      *该示例不会读取上一课的输入文件。
      *它的行已经被分类，以保持书写为焦点。
      *这里不进行账户余额计算。
      *第 22 课项目将结合阅读、规则和输出。
      *成功的 CLOSE 会刷新未完成的记录缓冲区。
      *STOP RUN 结束文件写入演示。
