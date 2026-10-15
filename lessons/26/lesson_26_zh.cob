      * 第26课：区分业务数据错误行与文件故障。
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
      * 只有发生系统 I/O 问题时，主程序才返回失败。
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           IF WS-SYSTEM-ERROR = "N"
               PERFORM 2000-PROCESS-INPUT
           END-IF
           PERFORM 8000-CLOSE-FILES
           DISPLAY "汇总 输入=" WS-INPUT-COUNT
               " 接受=" WS-ACCEPTED-COUNT
               " 拒绝=" WS-REJECTED-COUNT
           DISPLAY "系统错误=" WS-SYSTEM-ERROR
           IF WS-SYSTEM-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 创建任一输出文件前先打开输入文件。
       1000-OPEN-FILES.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               DISPLAY "错误=打开输入 状态=" WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "错误=打开接受输出 状态="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT REJECTED-OUTPUT
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "错误=打开拒绝输出 状态="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF.
      * AT END 处理文件结束；其他状态仍视为系统错误。
       2000-PROCESS-INPUT.
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-SYSTEM-ERROR = "Y"
               PERFORM 2100-READ-ONE-RECORD
           END-PERFORM.
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
               DISPLAY "错误=读取输入 状态="
                   WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 业务验证会拒绝该行并继续处理批次。
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
      * 只有输出 WRITE 成功后才统计有效行。
       4000-WRITE-ACCEPTED.
           MOVE FD-TRANSACTION-RECORD(1:12)
               TO WS-ACCEPTED-WORK
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-WORK
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "接受账户=" WS-ACCOUNT
           ELSE
               DISPLAY "错误=写入接受输出 状态="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 格式错误的业务行会被记录，处理随后继续。
       5000-WRITE-REJECTED.
           MOVE SPACES TO WS-REJECTED-WORK
           MOVE WS-ACCOUNT TO WS-REJECTED-WORK(1:6)
           MOVE "|" TO WS-REJECTED-WORK(7:1)
           MOVE WS-REJECT-REASON TO WS-REJECTED-WORK(8:12)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-WORK
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "拒绝账户=" WS-ACCOUNT
                   " REASON="
                   FUNCTION TRIM(WS-REJECT-REASON TRAILING)
           ELSE
               DISPLAY "错误=写入拒绝输出 状态="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 关闭每个已成功 OPEN 的文件，并检查各自状态。
       8000-CLOSE-FILES.
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-OUTPUT
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "错误=关闭拒绝输出 状态="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "错误=关闭接受输出 状态="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "错误=关闭输入 状态="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-INPUT-OPEN
           END-IF.
