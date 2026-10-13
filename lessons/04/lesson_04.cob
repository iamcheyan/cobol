      * Lesson 04: decide whether one transaction passes account rules.
      * This example demonstrates nested IF and explicit ELSE paths.
      * Values are fixed in WORKING-STORAGE for repeatable runs.
      * The example validates a single amount and account status only.
      * No balance, files, or external input are used here.
      * The positive amount rule rejects zero and all negative amounts.
      * The maximum amount is inclusive: its exact limit is accepted.
      * An account must also have active status to pass this example.
      * Each branch displays its own decision and reason.
      * PROGRAM-ID supplies the name used when compiling this source.
      * The DATA DIVISION separates values from executable logic.
      * Each 01 entry defines one elementary field in this example.
      * The procedure uses conditions and DISPLAY statements only.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Keep a text reference as an identifier, including its hyphens.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * A means active in this small, explicitly stated status scheme.
      * Other status values are treated as inactive by this example.
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
      * Signed amount allows the validation rule to reject negatives.
      * A separate sign makes positive and negative output unambiguous.
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
      * This limit is a teaching rule, not a bank product limit.
      * The transaction amount and limit both have two decimals.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
      * The reference has no arithmetic meaning in this program.
      * Account status is a one-character business code.
      * The signed amount lets us test a negative input value.
      * The policy limit is unsigned and has two decimal positions.
       PROCEDURE DIVISION.
      * Show the input values before selecting a business path.
           DISPLAY "TRANSACTION-REFERENCE="
               WS-TRANSACTION-REFERENCE
           DISPLAY "ACCOUNT-STATUS=" WS-ACCOUNT-STATUS
           DISPLAY "TRANSACTION-AMOUNT=" WS-TRANSACTION-AMOUNT
           DISPLAY "MAXIMUM-AMOUNT=" WS-MAXIMUM-AMOUNT
      * The first rule handles the lower boundary.
      * Its false path continues to the next validation rule.
      * Nested tests run only while each earlier rule has passed.
      * Reject zero and negative values before testing the upper limit.
      * This ELSE belongs to the lower-bound condition above.
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "DECISION=REJECTED"
               DISPLAY "REASON=AMOUNT_NOT_POSITIVE"
           ELSE
      * A value exactly equal to the limit passes this comparison.
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "DECISION=REJECTED"
                   DISPLAY "REASON=AMOUNT_OVER_LIMIT"
               ELSE
      * Only an amount within both numeric boundaries reaches this test.
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "DECISION=ACCEPTED"
                       DISPLAY "REASON=WITHIN_RULES"
                   ELSE
                       DISPLAY "DECISION=REJECTED"
                       DISPLAY "REASON=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * The first END-IF closes the account-status test.
      * The second END-IF closes the amount-limit test.
      * The third END-IF closes the positive-amount test.
      * Each nested IF has one ELSE for its false path.
      * At the limit, greater-than is false; processing continues.
      * END-IF closes its condition without ending the sentence.
      * A period at STOP RUN closes this COBOL sentence.
      * Explicit scopes show which IF owns each ELSE branch.
      * Reason text identifies the highest-priority failed rule.
      * The comparison operator defines the inclusive upper boundary.
      * Indentation helps readers but does not control COBOL scope.
      * Numeric comparisons use the actual values, not the display text.
      * Both values are numeric with two fractional positions.
      * No file status or persistent ledger is modeled in this lesson.
      * Real systems also need authorization and duplicate checks.
      * They must define currency, transaction type, and posting rules.
      * Rejection reports a business result, not a system error.
      * A later lesson will process several transactions with PERFORM.
      * EVALUATE will be introduced separately for multiple code values.
      * Fixed values keep each compile-and-run check deterministic.
      * Change one VALUE clause at a time for the boundary exercise.
      * Test both sides of every rule before trusting a batch decision.
      * The amount must be greater than zero to pass the first check.
      * The exact maximum is allowed by the previous test.
      * Any amount above the maximum is rejected by the second check.
      * A valid amount is accepted only when status is active.
      * Status comparison is a character equality test against A.
      * Unknown status characters follow the inactive-account branch.
      * The branch output identifies the first failed rule only.
      * The first failed nested test determines the reported reason.
      * Rule ordering must match the business contract.
      * The program displays only one decision for the one fixed record.
      * No value is changed while the nested IF statements execute.
      * DISPLAY statements inside a selected branch run in source order.
      * Statements in the other branches are skipped for that run.
      * The final STOP RUN ends this one-record demonstration.
           STOP RUN.
