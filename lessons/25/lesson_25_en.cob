      * Lesson 25: compare USING data directions and argument modes.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON25.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * One shared contract is copied into caller and callee programs.
      * It keeps signedness and binary storage size consistent.
       COPY "AMOUNT-INTERFACE.CPY".
      * All three source programs compile from this declaration.
      * Expected caller storage after each call returns.
       01 WS-EXPECTED USAGE BINARY-LONG VALUE ZERO.
      * Actual caller storage is copied before comparison.
       01 WS-ACTUAL USAGE BINARY-LONG VALUE ZERO.
      * This edited field adds leading zeroes for readable output.
       01 WS-EDITED-ACTUAL PIC 9(9) VALUE ZERO.
       01 WS-MODE PIC X(15) VALUE SPACES.
      * These counters belong to the caller between program calls.
       01 WS-PASS-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FAIL-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REFERENCE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CONTENT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALUE-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main stops only after all three subprogram calls return.
       0000-MAIN.
           PERFORM 1000-RUN-MODE-CASES
           PERFORM 9000-DISPLAY-SUMMARY
           IF WS-FAIL-COUNT NOT = ZERO
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Run one check for each argument-passing mode.
       1000-RUN-MODE-CASES.
           PERFORM 1100-TEST-REFERENCE
           PERFORM 1200-TEST-CONTENT
           PERFORM 1300-TEST-VALUE.
      * BY REFERENCE shares caller storage with ADD-ONE.
      * The subprogram's linkage item names the same interface item.
       1100-TEST-REFERENCE.
      * Expected 11 is the result of adding one to the initial 10.
           MOVE 10 TO AMOUNT-ARGUMENT
           MOVE 11 TO WS-EXPECTED
           MOVE "BY REFERENCE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY CONTENT gives ADD-ONE a temporary copy to change.
      * The increment in that temporary cannot change caller storage.
       1200-TEST-CONTENT.
           MOVE 20 TO AMOUNT-ARGUMENT
           MOVE 20 TO WS-EXPECTED
           MOVE "BY CONTENT" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUE passes a full-word integer to REPORT-BINARY.
      * The callee reads the value without a caller storage address.
       1300-TEST-VALUE.
           MOVE 30 TO AMOUNT-ARGUMENT
           MOVE 30 TO WS-EXPECTED
           MOVE "BY VALUE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "REPORT-BINARY" USING BY VALUE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BINARY-LONG provides the full-word type used by BY VALUE here.
      * The caller sets expected storage before making each call.
       8000-DISPLAY-BEFORE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-ACTUAL
           DISPLAY "CALLER=BEFORE MODE="
               FUNCTION TRIM(WS-MODE TRAILING)
               " VALUE=" WS-EDITED-ACTUAL.
      * Check the caller-visible value after the subprogram returns.
      * A separate actual field keeps the caller item unmodified.
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
               DISPLAY "CALLER=AFTER MODE="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " VALUE=" WS-EDITED-ACTUAL " CHECK=PASS"
           ELSE
               ADD 1 TO WS-FAIL-COUNT
               DISPLAY "CALLER=AFTER MODE="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " VALUE=" WS-EDITED-ACTUAL " CHECK=FAIL"
           END-IF.
      * The final process status reflects caller-side verification.
      * A mismatch is reported as a failed process status.
      * Per-mode totals identify which calling convention passed.
       9000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY PASS=" WS-PASS-COUNT
               " FAIL=" WS-FAIL-COUNT
           DISPLAY "MODE REFERENCE=" WS-REFERENCE-COUNT
               " CONTENT=" WS-CONTENT-COUNT " VALUE=" WS-VALUE-COUNT.
