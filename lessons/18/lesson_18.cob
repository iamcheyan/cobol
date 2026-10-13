      * Lesson 18: validate and parse one-line CSV customer records.
      * The five fields are ID, name, account, status, and note.
      * Quoted commas and doubled quotes are parsed as field content.
      * Empty fields are preserved; fields longer than 20 are rejected.
      * Each CSV record occupies one physical line in this profile.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CSV18.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-CSV
               ASSIGN TO "customers.csv"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD CUSTOMER-CSV.
       01 FD-CSV-RECORD PIC X(200).
       WORKING-STORAGE SECTION.
       01 WS-FIELDS.
          05 WS-FIELD-VALUE OCCURS 5 TIMES PIC X(20).
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IN-QUOTES PIC X VALUE "N".
       01 WS-AFTER-QUOTE PIC X VALUE "N".
       01 WS-FIELD-START PIC X VALUE "Y".
       01 WS-COMMA PIC X VALUE X"2C".
       01 WS-QUOTE PIC X VALUE X"22".
       01 WS-CURRENT-CHAR PIC X VALUE SPACE.
       01 WS-CSV-ERROR PIC X(20) VALUE SPACES.
       01 WS-ROW-COUNT PIC 9(2) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(2) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-LINE-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-CHAR-POSITION PIC 9(3) VALUE ZERO.
       01 WS-NEXT-POSITION PIC 9(3) VALUE ZERO.
       01 WS-FIELD-NUMBER PIC 9(3) VALUE ZERO.
       01 WS-FIELD-LENGTH PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Read and validate all physical CSV lines in file order.
       0000-MAIN.
           OPEN INPUT CUSTOMER-CSV
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               READ CUSTOMER-CSV
                   AT END
                       MOVE "Y" TO WS-END-OF-FILE
                   NOT AT END
                       ADD 1 TO WS-ROW-COUNT
                       PERFORM 1000-PARSE-ROW
               END-READ
           END-PERFORM
           CLOSE CUSTOMER-CSV
           DISPLAY "SUMMARY ROWS=" WS-ROW-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECTED-COUNT
           STOP RUN.
      * Reset parser state before each independent input row.
       1000-PARSE-ROW.
           INITIALIZE WS-FIELDS
           MOVE SPACES TO WS-CSV-ERROR
           MOVE 1 TO WS-FIELD-NUMBER
           MOVE ZERO TO WS-FIELD-LENGTH
           MOVE "Y" TO WS-FIELD-START
           MOVE "N" TO WS-IN-QUOTES
           MOVE "N" TO WS-AFTER-QUOTE
           COMPUTE WS-LINE-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(
                   FD-CSV-RECORD TRAILING))
           PERFORM VARYING WS-CHAR-POSITION FROM 1 BY 1
               UNTIL WS-CHAR-POSITION > WS-LINE-LENGTH
               MOVE FD-CSV-RECORD(WS-CHAR-POSITION:1)
                   TO WS-CURRENT-CHAR
               PERFORM 2000-PARSE-CHARACTER
           END-PERFORM
           IF WS-IN-QUOTES = "Y"
               PERFORM 2900-SET-UNCLOSED-QUOTE
           END-IF
           IF WS-FIELD-START = "Y" AND WS-FIELD-NUMBER > 1
               PERFORM 2920-SET-TRAILING-COMMA
           END-IF
           IF WS-FIELD-NUMBER NOT = 5
               PERFORM 2910-SET-FIELD-COUNT-ERROR
           END-IF
           PERFORM 3000-REPORT-ROW.
      * Apply quote and comma rules to the current character.
       2000-PARSE-CHARACTER.
           IF WS-IN-QUOTES = "Y"
               IF WS-CURRENT-CHAR = WS-QUOTE
                   PERFORM 2100-HANDLE-QUOTE-IN-FIELD
               ELSE
                   PERFORM 4000-APPEND-CHARACTER
               END-IF
           ELSE
               PERFORM 2200-HANDLE-UNQUOTED-CHAR
           END-IF.
      * A doubled quote contributes one quote to a quoted value.
       2100-HANDLE-QUOTE-IN-FIELD.
           IF WS-CHAR-POSITION < WS-LINE-LENGTH
               COMPUTE WS-NEXT-POSITION = WS-CHAR-POSITION + 1
               IF FD-CSV-RECORD(WS-NEXT-POSITION:1) = WS-QUOTE
                   PERFORM 4000-APPEND-CHARACTER
                   ADD 1 TO WS-CHAR-POSITION
               ELSE
                   MOVE "N" TO WS-IN-QUOTES
                   MOVE "Y" TO WS-AFTER-QUOTE
               END-IF
           ELSE
               MOVE "N" TO WS-IN-QUOTES
               MOVE "Y" TO WS-AFTER-QUOTE
           END-IF.
      * Outside quotes, commas end fields and quotes start fields.
       2200-HANDLE-UNQUOTED-CHAR.
           IF WS-AFTER-QUOTE = "Y"
               IF WS-CURRENT-CHAR = WS-COMMA
                   PERFORM 2300-START-NEXT-FIELD
               ELSE
                   IF WS-CSV-ERROR = SPACES
                       MOVE "TEXT_AFTER_QUOTE" TO WS-CSV-ERROR
                   END-IF
               END-IF
           ELSE
               EVALUATE WS-CURRENT-CHAR
                   WHEN WS-COMMA
                       PERFORM 2300-START-NEXT-FIELD
                   WHEN WS-QUOTE
                       IF WS-FIELD-START = "Y"
                           MOVE "Y" TO WS-IN-QUOTES
                           MOVE "N" TO WS-FIELD-START
                       ELSE
                           IF WS-CSV-ERROR = SPACES
                               MOVE "QUOTE_IN_UNQUOTED"
                                   TO WS-CSV-ERROR
                           END-IF
                           MOVE "N" TO WS-FIELD-START
                       END-IF
                   WHEN OTHER
                       PERFORM 4000-APPEND-CHARACTER
                       MOVE "N" TO WS-FIELD-START
               END-EVALUATE
           END-IF.
      * A delimiter begins a new field, including an empty field.
       2300-START-NEXT-FIELD.
           ADD 1 TO WS-FIELD-NUMBER
           MOVE ZERO TO WS-FIELD-LENGTH
           MOVE "Y" TO WS-FIELD-START
           MOVE "N" TO WS-AFTER-QUOTE
           IF WS-FIELD-NUMBER > 5
               IF WS-CSV-ERROR = SPACES
                   MOVE "TOO_MANY_FIELDS" TO WS-CSV-ERROR
               END-IF
           END-IF.
      * Preserve valid parsed fields and reject oversized values.
       4000-APPEND-CHARACTER.
           ADD 1 TO WS-FIELD-LENGTH
           IF WS-FIELD-NUMBER <= 5
               IF WS-FIELD-LENGTH <= 20
                   MOVE WS-CURRENT-CHAR TO
                       WS-FIELD-VALUE(WS-FIELD-NUMBER)(
                           WS-FIELD-LENGTH:1)
               ELSE
                   IF WS-CSV-ERROR = SPACES
                       MOVE "FIELD_TOO_LONG" TO WS-CSV-ERROR
                   END-IF
               END-IF
           ELSE
               IF WS-CSV-ERROR = SPACES
                   MOVE "TOO_MANY_FIELDS" TO WS-CSV-ERROR
               END-IF
           END-IF.
      * Keep the first detected parser error for this input row.
       2900-SET-UNCLOSED-QUOTE.
           IF WS-CSV-ERROR = SPACES
               MOVE "UNCLOSED_QUOTE" TO WS-CSV-ERROR
           END-IF.
       2910-SET-FIELD-COUNT-ERROR.
           IF WS-CSV-ERROR = SPACES
               MOVE "FIELD_COUNT" TO WS-CSV-ERROR
           END-IF.
       2920-SET-TRAILING-COMMA.
           IF WS-CSV-ERROR = SPACES
               MOVE "TRAILING_COMMA" TO WS-CSV-ERROR
           END-IF.
      * Display parsed values only when structure and sizes are valid.
       3000-REPORT-ROW.
           IF WS-CSV-ERROR = SPACES
               ADD 1 TO WS-VALID-COUNT
               DISPLAY "ROW=" WS-ROW-COUNT " STATUS=OK"
                   " ID=" FUNCTION TRIM(
                       WS-FIELD-VALUE(1) TRAILING)
                   " NAME=[" FUNCTION TRIM(
                       WS-FIELD-VALUE(2) TRAILING) "]"
                   " ACCOUNT=" FUNCTION TRIM(
                       WS-FIELD-VALUE(3) TRAILING)
                   " STATE=" FUNCTION TRIM(
                       WS-FIELD-VALUE(4) TRAILING)
                   " NOTE=[" FUNCTION TRIM(
                       WS-FIELD-VALUE(5) TRAILING) "]"
           ELSE
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "ROW=" WS-ROW-COUNT
                   " STATUS=REJECTED REASON="
                   FUNCTION TRIM(WS-CSV-ERROR TRAILING)
           END-IF.
      * CSV commas inside quoted fields are data, not delimiters.
      * A doubled quote inside a quoted field represents one quote.
      * An empty unquoted or quoted field has a length of zero.
      * A trailing comma is rejected by this CSV profile.
      * The schema requires exactly five fields in every valid row.
      * An extra delimiter produces TOO_MANY_FIELDS without overflow.
      * A short row produces FIELD_COUNT after the final field scan.
      * A quote may only open a field at its first character.
      * Non-delimiter text after a closing quote is rejected.
      * An unmatched opening quote produces UNCLOSED_QUOTE.
      * The first parser error is retained as the row's reject reason.
      * Each field stores at most 20 characters.
      * Longer values are rejected rather than silently truncated.
      * The input line area holds at most 200 characters.
      * Longer line-sequential records may be truncated by the runtime.
      * This profile does not support newlines inside quoted fields.
      * Spaces before a closing quote remain part of the field value.
      * Quote final fields when their trailing spaces are significant.
      * Unquoted trailing spaces are indistinguishable from FD padding.
      * TRIM removes FD padding when measuring and displaying a row.
      * The fixture has valid, empty, malformed, and boundary examples.
      * A physical input line is one CSV record for this lesson.
      * OPEN failure is reported before any record is read.
      * EOF is not counted as a CSV row.
      * This program reads CSV but does not change or write the input.
      * Later lessons will coordinate multiple file streams.
      * STOP RUN ends the one-line CSV parsing exercise.
