       IDENTIFICATION DIVISION.
       PROGRAM-ID. M06-LINESEQ-PROBE.
      *> Lesson 06.2: the same 5-byte logical record written by LINE
      *> SEQUENTIAL and by a fixed byte stream. Reading the line file as
      *> raw bytes exposes the LF that LINE SEQUENTIAL hides.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT L-FILE ASSIGN TO DYNAMIC L-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS L-STAT.
           SELECT LR-FILE ASSIGN TO DYNAMIC L-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS LR-STAT.
           SELECT F-FILE ASSIGN TO DYNAMIC F-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS F-STAT.
           SELECT FR-FILE ASSIGN TO DYNAMIC F-PATH
               ORGANIZATION IS SEQUENTIAL FILE STATUS IS FR-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD L-FILE.
       01 L-REC PIC X(5).
       FD LR-FILE.
       01 LR-BYTE PIC X.
       FD F-FILE.
       01 F-REC PIC X(5).
       FD FR-FILE.
       01 FR-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 L-PATH PIC X(4096).
       01 F-PATH PIC X(4096).
       01 L-STAT PIC XX.
       01 LR-STAT PIC XX.
       01 F-STAT PIC XX.
       01 FR-STAT PIC XX.
       01 L-DONE PIC 9.
       01 LR-DONE PIC 9.
       01 F-DONE PIC 9.
       01 LR-COUNT PIC 99 VALUE 0.
       01 F-COUNT PIC 99 VALUE 0.
       01 LR-LF PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT L-PATH FROM ENVIRONMENT 'LINE_PATH'
           ACCEPT F-PATH FROM ENVIRONMENT 'FIXED_PATH'
           OPEN OUTPUT L-FILE
           IF L-STAT NOT = '00' MOVE 12 TO RETURN-CODE GOBACK END-IF
           MOVE 'HELLO' TO L-REC
           WRITE L-REC
           CLOSE L-FILE
           OPEN OUTPUT F-FILE
           IF F-STAT NOT = '00' MOVE 12 TO RETURN-CODE GOBACK END-IF
           MOVE 'HELLO' TO F-REC
           WRITE F-REC
           CLOSE F-FILE
           OPEN INPUT L-FILE
           READ L-FILE
           DISPLAY 'LINE-LOGICAL=' L-REC
           READ L-FILE
           DISPLAY 'LINE-NEXT=' L-STAT
           CLOSE L-FILE
           OPEN INPUT LR-FILE
           MOVE 0 TO LR-DONE
           PERFORM UNTIL LR-DONE = 1
             READ LR-FILE
             IF LR-STAT = '10'
               MOVE 1 TO LR-DONE
             ELSE
               IF LR-STAT NOT = '00'
                 MOVE 12 TO RETURN-CODE GOBACK
               END-IF
               ADD 1 TO LR-COUNT
               IF LR-BYTE = X'0A' MOVE 'Y' TO LR-LF END-IF
             END-IF
           END-PERFORM
           CLOSE LR-FILE
           DISPLAY 'LINE-RAW-BYTES=' LR-COUNT
           DISPLAY 'LINE-RAW-LF=' LR-LF
           OPEN INPUT FR-FILE
           MOVE 0 TO F-DONE
           PERFORM UNTIL F-DONE = 1
             READ FR-FILE
             IF FR-STAT = '10'
               MOVE 1 TO F-DONE
             ELSE
               IF FR-STAT NOT = '00'
                 MOVE 12 TO RETURN-CODE GOBACK
               END-IF
               ADD 1 TO F-COUNT
             END-IF
           END-PERFORM
           CLOSE FR-FILE
           DISPLAY 'FIXED-RAW-BYTES=' F-COUNT
           MOVE 0 TO RETURN-CODE
           GOBACK.
