      * Lesson 19: read a master file and a daily transaction file.
      * Each input owns its own file status, EOF flag, and count.
      * The two streams may contain different numbers of records.
      * This lesson reads text records; it does not match account keys.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTI19.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-INPUT
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-INPUT.
       01 FD-ACCOUNT-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-ACCOUNT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Both inputs must open before the batch reads either stream.
       0000-MAIN.
           OPEN INPUT ACCOUNT-INPUT
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT TRANSACTION-INPUT
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-INPUT
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-ACCOUNT-EOF = "N"
                   PERFORM 1000-READ-ACCOUNT
               END-IF
               IF WS-TRANSACTION-EOF = "N"
                   AND WS-IO-ERROR = "N"
                   PERFORM 2000-READ-TRANSACTION
               END-IF
           END-PERFORM
           CLOSE ACCOUNT-INPUT
           CLOSE TRANSACTION-INPUT
           IF WS-ACCOUNT-STATUS = "00"
               AND WS-TRANSACTION-STATUS = "00"
               DISPLAY "CLOSE=OK ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TRANSACTIONS=" WS-TRANSACTION-COUNT
           ELSE
               DISPLAY "CLOSE=FAILED ACCOUNT=" WS-ACCOUNT-STATUS
                   " TRANSACTION=" WS-TRANSACTION-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read only while the account stream has not reached EOF.
       1000-READ-ACCOUNT.
           READ ACCOUNT-INPUT
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   IF WS-ACCOUNT-STATUS = "00"
                       ADD 1 TO WS-ACCOUNT-COUNT
                       DISPLAY "ACCOUNT="
                           FUNCTION TRIM(
                               FD-ACCOUNT-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Read only while the transaction stream has not reached EOF.
       2000-READ-TRANSACTION.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   IF WS-TRANSACTION-STATUS = "00"
                       ADD 1 TO WS-TRANSACTION-COUNT
                       DISPLAY "TRANSACTION="
                           FUNCTION TRIM(
                               FD-TRANSACTION-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * OPEN INPUT assigns a separate status to each file.
      * The first input must open before the second is attempted.
      * If the second OPEN fails, the first file is closed.
      * No READ occurs until both required inputs have opened.
      * Each FD describes a text line up to 100 characters.
      * Each SELECT uses LINE SEQUENTIAL organization.
      * Each physical line becomes one logical input record.
      * A short line is padded in its FD record area.
      * TRIM omits that right-side padding from the display.
      * The program does not split or validate the displayed fields.
      * The master and transaction records have different layouts.
      * Their layouts are visible in the two fixture files.
      * One loop pass attempts at most one read per active stream.
      * The account file may reach EOF before the transaction file.
      * The transaction file may reach EOF before the account file.
      * An EOF flag belongs only to the file that reached status 10.
      * A successful READ increments only that file's record count.
      * The EOF attempt does not increment either record count.
      * A file at EOF is skipped on every later loop pass.
      * Processing ends when both EOF flags are set.
      * The loop also stops after a non-EOF read error.
      * AT END handles status 10 for its own READ statement.
      * NOT AT END handles a successful READ with status 00.
      * Other nonzero statuses are reported as input errors.
      * An I/O error is different from normal end of file.
      * Both files are closed after normal completion or read error.
      * A close error is reported independently of the read counts.
      * The return code is nonzero for open, read, or close failures.
      * An empty file reaches its own EOF on the first READ attempt.
      * One empty file does not suppress reads from the other file.
      * The fixture contains three account master records.
      * The fixture contains four daily transaction records.
      * The files deliberately have different record counts.
      * The displayed output alternates while both files are active.
      * After account EOF, transaction records continue to be read.
      * After transaction EOF, account records continue to be read.
      * No account-to-transaction matching is done in this lesson.
      * The following lesson will match records by a sorted key.
      * Production jobs should log file names and batch identifiers.
      * This example keeps output short for classroom inspection.
      * File status is checked after each READ and each CLOSE.
      * The file status begins with 00 after a successful OPEN.
      * File status 10 denotes normal sequential end of file.
      * OPEN failure prevents the batch from entering the read loop.
      * STOP RUN returns the accumulated RETURN-CODE to the shell.
      * Run from the lesson directory to locate both fixtures.
      * Copy both inputs beside the executable for isolated testing.
      * No output file is created or modified by this program.
      * Lesson 19 introduces independent sequential input streams.
      * Lesson 20 will build on these files for ordered matching.
      * An EOF flag is never shared between the two input files.
      * Record counts are displayed as three-digit numeric fields.
      * The sample files contain fewer than one thousand records.
      * End-of-file is a normal input state, not an I/O failure.
      * The account stream retains its current position independently.
      * The transaction stream has its own current position.
      * Each successful READ advances only the selected file.
      * A failed second OPEN releases the already opened first file.
      * Empty-input behavior is part of the exercise scenarios.
      * The fixtures use printable ASCII characters for readability.
      * Parsing and account matching are out of scope here.
      * The summary confirms the number read from each input file.
      * Close both files before printing the final summary.
      * The line-sequential runtime handles physical line endings.
      * No newline bytes are copied into the COBOL record fields.
      * This demonstration uses two inputs; the same pattern extends.
      * For more inputs, give every file its own status and EOF state.
      * Do not stop all streams when only one reaches end of file.
      * A complete batch must define a policy for every input failure.
      * This lesson uses immediate stop after the first READ error.
      * The program never reopens or rewinds either input stream.
      * Sequential READ consumes records in their original file order.
      * Both input files are required and are not OPTIONAL.
      * These records are read-only and remain unchanged.
