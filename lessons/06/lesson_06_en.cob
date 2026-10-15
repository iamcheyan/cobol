      * Lesson 06: process a fixed sequence with PERFORM VARYING.
      * Three sample records demonstrate repeated sequential processing.
      * EVALUATE chooses details for each fixed sample.
      * It does not use a table; table storage comes in a later lesson.
      * The loop index begins at one and advances by one each iteration.
      * UNTIL index > last means the last index is included.
      * The loop checks its UNTIL condition before each iteration.
      * A last index of zero therefore processes no sample records.
      * The processed count records how many loop bodies actually ran.
      * No input file or database is read by this demonstration.
      * IDENTIFICATION DIVISION marks this program's source identity.
      * PROGRAM-ID names this standalone program.
      * DATA DIVISION declares storage used by the procedure.
      * WORKING-STORAGE keeps initial values during program execution.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Set to three for the complete fixed sample sequence.
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
      * VARYING initializes this index before its first test.
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
      * This counter is increased once for every processed sample.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * LAST-SAMPLE controls the loop's inclusive upper boundary.
      * VARYING changes the index through its FROM and BY clauses.
      * The processed count is separate from the loop index.
      * These PIC 9 fields are unsigned whole-number counters.
       PROCEDURE DIVISION.
      * Show the configured inclusive final sample number.
           DISPLAY "Last sample=" WS-LAST-SAMPLE
      * Iterate the sample numbers from one through the configured last.
      * The display before the loop also exposes zero-iteration runs.
      * FROM supplies the index's initial value for this execution.
      * BY supplies the step added after a completed loop body.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
      * EVALUATE maps each loop number to its fixed sample values.
               EVALUATE WS-SAMPLE-INDEX
      * Sample one is a deposit transaction.
                   WHEN 1
                       DISPLAY "Sample=001 CODE=D AMOUNT=125.50"
      * Sample two is a withdrawal transaction.
                   WHEN 2
                       DISPLAY "Sample=002 CODE=W AMOUNT=040.10"
      * Sample three is a transfer transaction.
                   WHEN 3
                       DISPLAY "Sample=003 CODE=T AMOUNT=075.00"
      * A higher limit reaches this branch after sample three.
                   WHEN OTHER
                       DISPLAY "Sample=UNMAPPED"
               END-EVALUATE
      * Count after the sample branch has completed.
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
      * The loop condition is tested before another iteration starts.
      * Each WHEN emits one sample line and continues the loop body.
      * COMPUTE increments the count after the sample branch.
      * DISPLAY after END-PERFORM reports the final count.
      * Show how many iterations actually passed the UNTIL test.
           DISPLAY "Samples processed=" WS-PROCESSED-COUNT
      * Index stops at the first value greater than LAST-SAMPLE.
      * A limit above three also exercises the unmapped sample branch.
      * This loop does not use a table or a file as its input source.
      * The PERFORM body completes once for each accepted index.
      * VARYING advances the index after the body completes.
      * The next UNTIL test sees the incremented index.
      * For last sample three, indexes one, two, and three are included.
      * Index four satisfies > three and ends this sample loop.
      * With last index zero, the initial test is already true.
      * In that case the loop body is skipped and the count stays zero.
      * Last index one processes one item, then stops at two.
      * A last sample above three reaches WHEN OTHER for extra indexes.
      * This example exposes that boundary instead of hiding extra work.
      * END-PERFORM closes the inline loop's statement scope.
      * END-EVALUATE closes the sample selection inside each iteration.
      * Each displayed sample is selected from its current loop index.
      * The count uses COMPUTE syntax introduced in the prior lessons.
      * No period occurs inside the loop to end PERFORM early.
      * The final STOP RUN period closes the sentence after the loop.
      * EVALUATE keeps sample details together by index.
      * A later lesson stores these records as repeated table entries.
      * A later lesson moves this work into a named paragraph.
      * Production batches also validate records and handle errors.
      * This example uses a small known limit and fixed values.
      * Transactions are shown in input order; no sorting is performed.
      * The loop is sequential and single-threaded.
      * No balance is posted and no transaction is changed.
      * The code and amount text are labels, not arithmetic operands.
      * The sample count is separate from the configured last index.
      * This distinction lets output report completed iterations.
      * The initial value of the processed count is zero.
      * The counter changes only after a sample branch executes.
      * If the body does not run, the initial zero remains unchanged.
      * The compiler checks the loop control and branch structure.
      * Run the boundary exercise to verify the observed counts.
      * Restore the last sample to three for the default example.
      * STOP RUN ends this fixed sequence demonstration.
           STOP RUN.
