      * 出力は相対パス。実行時の作業場所に書く。
      * OPEN OUTPUTは同名を上書き。追記しない。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 受理-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-受理-STATUS.
           SELECT 拒否-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-拒否-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 受理-FILE.
       01 FD-受理-RECORD PIC X(35).
       FD 拒否-FILE.
       01 FD-拒否-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
      * サンプルはプログラム内のデモデータ。
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-受理-STATUS PIC XX VALUE SPACES.
       01 WS-拒否-STATUS PIC XX VALUE SPACES.
       01 WS-受理-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒否-COUNT PIC 9(2) VALUE ZERO.
      * 書込または閉鎖失敗で停止。終了コード1。
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN OUTPUT 受理-FILE
           IF WS-受理-STATUS NOT = "00"
               DISPLAY "オープン=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=受理 成功"
           OPEN OUTPUT 拒否-FILE
           IF WS-拒否-STATUS NOT = "00"
               DISPLAY "オープン=拒否 失敗 状態="
                   WS-拒否-STATUS
               CLOSE 受理-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=拒否 成功"
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
                   WRITE FD-受理-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-受理-STATUS = "00"
                       ADD 1 TO WS-受理-COUNT
                       DISPLAY "書込=受理"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=受理 失敗 状態="
                           WS-受理-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-拒否-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-拒否-STATUS = "00"
                       ADD 1 TO WS-拒否-COUNT
                       DISPLAY "書込=拒否"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=拒否 失敗 状態="
                           WS-拒否-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
      * 宛先はA/Rのみ。それ以外は失敗扱い。
               WHEN OTHER
                   DISPLAY "書込=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
       9000-CLOSE-OUTPUTS.
           CLOSE 受理-FILE
           IF WS-受理-STATUS = "00"
               DISPLAY "クローズ=受理 成功"
           ELSE
               DISPLAY "クローズ=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE 拒否-FILE
           IF WS-拒否-STATUS = "00"
               DISPLAY "クローズ=拒否 成功"
           ELSE
               DISPLAY "クローズ=拒否 失敗 状態="
                   WS-拒否-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY 受理=" WS-受理-COUNT
               " 拒否=" WS-拒否-COUNT.
