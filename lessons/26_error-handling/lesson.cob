      * 输入契约：每行 12 字节 = 账户号 X(6) + "|" + 金额数字 X(5)。
      * FD 缓冲区为 X(20)；21 字节以上的行或末行 20 字节无换行时 READ 报状态 06。
      * 政策：宽度、分隔符、金额非数字、零金额属业务拒绝，写拒绝文件后继续，不改返回码；
      * 只有非 EOF 的文件操作失败才令批次失败（RETURN-CODE=1）。
      * 恢复边界：仅关闭 OPEN 成功的文件；WRITE 状态不为 00 时不得计入受理。
      * 状态 00 只表示运行库接受了调用，不等于数据已落盘（见 README 写失败边界）。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERROR26.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT ACCEPTED-OUTPUT
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-OUTPUT
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(20).
       FD ACCEPTED-OUTPUT.
       01 FD-ACCEPTED-RECORD PIC X(12).
       FD REJECTED-OUTPUT.
       01 FD-REJECTED-RECORD PIC X(19).
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-SYSTEM-ERROR PIC X VALUE "N".
       01 WS-RECORD-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT PIC X(6) VALUE SPACES.
       01 WS-AMOUNT PIC X(5) VALUE SPACES.
       01 WS-REJECT-REASON PIC X(12) VALUE SPACES.
       01 WS-ACCEPTED-WORK PIC X(12) VALUE SPACES.
       01 WS-REJECTED-WORK PIC X(19) VALUE SPACES.
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           IF WS-SYSTEM-ERROR = "N"
               PERFORM 2000-PROCESS-INPUT
           END-IF
           PERFORM 8000-CLOSE-FILES
           DISPLAY "集計 入力=" WS-INPUT-COUNT
               " 受理=" WS-ACCEPTED-COUNT
               " 拒否=" WS-REJECTED-COUNT
           DISPLAY "システムエラー=" WS-SYSTEM-ERROR
           IF WS-SYSTEM-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-OPEN-FILES.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               DISPLAY "エラー=入力OPEN 状態=" WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "エラー=受理出力オープン 状態="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT REJECTED-OUTPUT
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "エラー=拒否出力オープン 状態="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF.
       2000-PROCESS-INPUT.
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-SYSTEM-ERROR = "Y"
               PERFORM 2100-READ-ONE-RECORD
           END-PERFORM.
      * AT END 只覆盖状态 10；其余非零状态（含超长行的 06）按系统故障处理。
       2100-READ-ONE-RECORD.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       ADD 1 TO WS-INPUT-COUNT
                       PERFORM 3000-VALIDATE-RECORD
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "エラー=入力読取 状態="
                   WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 记录布局来自上游契约：1:6 账户号、7:1 分隔符、8:5 金额。
      * 先按去尾空格后的实际宽度分流；宽度不符时不再解析分隔符与金额。
       3000-VALIDATE-RECORD.
           MOVE SPACES TO WS-REJECT-REASON
           MOVE FD-TRANSACTION-RECORD(1:6) TO WS-ACCOUNT
           COMPUTE WS-RECORD-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING))
           IF WS-RECORD-LENGTH NOT = 12
               MOVE "BAD_WIDTH" TO WS-REJECT-REASON
           ELSE
               IF FD-TRANSACTION-RECORD(7:1) NOT = "|"
                   MOVE "BAD_FORMAT" TO WS-REJECT-REASON
               ELSE
                   MOVE FD-TRANSACTION-RECORD(8:5)
                       TO WS-AMOUNT
                   IF WS-AMOUNT IS NOT NUMERIC
                       MOVE "BAD_AMOUNT" TO WS-REJECT-REASON
                   ELSE
                       IF WS-AMOUNT = "00000"
                           MOVE "ZERO_AMOUNT" TO WS-REJECT-REASON
                       END-IF
                   END-IF
               END-IF
           END-IF
           IF WS-REJECT-REASON = SPACES
               PERFORM 4000-WRITE-ACCEPTED
           ELSE
               PERFORM 5000-WRITE-REJECTED
           END-IF.
      * 受理行沿用输入前 12 字节，保证结果文件宽度与输入契约一致。
       4000-WRITE-ACCEPTED.
           MOVE FD-TRANSACTION-RECORD(1:12)
               TO WS-ACCEPTED-WORK
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-WORK
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "受理口座=" WS-ACCOUNT
           ELSE
               DISPLAY "エラー=受理出力書込 状態="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 拒绝行 = 账户号 6 + "|" + 原因 X(12)；原因短于 12 字符时靠 LINE SEQUENTIAL
      * 去掉行尾填充空格，所以实际写出行短于 PIC X(19) 缓冲区。
       5000-WRITE-REJECTED.
           MOVE SPACES TO WS-REJECTED-WORK
           MOVE WS-ACCOUNT TO WS-REJECTED-WORK(1:6)
           MOVE "|" TO WS-REJECTED-WORK(7:1)
           MOVE WS-REJECT-REASON TO WS-REJECTED-WORK(8:12)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-WORK
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "拒否口座=" WS-ACCOUNT
                   " REASON="
                   FUNCTION TRIM(WS-REJECT-REASON TRAILING)
           ELSE
               DISPLAY "エラー=拒否出力書込 状態="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 只关闭 OPEN 成功的文件；受理输出打开失败时拒绝输出从未打开，不能盲关。
       8000-CLOSE-FILES.
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-OUTPUT
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "エラー=拒否出力クローズ 状態="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "エラー=受理出力クローズ 状態="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "エラー=入力クローズ 状態="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-INPUT-OPEN
           END-IF.
