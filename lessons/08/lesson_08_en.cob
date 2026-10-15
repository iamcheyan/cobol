      * Lesson 08: run a small fixed-data account transaction batch.
      * This lesson combines fields, math, IF, EVALUATE, and PERFORM.
      * Named paragraphs separate setup, processing, and reporting.
      * Five fixed transactions exercise accepted and rejected paths.
      * No file, database, table, or terminal input is used here.
      * D credits the balance; W debits it when funds are sufficient.
      * Other transaction codes are rejected for review.
      * All amounts use two fractional positions for this example.
      * This is a learning batch, not a production ledger system.
      * Its input and output remain deterministic across runs.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH08.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Initial account balance before processing the sample batch.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-CURRENT-BALANCE PIC 9(7)V99 VALUE ZERO.
      * Sample index and last index control the inline PERFORM loop.
       01 WS-SAMPLE-INDEX PIC 9(3) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
      * The current sample code and amount are loaded on each pass.
       01 WS-TRANSACTION-CODE PIC X VALUE SPACE.
       01 WS-TRANSACTION-AMOUNT PIC S9(5)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE ZERO.
      * Counters distinguish processed, accepted, and rejected records.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main calls the three batch stages in dependency order.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-BATCH
           PERFORM 9000-REPORT
           STOP RUN.
      * Initialize shared balance and counters before processing.
       1000-INITIALIZE.
           MOVE WS-OPENING-BALANCE TO WS-CURRENT-BALANCE
           MOVE ZERO TO WS-PROCESSED-COUNT
           MOVE ZERO TO WS-ACCEPTED-COUNT
           MOVE ZERO TO WS-REJECTED-COUNT
           DISPLAY "Batch=START"
           DISPLAY "Opening balance=" WS-OPENING-BALANCE.
      * Process each fixed record in sequence using its sample number.
       2000-PROCESS-BATCH.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-LOAD-SAMPLE
               PERFORM 2200-CLASSIFY-AND-POST
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM.
      * Load the code and amount associated with each sample number.
       2100-LOAD-SAMPLE.
           EVALUATE WS-SAMPLE-INDEX
               WHEN 1
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE 125.50 TO WS-TRANSACTION-AMOUNT
               WHEN 2
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 40.10 TO WS-TRANSACTION-AMOUNT
               WHEN 3
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 1500.00 TO WS-TRANSACTION-AMOUNT
               WHEN 4
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE -5.00 TO WS-TRANSACTION-AMOUNT
               WHEN 5
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE 25.00 TO WS-TRANSACTION-AMOUNT
               WHEN OTHER
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE ZERO TO WS-TRANSACTION-AMOUNT
           END-EVALUATE
           DISPLAY "Record=" WS-SAMPLE-INDEX
               " CODE=" WS-TRANSACTION-CODE
               " AMOUNT=" WS-TRANSACTION-AMOUNT.
      * Classify the current record and apply only accepted amounts.
       2200-CLASSIFY-AND-POST.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       COMPUTE WS-CURRENT-BALANCE =
                           WS-CURRENT-BALANCE
                               + WS-TRANSACTION-AMOUNT
                       COMPUTE WS-ACCEPTED-COUNT =
                           WS-ACCEPTED-COUNT + 1
                       DISPLAY "Result=ACCEPTED REASON=DEPOSIT"
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "Result=REJECTED"
                           " REASON=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN "W"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       IF WS-TRANSACTION-AMOUNT
                           <= WS-CURRENT-BALANCE
                           COMPUTE WS-CURRENT-BALANCE =
                               WS-CURRENT-BALANCE
                                   - WS-TRANSACTION-AMOUNT
                           COMPUTE WS-ACCEPTED-COUNT =
                               WS-ACCEPTED-COUNT + 1
                           DISPLAY "Result=ACCEPTED"
                               " REASON=WITHDRAWAL"
                       ELSE
                           COMPUTE WS-REJECTED-COUNT =
                               WS-REJECTED-COUNT + 1
                           DISPLAY "Result=REJECTED"
                               " REASON=INSUFFICIENT_FUNDS"
                       END-IF
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "Result=REJECTED"
                           " REASON=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN OTHER
                   COMPUTE WS-REJECTED-COUNT =
                       WS-REJECTED-COUNT + 1
                   DISPLAY "Result=REJECTED"
                       " REASON=UNKNOWN_TRANSACTION_CODE"
           END-EVALUATE.
      * Report totals and the balance after the complete sample batch.
       9000-REPORT.
           DISPLAY "Processed=" WS-PROCESSED-COUNT
           DISPLAY "Accepted=" WS-ACCEPTED-COUNT
           DISPLAY "Rejected=" WS-REJECTED-COUNT
           DISPLAY "Final balance=" WS-CURRENT-BALANCE.
      * The main paragraph is the program's only entry sequence.
      * Each PERFORM returns to the statement after its paragraph call.
      * The process paragraph uses PERFORM VARYING for record iteration.
      * The load paragraph separates fixed data from business rules.
      * EVALUATE maps the sample index to its fixed code and amount.
      * A second EVALUATE selects deposit, withdrawal, or unknown logic.
      * IF checks positive amount and available funds before posting.
      * Rejected records increase the count and leave balance unchanged.
      * Accepted records change the balance and accepted count together.
      * The processed count increases once after each complete record.
      * Five records produce two accepted and three rejected outcomes.
      * The credit raises balance from 1000.00 to 1125.50.
      * The valid withdrawal lowers balance to 1085.40.
      * Oversized withdrawals are rejected without changing balance.
      * The negative deposit is rejected before the balance is changed.
      * The unknown code is rejected without posting its amount.
      * Counters report record outcomes, not accounting entries.
      * Initialization precedes every transaction-processing step.
      * The report reads shared totals after processing returns.
      * Periods end each paragraph's final sentence.
      * EVALUATE embeds samples until the table lesson.
      * Later lessons store samples in reusable data structures.
      * Production batches also need file status and restart handling.
      * Define production rules for concurrency and idempotency.
      * STOP RUN ends this integrated language-basics example.
