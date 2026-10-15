      * Lesson 05: classify one transaction code with EVALUATE.
      * Three known codes are deposit, withdrawal, and transfer.
      * A single subject is compared with the WHEN choices in order.
      * The selected branch reports a category and a business action.
      * WHEN OTHER handles any code without a named WHEN alternative.
      * The sample value is fixed so output remains repeatable.
      * This lesson classifies a transaction; it does not post it.
      * No account balance or external file is read or changed.
      * Use code values defined by the interface contract in production.
      * Unknown codes must be visible for rejection or review.
      * IDENTIFICATION names the program that owns this source file.
      * PROGRAM-ID gives the compiler a stable program name.
      * DATA DIVISION declares values used by the procedure.
      * WORKING-STORAGE keeps these sample values during this run.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * This reference identifies the fixed example transaction.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * A text reference preserves letters and leading zeroes.
      * PIC X defines storage shape, not a permitted-code list.
      * VALUE initializes the sample transaction code before execution.
      * The code is one character in the teaching interface.
      * D means deposit; W means withdrawal; T means transfer.
      * Any other value must fall through to WHEN OTHER.
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
      * One character is enough for this deliberately small code set.
       PROCEDURE DIVISION.
      * Display the input before classifying its code.
           DISPLAY "Transaction reference="
               WS-TRANSACTION-REFERENCE
           DISPLAY "Transaction code=" WS-TRANSACTION-CODE
      * DISPLAY adds the field contents after each output label.
      * Stable labels make the four code paths easy to compare.
      * EVALUATE checks one transaction code against its WHEN choices.
      * The subject is one character data item, not a condition.
      * Quoted WHEN literals compare character values exactly.
           EVALUATE WS-TRANSACTION-CODE
      * Deposits increase an account balance in a later processing step.
               WHEN "D"
                   DISPLAY "Category=DEPOSIT"
                   DISPLAY "Action=ADD_TO_ACCOUNT"
      * This label classifies D without changing a balance.
      * Withdrawals decrease an account balance in a later step.
               WHEN "W"
                   DISPLAY "Category=WITHDRAWAL"
                   DISPLAY "Action=SUBTRACT_FROM_ACCOUNT"
      * W has a distinct classification and action from D.
      * Transfers require source and destination account processing.
               WHEN "T"
                   DISPLAY "Category=TRANSFER"
                   DISPLAY "Action=PROCESS_BOTH_ACCOUNTS"
      * T identifies a transfer requiring both account identifiers.
      * Every unlisted value is explicitly marked for review.
      * The fallback keeps unsupported codes visible in output.
               WHEN OTHER
                   DISPLAY "Category=UNKNOWN"
                   DISPLAY "Action=REJECT_FOR_REVIEW"
           END-EVALUATE
      * This control statement does not change the input code.
      * The action label describes future work; it does not perform it.
      * Keep valid code values synchronized with the feed contract.
      * Add a WHEN branch only after confirming its business meaning.
      * END-EVALUATE ends the multiway selection statement.
      * Only the matching WHEN branch runs for this subject value.
      * WHEN OTHER runs only if no earlier WHEN choice matches.
      * Branches are not processed by falling through from one to next.
      * The reference and code are input data, not output categories.
      * Code matching is an exact character comparison in this example.
      * Lowercase d is not the uppercase code D used by the contract.
      * If lowercase is permitted, normalize it in a later lesson.
      * Do not invent extra aliases without agreement from the producer.
      * Each category maps to one declared business action label.
      * The action labels document intent; they do not move money.
      * A transfer action needs both source and destination identifiers.
      * Unknown codes must never be silently interpreted as deposits.
      * Production feeds need documented code ownership and versions.
      * Define whether blank codes are missing or malformed.
      * Log the transaction reference with each rejection reason.
      * A new code needs an agreed category and action mapping.
      * Exact matching means lowercase d does not match uppercase D.
      * The exercise changes one code at a time to isolate its path.
      * This one-record example has no count, loop, or file handling.
      * PERFORM will later repeat processing for a sequence of records.
      * Paragraphs will later separate classification from main flow.
      * IF from the previous lesson handles conditions and boundaries.
      * EVALUATE makes a fixed set of alternatives easy to scan.
      * WHEN choices should be mutually meaningful and easy to audit.
      * WHEN OTHER makes the default path visible to maintainers.
      * This statement is one sentence terminated by the final period.
      * END-EVALUATE closes the scope before the program ends.
      * The display output is stable for scripted learning checks.
      * Change the code VALUE and rerun to exercise each branch.
      * Restore the original value before comparing the next branch.
      * The branch displays exactly one category and one action.
      * No data item changes during this example's execution.
      * STOP RUN ends this single-transaction demonstration.
           STOP RUN.
