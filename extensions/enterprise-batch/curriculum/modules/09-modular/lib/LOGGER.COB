       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOGGER.
      *    Shared append-only log module, interface LOGGER v1.
      *    Called BY CONTENT; keeps an in-process sequence counter.
      *    Returns 0 written, 8 interface error, 12 system error.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LOG-FILE ASSIGN TO DYNAMIC LOG-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS LOG-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD LOG-FILE.
       01 LOG-REC PIC X(67).
       WORKING-STORAGE SECTION.
       01 WS-EXPECTED-LENGTH PIC 9(4) COMP-5.
       01 LOG-PATH PIC X(4096).
       01 LOG-STAT PIC XX.
       01 WS-DATE PIC X(8).
       01 WS-SEQ PIC 9(6) VALUE 0.
       01 WS-LINE PIC X(67).
       LINKAGE SECTION.
           COPY "LOGGER-INTERFACE-V1.CPY".
       PROCEDURE DIVISION USING LOG-INTERFACE.
       0000-EMIT.
           MOVE 0 TO RETURN-CODE
           COMPUTE WS-EXPECTED-LENGTH = LENGTH OF LOG-INTERFACE
           IF LOG-IFACE-LENGTH NOT = WS-EXPECTED-LENGTH
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           IF LOG-IFACE-VERSION NOT = '001'
              MOVE 8 TO RETURN-CODE
              GOBACK
           END-IF
           ACCEPT LOG-PATH FROM ENVIRONMENT 'LOG_FILE'
           ACCEPT WS-DATE FROM ENVIRONMENT 'BATCH_DATE'
           ADD 1 TO WS-SEQ
           MOVE SPACES TO WS-LINE
           MOVE WS-DATE TO WS-LINE(1:8)
           MOVE '|' TO WS-LINE(9:1)
           MOVE WS-SEQ TO WS-LINE(10:6)
           MOVE '|' TO WS-LINE(16:1)
           MOVE LOG-SEVERITY TO WS-LINE(17:1)
           MOVE '|' TO WS-LINE(18:1)
           MOVE LOG-EVENT TO WS-LINE(19:8)
           MOVE '|' TO WS-LINE(27:1)
           MOVE LOG-MESSAGE TO WS-LINE(28:40)
           MOVE WS-LINE TO LOG-REC
           OPEN EXTEND LOG-FILE
           IF LOG-STAT = '35'
              OPEN OUTPUT LOG-FILE
           END-IF
           IF LOG-STAT NOT = '00'
              MOVE 12 TO RETURN-CODE
              GOBACK
           END-IF
           WRITE LOG-REC
           IF LOG-STAT NOT = '00'
              CLOSE LOG-FILE
              MOVE 12 TO RETURN-CODE
              GOBACK
           END-IF
           CLOSE LOG-FILE
           IF LOG-STAT NOT = '00'
              MOVE 12 TO RETURN-CODE
              GOBACK
           END-IF
           MOVE 0 TO RETURN-CODE
           GOBACK.
       END PROGRAM LOGGER.
