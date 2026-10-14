      * Lesson 17: read raw fixed records and write a fixed layout.
      * Sequential binary files have no line-ending record delimiters.
      * Each sample input record is exactly 27 display bytes.
      * Field positions are account 1-10, customer 11-18, balance 19-27.
      * Output positions are customer 1-8, account 9-18, balance 19-27.
      * Input and output fixtures are raw concatenated record bytes.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXED17.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "accounts.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT BALANCE-FILE
               ASSIGN TO "balances.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BALANCE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD BALANCE-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-BALANCE-RECORD.
          05 FD-OUT-CUSTOMER-ID PIC X(8).
          05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
          05 FD-OUT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-BALANCE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open the raw master file and create the fixed-width output file.
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "OPEN=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=INPUT OK OPEN=OUTPUT OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read one 27-byte record and write its reordered fields.
       1000-READ-AND-WRITE.
           READ ACCOUNT-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   PERFORM 1100-WRITE-BALANCE-RECORD
           END-READ.
      * Move named fields into the output record's declared positions.
       1100-WRITE-BALANCE-RECORD.
           MOVE FD-CUSTOMER-ID TO FD-OUT-CUSTOMER-ID
           MOVE FD-ACCOUNT-NUMBER TO FD-OUT-ACCOUNT-NUMBER
           MOVE FD-ACCOUNT-BALANCE TO FD-OUT-BALANCE
           WRITE FD-BALANCE-RECORD
           IF WS-BALANCE-STATUS = "00"
               ADD 1 TO WS-RECORD-COUNT
               DISPLAY "WROTE ACCOUNT=" FD-OUT-ACCOUNT-NUMBER
                   " CUSTOMER=" FD-OUT-CUSTOMER-ID
                   " BALANCE=" FD-OUT-BALANCE
           ELSE
               DISPLAY "WRITE=FAILED STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Close both files and report records successfully written.
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "CLOSE=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "CLOSE=OK RECORDS=" WS-RECORD-COUNT.
      * RECORD CONTAINS and the FD fields agree on 27 bytes.
      * DISPLAY fields use text bytes and implied decimal positions.
      * The V in PIC 9(7)V99 occupies no physical file byte.
      * Therefore the balance occupies nine display digit bytes.
      * The input fixture is three 27-byte records, with no delimiters.
      * The second record begins exactly at byte offset 28.
      * The output record begins with customer ID instead of account ID.
      * Its next ten bytes hold the account number.
      * The last nine bytes hold the same numeric balance.
      * ORGANIZATION SEQUENTIAL means raw fixed-record byte placement.
      * It is not the same physical format as LINE SEQUENTIAL text.
      * Do not insert newline characters between sequential records.
      * Text editors add line endings and corrupt this fixture.
      * Each successful READ supplies one FD record to the program.
      * READ AT END stops the loop without creating an output record.
      * Each successful WRITE adds exactly one 27-byte output record.
      * Output file size is record count multiplied by 27 bytes.
      * File status 00 indicates successful open, read, write, or close.
      * The program preserves account order from the input file.
      * No sort, search, or arithmetic changes the account balances.
      * OPEN OUTPUT replaces any older balances.dat contents.
      * Paths are relative to the process current working directory.
      * Run in a temporary directory containing accounts.dat.
      * The sample uses ASCII display characters and numeric digits.
      * Binary COMP data would need a separately specified layout.
      * Input and output field order differs; total size remains equal.
      * Verify field offsets before exchanging a fixed-width data file.
      * A missing input file is reported before the output is opened.
      * A successful output close flushes the fixed records.
      * STOP RUN ends the fixed-record conversion example.
