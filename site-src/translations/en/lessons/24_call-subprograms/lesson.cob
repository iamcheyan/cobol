      * Call contract: pass amount PIC 9(7)V99 and result PIC X(15)
      * BY REFERENCE, matching CHECK-AMOUNT linkage order and types.
      * Business rejection writes result only; main exit code stays 0.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON24.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-AMOUNT PIC 9(7)V99 VALUE ZERO.
       01 WS-CHECK-RESULT PIC X(15) VALUE SPACES.
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
       01 WS-CHECK-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ZERO-COUNT PIC 9(3) VALUE ZERO.
       01 WS-LIMIT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "调用方：开始"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "调用方：子程序返回后继续"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
      * Eight cases cover zero, limit edges, minimum positive, and max.
       1000-RUN-CHECK-CASES.
           PERFORM 1100-CHECK-ORDINARY-AMOUNT
           PERFORM 1200-CHECK-ZERO-AMOUNT
           PERFORM 1300-CHECK-LIMIT-AMOUNT
           PERFORM 1400-CHECK-OVER-LIMIT-AMOUNT
           PERFORM 1500-CHECK-SMALL-POSITIVE
           PERFORM 1600-CHECK-BELOW-LIMIT
           PERFORM 1700-CHECK-LARGEST-AMOUNT
           PERFORM 1800-CHECK-MIDRANGE-AMOUNT.
       1100-CHECK-ORDINARY-AMOUNT.
           MOVE 125.50 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1200-CHECK-ZERO-AMOUNT.
           MOVE ZERO TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1300-CHECK-LIMIT-AMOUNT.
           MOVE 1000.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1400-CHECK-OVER-LIMIT-AMOUNT.
           MOVE 1000.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1500-CHECK-SMALL-POSITIVE.
           MOVE 0.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1600-CHECK-BELOW-LIMIT.
           MOVE 999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1700-CHECK-LARGEST-AMOUNT.
           MOVE 9999999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       1800-CHECK-MIDRANGE-AMOUNT.
           MOVE 500.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
       2000-CALL-AMOUNT-CHECK.
      * Clear result first: branches write it; clearing is defensive;
      * unwritten future branch falls to WHEN OTHER, not prior status.
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "调用前 金额=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "调用返回 状态="
               FUNCTION TRIM(WS-CHECK-RESULT TRAILING)
           PERFORM 2100-COUNT-CHECK-RESULT.
       2100-COUNT-CHECK-RESULT.
           ADD 1 TO WS-CHECK-COUNT
           EVALUATE WS-CHECK-RESULT
               WHEN "VALID"
                   ADD 1 TO WS-VALID-COUNT
               WHEN "ZERO-AMOUNT"
                   ADD 1 TO WS-ZERO-COUNT
                   ADD 1 TO WS-REJECT-COUNT
               WHEN "LIMIT-EXCEEDED"
                   ADD 1 TO WS-LIMIT-COUNT
                   ADD 1 TO WS-REJECT-COUNT
               WHEN OTHER
                   ADD 1 TO WS-REJECT-COUNT
           END-EVALUATE.
       3000-DISPLAY-SUMMARY.
           DISPLAY "检查总数=" WS-CHECK-COUNT
               " 有效=" WS-VALID-COUNT
               " 拒绝=" WS-REJECT-COUNT
           DISPLAY "零金额拒绝数=" WS-ZERO-COUNT
               " 超限拒绝数=" WS-LIMIT-COUNT.
