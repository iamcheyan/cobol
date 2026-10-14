      * Lesson 15: read daily transaction text one line at a time.
      * LINE SEQUENTIAL stores one text record on each physical line.
      * READ retrieves the next record until the AT END clause runs.
      * Short lines are padded in the FD record area.
      * TRIM removes that padding only for the display operation.
      * This program reads records as text and does not parse fields.
      * Run here so ASSIGN finds the input fixture.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open failure is reported before any read is attempted.
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=YES RECORDS=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "CLOSE=OK"
           ELSE
               DISPLAY "CLOSE=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * READ obtains one physical line or signals end of file.
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   DISPLAY "RECORD="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
      * OPEN INPUT prepares an existing file for reading.
      * A successful OPEN reports file status 00.
      * A missing required file causes OPEN to return a nonzero status.
      * The program returns status 1 if its input cannot be opened.
      * The FD describes one line-sequential text record.
      * Line sequential records end at each physical newline.
      * The input records are shorter than the 100-character FD area.
      * GnuCOBOL pads shorter line-sequential records with spaces.
      * FUNCTION TRIM removes only right-side padding for display.
      * The stored file record itself remains unchanged by TRIM.
      * READ without a random key retrieves the next sequential record.
      * READ AT END signals that no next record is available.
      * The EOF branch sets a flag and does not increment the count.
      * The loop ends after the first READ that reaches end of file.
      * A final newline does not create an extra empty data record.
      * The record counter increases once for each successful READ.
      * The program displays the original text of each input record.
      * It does not split the pipe-delimited fields in this lesson.
      * File status after a successful READ is 00.
      * File status after end of file is 10 until the file is closed.
      * CLOSE returns status 00 when it succeeds.
      * The file must exist because this SELECT is not OPTIONAL.
      * The input path is relative to the current directory.
      * Start the program from the lesson directory to use its fixture.
      * This program performs no writes and changes no input data.
      * The next lesson will write accepted and rejected output records.
      * Lesson 18 will parse delimiter-separated fields.
      * The fixture contains four daily account transaction records.
      * Records differ in length to demonstrate line handling.
      * Each read uses the same FD record area.
      * Only READ AT END marks this input stream as complete.
      * A file read error is distinct from an ordinary end-of-file.
      * File status should be examined when diagnosing I/O failures.
      * Close the file after the read loop, even when it is empty.
      * The output count confirms all available records were visited.
      * The empty file would report EOF with a zero record count.
      * No table search or account balance update occurs in this lesson.
      * STOP RUN ends the sequential input demonstration.
      * The fixture uses pipe characters to separate visible fields.
      * In this lesson each entire line remains one character record.
      * Date and transaction identifiers are displayed without checks.
      * Transaction codes and amounts are not converted to COBOL fields.
      * A later lesson will parse fields from delimited columns.
      * Line sequential files use newline delimiters between records.
      * A text editor can create this input fixture directly.
      * Empty input reaches AT END on the first READ attempt.
      * A successful read increments the count exactly once.
      * The FD record width must accommodate the longest input line.
