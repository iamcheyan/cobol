      * 第25课：比较 USING 数据方向和参数传递模式。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON25.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 共享契约会复制到调用方和被调用方程序中，确保双方按同一布局解释参数。
       COPY "AMOUNT-INTERFACE.CPY".
      * 三个源程序都根据此声明编译。
      * 每次调用返回后调用方存储区中的预期值。
       01 WS-EXPECTED USAGE BINARY-LONG VALUE ZERO.
      * 比较前会复制调用方存储区的实际值。
       01 WS-ACTUAL USAGE BINARY-LONG VALUE ZERO.
      * 此编辑字段会添加前导零，以便清晰显示。
       01 WS-EDITED-ACTUAL PIC 9(9) VALUE ZERO.
       01 WS-MODE PIC X(15) VALUE SPACES.
      * 这些计数器在程序调用之间由调用方持有。
       01 WS-PASS-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FAIL-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REFERENCE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CONTENT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALUE-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 三个子程序都返回后，主程序才结束。
       0000-MAIN.
           PERFORM 1000-RUN-MODE-CASES
           PERFORM 9000-DISPLAY-SUMMARY
           IF WS-FAIL-COUNT NOT = ZERO
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 对每种参数传递模式分别执行一次检查。
       1000-RUN-MODE-CASES.
           PERFORM 1100-TEST-REFERENCE
           PERFORM 1200-TEST-CONTENT
           PERFORM 1300-TEST-VALUE.
      * BY REFERENCE 让 ADD-ONE 与调用方共享存储区。
      * 子程序的链接项指向同一个接口项。
       1100-TEST-REFERENCE.
      * 预期值 11 是在初始值 10 上加 1 的结果。
           MOVE 10 TO AMOUNT-ARGUMENT
           MOVE 11 TO WS-EXPECTED
           MOVE "BY REFERENCE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY CONTENT 为 ADD-ONE 提供可修改的临时副本。
      * 临时副本中的递增不会改变调用方存储区。
       1200-TEST-CONTENT.
           MOVE 20 TO AMOUNT-ARGUMENT
           MOVE 20 TO WS-EXPECTED
           MOVE "BY CONTENT" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUE 将全字长整数传递给 REPORT-BINARY。
      * 被调用方读取该值时无需调用方存储地址。
       1300-TEST-VALUE.
           MOVE 30 TO AMOUNT-ARGUMENT
           MOVE 30 TO WS-EXPECTED
           MOVE "BY VALUE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "REPORT-BINARY" USING BY VALUE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUE参数使用BINARY-LONG表示全字长整数。
      * 调用方在每次调用前设置期望值，再将实际值复制到独立字段比较。
       8000-DISPLAY-BEFORE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-ACTUAL
           DISPLAY "调用方=调用前 模式="
               FUNCTION TRIM(WS-MODE TRAILING)
               " 数值=" WS-EDITED-ACTUAL.
      * 子程序返回后检查调用方可见的值。
      * 单独的实际值字段可保持调用方数据项不变。
       8100-CHECK-ACTUAL.
           MOVE AMOUNT-ARGUMENT TO WS-ACTUAL
           MOVE WS-ACTUAL TO WS-EDITED-ACTUAL
           IF WS-ACTUAL = WS-EXPECTED
               ADD 1 TO WS-PASS-COUNT
               EVALUATE WS-MODE
                   WHEN "BY REFERENCE"
                       ADD 1 TO WS-REFERENCE-COUNT
                   WHEN "BY CONTENT"
                       ADD 1 TO WS-CONTENT-COUNT
                   WHEN "BY VALUE"
                       ADD 1 TO WS-VALUE-COUNT
               END-EVALUATE
               DISPLAY "调用方=调用后 模式="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " 数值=" WS-EDITED-ACTUAL " 校验=通过"
           ELSE
               ADD 1 TO WS-FAIL-COUNT
               DISPLAY "调用方=调用后 模式="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " 数值=" WS-EDITED-ACTUAL " 校验=失败"
           END-IF.
      * 最终进程状态反映调用方的验证结果。
      * 值不匹配时会报告失败的进程状态。
      * 各模式的汇总可指出哪种调用约定通过了检查。
       9000-DISPLAY-SUMMARY.
           DISPLAY "汇总 通过=" WS-PASS-COUNT
               " 失败=" WS-FAIL-COUNT
           DISPLAY "模式 BY REFERENCE=" WS-REFERENCE-COUNT
               " CONTENT=" WS-CONTENT-COUNT " VALUE=" WS-VALUE-COUNT.
