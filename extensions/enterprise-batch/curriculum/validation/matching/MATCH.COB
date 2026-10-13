       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEQUENTIAL-MATCH.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MASTER-FILE ASSIGN TO 'master.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS M-STATUS.
           SELECT TX-FILE ASSIGN TO 'transaction.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS T-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD MASTER-FILE
           RECORD IS VARYING FROM 1 TO 4096
           DEPENDING ON M-LENGTH.
       01 M-LINE PIC X(4096).
       FD TX-FILE
           RECORD IS VARYING FROM 1 TO 4096
           DEPENDING ON T-LENGTH.
       01 T-LINE PIC X(4096).
       WORKING-STORAGE SECTION.
       01 M-LENGTH BINARY-LONG.
       01 T-LENGTH BINARY-LONG.
       01 M-STATUS PIC XX.
       01 T-STATUS PIC XX.
       01 M-EOF PIC 9 VALUE 0.
       01 T-EOF PIC 9 VALUE 0.
       01 M-PREV PIC X(3) VALUE LOW-VALUES.
       01 T-PREV PIC X(3) VALUE LOW-VALUES.
       PROCEDURE DIVISION.
       1000-MAIN.
           OPEN INPUT MASTER-FILE
           IF M-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           OPEN INPUT TX-FILE
           IF T-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           PERFORM 2000-READ-MASTER
           PERFORM 3000-READ-TX
           PERFORM UNTIL M-EOF = 1 AND T-EOF = 1
               EVALUATE TRUE
                   WHEN M-EOF = 1
                       PERFORM 5000-TX-ONLY
                   WHEN T-EOF = 1
                       PERFORM 4000-MASTER-ONLY
                   WHEN M-LINE(1:3) = T-LINE(1:3)
                       DISPLAY 'MATCH|' M-LINE(1:3) '|'
                           M-LINE(4:4) '|' T-LINE(4:4)
                       PERFORM 2000-READ-MASTER
                       PERFORM 3000-READ-TX
                   WHEN M-LINE(1:3) < T-LINE(1:3)
                       PERFORM 4000-MASTER-ONLY
                   WHEN OTHER
                       PERFORM 5000-TX-ONLY
               END-EVALUATE
           END-PERFORM
           CLOSE MASTER-FILE TX-FILE
           IF M-STATUS NOT = '00' OR T-STATUS NOT = '00'
               PERFORM 9100-SYSTEM-FAIL
           END-IF
           MOVE 0 TO RETURN-CODE
           GOBACK.
       2000-READ-MASTER.
           READ MASTER-FILE
           EVALUATE M-STATUS
               WHEN '10'
                   MOVE 1 TO M-EOF
               WHEN '00'
                   IF M-LENGTH NOT = 7
                       DISPLAY 'MASTER:LENGTH' UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   IF M-LINE(1:7) IS NOT NUMERIC
                       DISPLAY 'MASTER:NUMERIC' UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   IF M-LINE(1:3) NOT > M-PREV
                       DISPLAY 'MASTER:ORDER-OR-DUPLICATE'
                           UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   MOVE M-LINE(1:3) TO M-PREV
               WHEN '04'
                   PERFORM 9000-DATA-FAIL
               WHEN OTHER
                   PERFORM 9100-SYSTEM-FAIL
           END-EVALUATE.
       3000-READ-TX.
           READ TX-FILE
           EVALUATE T-STATUS
               WHEN '10'
                   MOVE 1 TO T-EOF
               WHEN '00'
                   IF T-LENGTH NOT = 7
                       DISPLAY 'TX:LENGTH' UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   IF T-LINE(1:7) IS NOT NUMERIC
                       DISPLAY 'TX:NUMERIC' UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   IF T-LINE(1:3) NOT > T-PREV
                       DISPLAY 'TX:ORDER-OR-DUPLICATE'
                           UPON STDERR
                       PERFORM 9000-DATA-FAIL
                   END-IF
                   MOVE T-LINE(1:3) TO T-PREV
               WHEN '04'
                   PERFORM 9000-DATA-FAIL
               WHEN OTHER
                   PERFORM 9100-SYSTEM-FAIL
           END-EVALUATE.
       4000-MASTER-ONLY.
           DISPLAY 'MASTER-ONLY|' M-LINE(1:3) '|' M-LINE(4:4)
           PERFORM 2000-READ-MASTER.
       5000-TX-ONLY.
           DISPLAY 'TX-ONLY|' T-LINE(1:3) '|' T-LINE(4:4)
           PERFORM 3000-READ-TX.
       9000-DATA-FAIL.
           MOVE 8 TO RETURN-CODE
           STOP RUN.
       9100-SYSTEM-FAIL.
           DISPLAY 'FILE-STATUS=' M-STATUS '/' T-STATUS
               UPON STDERR
           MOVE 12 TO RETURN-CODE
           STOP RUN.
