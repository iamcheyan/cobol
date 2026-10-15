      * Parse five-field CSV one physical line at a time.
      * Quoted commas are data; doubled quotes encode one quote.
      * Limits: 20 characters per field, 200 per row.
      * Multiline quoted fields are unsupported.
      * Reject malformed rows with the first detected reason.
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
