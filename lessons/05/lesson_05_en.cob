      * WHEN OTHER handles any code without a named WHEN alternative.
      * Use code values defined by the interface contract in production.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
       PROCEDURE DIVISION.
           DISPLAY "Transaction reference="
               WS-TRANSACTION-REFERENCE
           DISPLAY "Transaction code=" WS-TRANSACTION-CODE
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "Category=DEPOSIT"
                   DISPLAY "Action=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "Category=WITHDRAWAL"
                   DISPLAY "Action=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "Category=TRANSFER"
                   DISPLAY "Action=PROCESS_BOTH_ACCOUNTS"
      * T identifies a transfer requiring both account identifiers.
               WHEN OTHER
                   DISPLAY "Category=UNKNOWN"
                   DISPLAY "Action=REJECT_FOR_REVIEW"
           END-EVALUATE
      * Lowercase d is not the uppercase code D used by the contract.
      * A transfer action needs both source and destination identifiers.
      * Unknown codes must never be silently interpreted as deposits.
      * Define whether blank codes are missing or malformed.
      * Exact matching means lowercase d does not match uppercase D.
           STOP RUN.
