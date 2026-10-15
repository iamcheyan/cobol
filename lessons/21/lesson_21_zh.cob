      * 每条源记录为27字符：账户号10、客户编号8、余额9。排序键是十字符账户号，前导零有意义。
      * SORT调用输入过程读取至EOF。每条记录复制到SD记录后RELEASE。装载结束时检查源文件状态并关闭源文件。
      * 排序完成后，输出过程逐条RETURN。RETURN AT END表示正常结束；成功取出的记录计数后按键升序显示。
      * 文件错误或非零SORT-RETURN会返回失败状态。比较输入与输出计数有助发现记录丢失。源文件不变，也不创建输出文件。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORT21.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT UNSORTED-INPUT
               ASSIGN TO "accounts-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD UNSORTED-INPUT.
       01 FD-INPUT-RECORD PIC X(27).
       SD SORT-WORK.
       01 SD-SORT-RECORD.
          05 SD-ACCOUNT-NUMBER PIC X(10).
          05 SD-CUSTOMER-ID PIC X(8).
          05 SD-ACCOUNT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-OUTPUT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER
               INPUT PROCEDURE 1000-LOAD-INPUT
               OUTPUT PROCEDURE 2000-RETURN-SORTED.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "排序失败 STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "输入记录数=" WS-INPUT-COUNT
               " 出力记录数=" WS-OUTPUT-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
       1000-LOAD-INPUT.
           OPEN INPUT UNSORTED-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "输入OPEN失败 STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE UNSORTED-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "输入关闭失败 STATUS="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
       1100-READ-AND-RELEASE.
           READ UNSORTED-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       MOVE FD-INPUT-RECORD TO SD-SORT-RECORD
                       RELEASE SD-SORT-RECORD
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-INPUT-COUNT
                       ELSE
                           DISPLAY "释放失败 STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "输入读取失败 STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
       2000-RETURN-SORTED.
           PERFORM UNTIL WS-SORT-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               RETURN SORT-WORK
                   AT END
                       MOVE "Y" TO WS-SORT-EOF
                   NOT AT END
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-OUTPUT-COUNT
                           DISPLAY "排序结果 账户号="
                               SD-ACCOUNT-NUMBER
                               " 客户号=" SD-CUSTOMER-ID
                               " 余额=" SD-ACCOUNT-BALANCE
                       ELSE
                           DISPLAY "返回失败 STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
               END-RETURN
           END-PERFORM.
