      * Samples are embedded; no terminal, file, or database input.
      * Rejection is a business result, not a system failure; code is 0.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * These four values are for this lesson, not business policy.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      * Echo the four inputs so the decision can be checked.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "口座状態=" WS-ACCOUNT-STATUS
           DISPLAY "取引金額=" WS-TRANSACTION-AMOUNT
           DISPLAY "上限金額=" WS-MAXIMUM-AMOUNT
      * Report the first failed rule; nesting below sets priority.
           IF WS-TRANSACTION-AMOUNT <= ZERO
      * Rule 1: amount must be positive; reject zero and negatives.
               DISPLAY "判定=REJECTED"
               DISPLAY "理由=AMOUNT_NOT_POSITIVE"
           ELSE
      * Rule 2: limit is inclusive; an amount at the limit proceeds.
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "判定=REJECTED"
                   DISPLAY "理由=AMOUNT_OVER_LIMIT"
               ELSE
      * Rule 3: only status A denotes an active account.
      * All other statuses use the same reason, regardless of code.
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "判定=ACCEPTED"
                       DISPLAY "理由=WITHIN_RULES"
                   ELSE
                       DISPLAY "判定=REJECTED"
                       DISPLAY "理由=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
           STOP RUN.
