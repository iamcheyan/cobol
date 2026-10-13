      * Lesson 21: sort an unsorted account file with procedures.
      * The input procedure RELEASEs records to the sort work file.
      * The output procedure RETURNs rows in ascending key order.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORT21.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT UNSORTED-INPUT
               ASSIGN TO "accounts-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD UNSORTED-INPUT.
       01 FD-INPUT-RECORD PIC X(27).
       SD SORT-WORK.
       01 SD-SORT-RECORD.
          05 SD-ACCOUNT-NUMBER PIC X(10).
          05 SD-CUSTOMER-ID PIC X(8).
          05 SD-ACCOUNT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-OUTPUT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * SORT controls the input, sort, and output stages.
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER
               INPUT PROCEDURE 1000-LOAD-INPUT
               OUTPUT PROCEDURE 2000-RETURN-SORTED.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " OUTPUT=" WS-OUTPUT-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read input rows and release each valid record to SORT.
       1000-LOAD-INPUT.
           OPEN INPUT UNSORTED-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE UNSORTED-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=INPUT FAILED STATUS="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * Load one row; AT END ends only the input procedure loop.
       1100-READ-AND-RELEASE.
           READ UNSORTED-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       MOVE FD-INPUT-RECORD TO SD-SORT-RECORD
                       RELEASE SD-SORT-RECORD
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-INPUT-COUNT
                       ELSE
                           DISPLAY "RELEASE=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Return sorted rows until SORT reports its output EOF.
       2000-RETURN-SORTED.
           PERFORM UNTIL WS-SORT-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               RETURN SORT-WORK
                   AT END
                       MOVE "Y" TO WS-SORT-EOF
                   NOT AT END
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-OUTPUT-COUNT
                           DISPLAY "SORTED ACCOUNT="
                               SD-ACCOUNT-NUMBER
                               " CUSTOMER=" SD-CUSTOMER-ID
                               " BALANCE=" SD-ACCOUNT-BALANCE
                       ELSE
                           DISPLAY "RETURN=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
               END-RETURN
           END-PERFORM.
      * The input file is intentionally not in key order.
      * Its record width is 27 characters, matching Lesson 17.
      * Account number occupies positions 1 through 10.
      * Customer id occupies positions 11 through 18.
      * Balance occupies positions 19 through 27.
      * The sort work record uses the same field layout.
      * SORT-WORK is described with SD, not FD.
      * SORT owns the work file; the program does not OPEN it.
      * The input procedure is run as part of SORT's input stage.
      * RELEASE adds the current SD record to the sort work file.
      * The input procedure reads until the source file reaches EOF.
      * FILE STATUS distinguishes EOF from other input failures.
      * The source file is closed before the sort output procedure.
      * The sort stage orders records by the declared key.
      * The account key is fixed-width text with leading zeroes.
      * No duplicate keys occur in this fixture.
      * The output procedure is run after sorting is complete.
      * RETURN retrieves one sorted row at a time.
      * RETURN AT END terminates the output procedure loop.
      * The output procedure displays rows in ascending key order.
      * Input and output counts should be equal after successful SORT.
      * Empty input produces zero RELEASE and zero RETURN records.
      * The input count increments only after successful RELEASE.
      * The output count increments only after successful RETURN.
      * A source OPEN, READ, or CLOSE error sets the failure flag.
      * A nonzero SORT-RETURN reports RELEASE, RETURN, or SORT failure.
      * The process returns status 1 after a detected I/O failure.
      * This program displays sorted rows and creates no output file.
      * The sort work area can exceed a small in-memory table.
      * GnuCOBOL may use temporary storage for large sorts.
      * The fixture uses printable characters and one physical row.
      * Each row has no delimiter between its three fixed-width fields.
      * The line ending is not part of the 27-character FD record.
      * Run from this directory so ASSIGN finds the input fixture.
      * Sorting does not validate account or customer identifiers.
      * Sorting does not change the input file's original order.
      * The program does not depend on input key order.
      * The sort result is ascending by account number only.
      * A later batch can feed this ordered stream into file matching.
      * Lesson 20 consumes ordered account keys for sequential matching.
      * The input procedure must terminate like a performed procedure.
      * The output procedure must terminate after its final RETURN.
      * SORT invokes both named procedures in their respective stages.
      * RELEASE is legal in the SORT input procedure.
      * RETURN is legal in the SORT output procedure.
      * SORT-RETURN is checked after each sort-work operation.
      * The final summary makes dropped or duplicated rows visible.
      * All counters are three-digit fields for this small exercise.
      * The expected input contains four distinct account keys.
      * Their output sequence is independent of their input sequence.
      * STOP RUN returns the final RETURN-CODE to the shell.
