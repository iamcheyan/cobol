      * Call a separately compiled amount validator and exchange a
      * result through caller storage.
      * The calling contract passes PIC 9(7)V99 amount and PIC X(15)
      * result fields. The callee returns ZERO-AMOUNT, LIMIT-EXCEEDED,
      * or VALID; the limit of 1000.00 is inclusive.
      * The main flow prepares eight representative and boundary values,
      * then calls the same subprogram through a shared paragraph. That
      * paragraph clears the result field and passes both fields by
      * reference.
      * The callee checks zero, then values above the limit, and
      * classifies all others as valid. It writes the decision into
      * caller storage and returns with GOBACK. The caller displays the
      * result and updates the matching counters after return.
      * After all cases, the summary reports checked, valid, rejected,
      * and reason-specific totals.
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
           DISPLAY "CALLER=START"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "CALLER=RESUMED"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
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
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=BEGIN AMOUNT=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "CALL=RETURN STATUS="
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
           DISPLAY "SUMMARY CHECKED=" WS-CHECK-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECT-COUNT
           DISPLAY "REJECT ZERO=" WS-ZERO-COUNT
               " OVER_LIMIT=" WS-LIMIT-COUNT.
