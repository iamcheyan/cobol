      * 将账户主档和每日交易作为彼此独立的顺序输入读取。
      * 两个文件都是行顺序文本，每条最多100字符。程序显示记录并计数，不解析字段，也不匹配账户。
      * 主流程在进入循环前打开两个必需输入。第二个OPEN失败时，关闭已打开的第一个文件并以失败状态退出。
      * 每轮最多从每个未到EOF的流读取一条。读取成功只增加对应流的计数；状态10只标记该文件到达EOF。
      * 一个流结束后，另一个仍继续读取。非EOF读取错误会停止循环。正常结束或读取失败后关闭已打开文件，并报告关闭错误。
      * OPEN、READ或CLOSE失败都会返回非零码。空文件属于正常EOF。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTI19.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-INPUT
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-INPUT.
       01 FD-ACCOUNT-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-ACCOUNT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT ACCOUNT-INPUT
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "账户文件打开失败 STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT TRANSACTION-INPUT
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "交易文件打开失败 STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-INPUT
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "账户与交易文件已打开"
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-ACCOUNT-EOF = "N"
                   PERFORM 1000-READ-ACCOUNT
               END-IF
               IF WS-TRANSACTION-EOF = "N"
                   AND WS-IO-ERROR = "N"
                   PERFORM 2000-READ-TRANSACTION
               END-IF
           END-PERFORM
           CLOSE ACCOUNT-INPUT
           CLOSE TRANSACTION-INPUT
           IF WS-ACCOUNT-STATUS = "00"
               AND WS-TRANSACTION-STATUS = "00"
               DISPLAY "关闭完成 账户记录数=" WS-ACCOUNT-COUNT
                   " 交易记录数=" WS-TRANSACTION-COUNT
           ELSE
               DISPLAY "关闭时账户文件异常 STATUS="
                   WS-ACCOUNT-STATUS
                   "交易文件异常 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-READ-ACCOUNT.
           READ ACCOUNT-INPUT
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   IF WS-ACCOUNT-STATUS = "00"
                       ADD 1 TO WS-ACCOUNT-COUNT
                       DISPLAY "账户主档："
                           FUNCTION TRIM(
                               FD-ACCOUNT-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "读取账户文件失败 STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       2000-READ-TRANSACTION.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   IF WS-TRANSACTION-STATUS = "00"
                       ADD 1 TO WS-TRANSACTION-COUNT
                       DISPLAY "交易："
                           FUNCTION TRIM(
                               FD-TRANSACTION-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "读取交易文件失败 STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
