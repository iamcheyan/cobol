      * The positive amount rule rejects zero and all negative amounts.
      * The maximum amount is inclusive: its exact limit is accepted.
      * An account must also have active status to pass this example.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
           DISPLAY "Transaction reference="
               WS-TRANSACTION-REFERENCE
           DISPLAY "name=" WS-ACCOUNT-STATUS
           DISPLAY "Transaction amount=" WS-TRANSACTION-AMOUNT
           DISPLAY "Maximum amount=" WS-MAXIMUM-AMOUNT
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "Decision=REJECTED"
               DISPLAY "Reason=AMOUNT_NOT_POSITIVE"
           ELSE
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "Decision=REJECTED"
                   DISPLAY "Reason=AMOUNT_OVER_LIMIT"
               ELSE
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "Decision=ACCEPTED"
                       DISPLAY "Reason=WITHIN_RULES"
                   ELSE
                       DISPLAY "Decision=REJECTED"
                       DISPLAY "Reason=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * Reason text identifies the highest-priority failed rule.
      * Rejection reports a business result, not a system error.
      * A rejection is a business outcome, not a system I/O failure.
           STOP RUN.
