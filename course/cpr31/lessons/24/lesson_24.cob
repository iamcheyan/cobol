      * Lesson 24: CALL a separately compiled amount validator.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON24.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The amount uses implied cents in its numeric storage.
       01 WS-AMOUNT PIC 9(7)V99 VALUE ZERO.
      * The called program writes its decision into this caller field.
       01 WS-CHECK-RESULT PIC X(15) VALUE SPACES.
      * This edited field adds a decimal point only for DISPLAY.
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
      * Counters belong to this program and persist between calls.
       01 WS-CHECK-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ZERO-COUNT PIC 9(3) VALUE ZERO.
       01 WS-LIMIT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main stops only after each called program has returned.
       0000-MAIN.
           DISPLAY "CALLER=START"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "CALLER=RESUMED"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
      * Each case prepares a new value, then uses the same CALL.
       1000-RUN-CHECK-CASES.
           PERFORM 1100-CHECK-ORDINARY-AMOUNT
           PERFORM 1200-CHECK-ZERO-AMOUNT
           PERFORM 1300-CHECK-LIMIT-AMOUNT
           PERFORM 1400-CHECK-OVER-LIMIT-AMOUNT
           PERFORM 1500-CHECK-SMALL-POSITIVE
           PERFORM 1600-CHECK-BELOW-LIMIT
           PERFORM 1700-CHECK-LARGEST-AMOUNT
           PERFORM 1800-CHECK-MIDRANGE-AMOUNT.
      * This ordinary amount is inside the accepted range.
       1100-CHECK-ORDINARY-AMOUNT.
           MOVE 125.50 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * Zero is outside the business rule.
       1200-CHECK-ZERO-AMOUNT.
           MOVE ZERO TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * The configured maximum is inclusive.
       1300-CHECK-LIMIT-AMOUNT.
           MOVE 1000.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * One cent above the configured maximum is rejected.
       1400-CHECK-OVER-LIMIT-AMOUNT.
           MOVE 1000.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * The smallest positive amount can be accepted.
       1500-CHECK-SMALL-POSITIVE.
           MOVE 0.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * This value is just below the configured maximum.
       1600-CHECK-BELOW-LIMIT.
           MOVE 999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * PIC capacity and the business validation limit differ.
       1700-CHECK-LARGEST-AMOUNT.
           MOVE 9999999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * A midrange amount checks the rule away from both boundaries.
       1800-CHECK-MIDRANGE-AMOUNT.
           MOVE 500.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * CALL transfers control to the named program unit.
      * This literal matches PROGRAM-ID CHECK-AMOUNT in the callee.
      * USING passes the amount first and result storage second.
      * Default BY REFERENCE lets the callee update WS-CHECK-RESULT.
      * The caller reuses the same storage for every test amount.
       2000-CALL-AMOUNT-CHECK.
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=BEGIN AMOUNT=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "CALL=RETURN STATUS="
               FUNCTION TRIM(WS-CHECK-RESULT TRAILING)
           PERFORM 2100-COUNT-CHECK-RESULT.
      * Execution resumes here after the subprogram executes GOBACK.
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
      * The caller displays totals after all eight calls return.
       3000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY CHECKED=" WS-CHECK-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECT-COUNT
           DISPLAY "REJECT ZERO=" WS-ZERO-COUNT
               " OVER_LIMIT=" WS-LIMIT-COUNT.
