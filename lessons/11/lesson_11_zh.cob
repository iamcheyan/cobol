       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      *读取当前表项中的代码和金额。
       2100-PROCESS-ENTRY.
           DISPLAY "条目=" WS-SAMPLE-INDEX
               " 代码=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " 金额=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "动作=贷记"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "动作=借记"
               WHEN OTHER
                   DISPLAY "动作=忽略未知代码"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
       9000-REPORT.
           DISPLAY "已处理=" WS-PROCESSED-COUNT
           DISPLAY "最终余额=" WS-ACCOUNT-BALANCE.
      *OCCURS 4 TIMES 在此固定表中定义四个表项。
      *每个表项都包含 WS-TXN-CODE 和 WS-TXN-AMOUNT。
      *第四个也是最后一个表项用下标 4 引用。
      *WS-LAST-SAMPLE 绝不能超过声明的表上限。
      *下标为 4 的表项会被处理，因为退出条件使用大于号。
      *示例在循环之前填充所有已分配的表项。
      *OCCURS 不加载值或检查交易业务规则。
      *声明表时不会自动排序或查找表项。
      *固定的 OCCURS 边界简化了存储规划和表审查。
      *保持表边界和循环范围一致。
      *避免使用超出声明表项范围的下标。
