       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORTTX.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TX-IN ASSIGN TO DYNAMIC INPUT-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS INPUT-STATUS.
           SELECT TX-WORK ASSIGN TO SORT-WORK.
           SELECT TX-OUT ASSIGN TO DYNAMIC OUTPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS OUTPUT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TX-IN RECORD CONTAINS 1 CHARACTERS.
       01 TX-IN-BYTE PIC X.
       SD TX-WORK.
       COPY "TRANSACTION-V1.CPY".
       FD TX-OUT.
       01 TX-OUT-RECORD PIC X(55).
       WORKING-STORAGE SECTION.
       01 INPUT-PATH PIC X(4096).
       01 OUTPUT-PATH PIC X(4096).
       01 INPUT-STATUS PIC XX.
       01 RECORD-POSITION PIC 99 COMP-5.
       01 INPUT-EOF PIC X VALUE "N".
       01 CHECK-RECORD PIC X(55).
       01 CHECK-DATE PIC 9(8).
       01 ID-POSITION PIC 99 COMP-5.
       01 BUSINESS-DATE PIC X(8).
       01 INVALID-INPUT PIC X VALUE "N".
       01 OUTPUT-STATUS PIC XX.
       01 END-INPUT PIC X VALUE "N".
       01 END-SORT PIC X VALUE "N".
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           ACCEPT INPUT-PATH FROM ENVIRONMENT "B02_INPUT"
           ACCEPT OUTPUT-PATH FROM ENVIRONMENT "B02_OUTPUT"
           ACCEPT BUSINESS-DATE FROM ENVIRONMENT "B02_DATE"
           OPEN INPUT TX-IN
           IF INPUT-STATUS NOT = "00"
               DISPLAY "SORT INPUT OPEN STATUS=" INPUT-STATUS
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT TX-OUT
           IF OUTPUT-STATUS NOT = "00"
               DISPLAY "SORT OUTPUT OPEN STATUS=" OUTPUT-STATUS
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           SORT TX-WORK ON ASCENDING KEY
               TX-ACCOUNT-ID
               TRANSACTION-SEQUENCE
               TRANSACTION-ID
               INPUT PROCEDURE LOAD-INPUT
               OUTPUT PROCEDURE WRITE-OUTPUT
           IF SORT-RETURN NOT = 0
               DISPLAY "SORT-RETURN=" SORT-RETURN
               MOVE 12 TO RETURN-CODE
           END-IF
           CLOSE TX-IN TX-OUT
           IF INPUT-STATUS NOT = "00" OR OUTPUT-STATUS NOT = "00"
               DISPLAY "SORT CLOSE STATUS="
                   INPUT-STATUS "/" OUTPUT-STATUS
               MOVE 12 TO RETURN-CODE
           END-IF
           GOBACK.
       LOAD-INPUT.
           MOVE 1 TO RECORD-POSITION
           PERFORM UNTIL INPUT-EOF = "Y" OR INVALID-INPUT = "Y"
               READ TX-IN
                   AT END MOVE "Y" TO INPUT-EOF
               END-READ
               IF INPUT-STATUS = "00"
                   IF TX-IN-BYTE = X"0A"
                       IF RECORD-POSITION = 56
                           PERFORM CHECK-FIELDS
                           IF INVALID-INPUT = "N"
                               MOVE CHECK-RECORD TO TRANSACTION-RECORD
                               RELEASE TRANSACTION-RECORD
                           END-IF
                           MOVE 1 TO RECORD-POSITION
                       ELSE
                           MOVE "Y" TO INVALID-INPUT
                       END-IF
                   ELSE
                       IF RECORD-POSITION > 55 OR
                          FUNCTION ORD(TX-IN-BYTE) < 33 OR
                          FUNCTION ORD(TX-IN-BYTE) > 127
                           MOVE "Y" TO INVALID-INPUT
                       ELSE
                           MOVE TX-IN-BYTE TO
                               CHECK-RECORD(RECORD-POSITION:1)
                           ADD 1 TO RECORD-POSITION
                       END-IF
                   END-IF
               ELSE
                   IF INPUT-STATUS = "10"
                       MOVE "Y" TO INPUT-EOF
                   ELSE
                       DISPLAY "SORT READ STATUS=" INPUT-STATUS
                       MOVE 12 TO RETURN-CODE
                       MOVE "Y" TO INPUT-EOF
                   END-IF
               END-IF
           END-PERFORM
           IF RECORD-POSITION NOT = 1
               MOVE "Y" TO INVALID-INPUT
           END-IF
           IF INVALID-INPUT = "Y" AND RETURN-CODE NOT = 12
               DISPLAY "SORT INPUT CONTRACT ERROR"
               MOVE 8 TO RETURN-CODE
           END-IF.
       CHECK-FIELDS.
           IF CHECK-RECORD(1:10) IS NOT NUMERIC OR
              CHECK-RECORD(27:8) IS NOT NUMERIC OR
              CHECK-RECORD(35:6) IS NOT NUMERIC OR
              CHECK-RECORD(41:1) NOT = "C" AND NOT = "D" OR
              CHECK-RECORD(42:13) IS NOT NUMERIC OR
              CHECK-RECORD(55:1) NOT = "N"
               MOVE "Y" TO INVALID-INPUT
           END-IF
           PERFORM VARYING ID-POSITION FROM 11 BY 1
               UNTIL ID-POSITION > 26
               IF (CHECK-RECORD(ID-POSITION:1) < "A" OR
                   CHECK-RECORD(ID-POSITION:1) > "Z") AND
                  (CHECK-RECORD(ID-POSITION:1) < "0" OR
                   CHECK-RECORD(ID-POSITION:1) > "9")
                   MOVE "Y" TO INVALID-INPUT
               END-IF
           END-PERFORM
           MOVE CHECK-RECORD(27:8) TO CHECK-DATE
           IF CHECK-DATE NOT = BUSINESS-DATE OR
              FUNCTION TEST-DATE-YYYYMMDD(CHECK-DATE) NOT = 0
               MOVE "Y" TO INVALID-INPUT
           END-IF.
       WRITE-OUTPUT.
           PERFORM UNTIL END-SORT = "Y"
               RETURN TX-WORK
                   AT END MOVE "Y" TO END-SORT
                   NOT AT END
                       MOVE TRANSACTION-RECORD TO TX-OUT-RECORD
                       WRITE TX-OUT-RECORD
                       IF OUTPUT-STATUS NOT = "00"
                           DISPLAY "SORT WRITE STATUS=" OUTPUT-STATUS
                           MOVE 12 TO RETURN-CODE
                           MOVE "Y" TO END-SORT
                       END-IF
               END-RETURN
           END-PERFORM.
