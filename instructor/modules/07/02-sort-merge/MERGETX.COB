       IDENTIFICATION DIVISION.
       PROGRAM-ID. MERGETX.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RAW-IN ASSIGN TO DYNAMIC RAW-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS RAW-STATUS.
           SELECT FEED-A ASSIGN TO DYNAMIC PATH-A
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT FEED-B ASSIGN TO DYNAMIC PATH-B
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT MERGE-WORK ASSIGN TO SORT-WORK.
           SELECT TX-OUT ASSIGN TO DYNAMIC OUTPUT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS STATUS-OUT.
       DATA DIVISION.
       FILE SECTION.
       FD RAW-IN RECORD CONTAINS 1 CHARACTERS.
       01 RAW-BYTE PIC X.
       FD FEED-A.
       01 FEED-A-RECORD PIC X(55).
       FD FEED-B.
       01 FEED-B-RECORD PIC X(55).
       SD MERGE-WORK.
       COPY "TRANSACTION-V1.CPY".
       FD TX-OUT.
       01 TX-OUT-RECORD PIC X(55).
       WORKING-STORAGE SECTION.
       01 PATH-A PIC X(4096).
       01 PATH-B PIC X(4096).
       01 RAW-PATH PIC X(4096).
       01 OUTPUT-PATH PIC X(4096).
       01 RAW-STATUS PIC XX.
       01 STATUS-OUT PIC XX.
       01 BUSINESS-DATE PIC 9(8).
       01 CHECK-DATE PIC 9(8).
       01 CHECK-RECORD PIC X(55).
       01 CHECK-KEY PIC X(32).
       01 PREVIOUS-KEY PIC X(32).
       01 HAVE-PREVIOUS PIC X.
       01 BAD-RECORD PIC X.
       01 RAW-POSITION PIC 99 COMP-5.
       01 ID-POSITION PIC 99 COMP-5.
       01 END-INPUT PIC X.
       01 END-MERGE PIC X VALUE "N".
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           ACCEPT PATH-A FROM ENVIRONMENT "B02_INPUT_A"
           ACCEPT PATH-B FROM ENVIRONMENT "B02_INPUT_B"
           ACCEPT OUTPUT-PATH FROM ENVIRONMENT "B02_OUTPUT"
           ACCEPT BUSINESS-DATE FROM ENVIRONMENT "B02_DATE"
           MOVE PATH-A TO RAW-PATH
           PERFORM VALIDATE-SOURCE
           IF RETURN-CODE = 0
               MOVE PATH-B TO RAW-PATH
               PERFORM VALIDATE-SOURCE
           END-IF
           IF RETURN-CODE NOT = 0 GOBACK END-IF
           OPEN OUTPUT TX-OUT
           IF STATUS-OUT NOT = "00"
               DISPLAY "MERGE OUTPUT OPEN STATUS=" STATUS-OUT
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           MERGE MERGE-WORK ON ASCENDING KEY
               TX-ACCOUNT-ID
               TRANSACTION-SEQUENCE
               TRANSACTION-ID
               USING FEED-A FEED-B
               OUTPUT PROCEDURE WRITE-MERGED
           IF SORT-RETURN NOT = 0
               DISPLAY "MERGE SORT-RETURN=" SORT-RETURN
               MOVE 12 TO RETURN-CODE
           END-IF
           CLOSE TX-OUT
           IF STATUS-OUT NOT = "00"
               DISPLAY "MERGE OUTPUT CLOSE STATUS=" STATUS-OUT
               MOVE 12 TO RETURN-CODE
           END-IF
           GOBACK.
       VALIDATE-SOURCE.
           MOVE "N" TO HAVE-PREVIOUS
           MOVE "N" TO BAD-RECORD
           MOVE "N" TO END-INPUT
           MOVE 1 TO RAW-POSITION
           OPEN INPUT RAW-IN
           IF RAW-STATUS NOT = "00"
               DISPLAY "MERGE INPUT OPEN STATUS=" RAW-STATUS
               MOVE 12 TO RETURN-CODE
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL END-INPUT = "Y" OR BAD-RECORD = "Y"
               READ RAW-IN
                   AT END MOVE "Y" TO END-INPUT
               END-READ
               IF RAW-STATUS = "00"
                   IF RAW-BYTE = X"0A"
                       IF RAW-POSITION = 56
                           PERFORM CHECK-FIELDS
                           PERFORM CHECK-ORDER
                           MOVE 1 TO RAW-POSITION
                       ELSE
                           MOVE "Y" TO BAD-RECORD
                       END-IF
                   ELSE
                       IF RAW-POSITION > 55 OR
                          FUNCTION ORD(RAW-BYTE) < 33 OR
                          FUNCTION ORD(RAW-BYTE) > 127
                           MOVE "Y" TO BAD-RECORD
                       ELSE
                           MOVE RAW-BYTE TO
                               CHECK-RECORD(RAW-POSITION:1)
                           ADD 1 TO RAW-POSITION
                       END-IF
                   END-IF
               ELSE
                   IF RAW-STATUS = "10"
                       MOVE "Y" TO END-INPUT
                   ELSE
                       DISPLAY "MERGE INPUT READ STATUS=" RAW-STATUS
                       MOVE 12 TO RETURN-CODE
                       MOVE "Y" TO END-INPUT
                   END-IF
               END-IF
           END-PERFORM
           IF RAW-POSITION NOT = 1 MOVE "Y" TO BAD-RECORD END-IF
           CLOSE RAW-IN
           IF RAW-STATUS NOT = "00" AND RETURN-CODE = 0
               DISPLAY "MERGE INPUT CLOSE STATUS=" RAW-STATUS
               MOVE 12 TO RETURN-CODE
           END-IF
           IF BAD-RECORD = "Y" AND RETURN-CODE = 0
               DISPLAY "MERGE INPUT CONTRACT ERROR"
               MOVE 8 TO RETURN-CODE
           END-IF.
       CHECK-FIELDS.
           IF CHECK-RECORD(1:10) IS NOT NUMERIC OR
              CHECK-RECORD(27:8) IS NOT NUMERIC OR
              CHECK-RECORD(35:6) IS NOT NUMERIC OR
              CHECK-RECORD(41:1) NOT = "C" AND NOT = "D" OR
              CHECK-RECORD(42:13) IS NOT NUMERIC OR
              CHECK-RECORD(55:1) NOT = "N"
               MOVE "Y" TO BAD-RECORD
           END-IF
           PERFORM VARYING ID-POSITION FROM 11 BY 1
               UNTIL ID-POSITION > 26
               IF (CHECK-RECORD(ID-POSITION:1) < "A" OR
                   CHECK-RECORD(ID-POSITION:1) > "Z") AND
                  (CHECK-RECORD(ID-POSITION:1) < "0" OR
                   CHECK-RECORD(ID-POSITION:1) > "9")
                   MOVE "Y" TO BAD-RECORD
               END-IF
           END-PERFORM
           MOVE CHECK-RECORD(27:8) TO CHECK-DATE
           IF CHECK-DATE NOT = BUSINESS-DATE OR
              FUNCTION TEST-DATE-YYYYMMDD(CHECK-DATE) NOT = 0
               MOVE "Y" TO BAD-RECORD
           END-IF.
       CHECK-ORDER.
           MOVE CHECK-RECORD(1:10) TO CHECK-KEY(1:10)
           MOVE CHECK-RECORD(35:6) TO CHECK-KEY(11:6)
           MOVE CHECK-RECORD(11:16) TO CHECK-KEY(17:16)
           IF HAVE-PREVIOUS = "Y" AND CHECK-KEY <= PREVIOUS-KEY
               MOVE "Y" TO BAD-RECORD
           END-IF
           MOVE CHECK-KEY TO PREVIOUS-KEY
           MOVE "Y" TO HAVE-PREVIOUS.
       WRITE-MERGED.
           PERFORM UNTIL END-MERGE = "Y"
               RETURN MERGE-WORK
                   AT END MOVE "Y" TO END-MERGE
                   NOT AT END
                       MOVE TRANSACTION-RECORD TO TX-OUT-RECORD
                       WRITE TX-OUT-RECORD
                       IF STATUS-OUT NOT = "00"
                           DISPLAY "MERGE WRITE STATUS=" STATUS-OUT
                           MOVE 12 TO RETURN-CODE
                           MOVE "Y" TO END-MERGE
                       END-IF
               END-RETURN
           END-PERFORM.
