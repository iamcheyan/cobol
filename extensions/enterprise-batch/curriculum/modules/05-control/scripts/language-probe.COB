       IDENTIFICATION DIVISION.
       PROGRAM-ID. M05-LANGUAGE-PROBE.
      *> 05.2 実験：UNSTRING で順不同の対応表を読む。
      *> raw=canonical、INSPECT で名前を正規化。
      *> SEARCH で状態検索、INITIALIZE で出力初期化、
      *> STRING でレポート行を組み立てる。
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MAP-FILE ASSIGN TO DYNAMIC MAP-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS MAP-STAT.
           SELECT NAME-FILE ASSIGN TO DYNAMIC NAME-PATH
               ORGANIZATION IS LINE SEQUENTIAL FILE STATUS IS NAME-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD MAP-FILE.
       01 MAP-LINE PIC X(80).
       FD NAME-FILE.
       01 NAME-LINE PIC X(80).
       WORKING-STORAGE SECTION.
       01 MAP-PATH PIC X(4096).
       01 NAME-PATH PIC X(4096).
       01 MAP-STAT PIC XX.
       01 NAME-STAT PIC XX.
       01 MAP-DONE PIC 9.
       01 NAME-DONE PIC 9.
       01 MAP-COUNT PIC 99 VALUE 0.
       01 IN-ID PIC X(8).
       01 IN-NAME PIC X(10).
       01 IN-STATUS PIC X(8).
       01 CANON PIC X(8).
       01 LINE-BUF PIC X(120).
       01 PTR BINARY-LONG.
       01 OUT-REC.
          05 OUT-ID PIC X(8).
          05 OUT-NAME PIC X(10).
          05 OUT-STATUS PIC X(8).
       01 STATUS-MAP.
          05 MAP-ENTRY OCCURS 20 TIMES INDEXED BY MAP-IX.
             10 MAP-RAW PIC X(8).
             10 MAP-CANON PIC X(8).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT MAP-PATH FROM ENVIRONMENT 'MAP_FILE'
           ACCEPT NAME-PATH FROM ENVIRONMENT 'NAME_FILE'
           MOVE SPACES TO STATUS-MAP
           OPEN INPUT MAP-FILE
           IF MAP-STAT NOT = '00' MOVE 12 TO RETURN-CODE GOBACK END-IF
           MOVE 0 TO MAP-DONE
           PERFORM UNTIL MAP-DONE = 1
             READ MAP-FILE
             IF MAP-STAT = '10'
               MOVE 1 TO MAP-DONE
             ELSE
               IF MAP-STAT NOT = '00'
                 MOVE 12 TO RETURN-CODE GOBACK
               END-IF
               ADD 1 TO MAP-COUNT
               UNSTRING MAP-LINE DELIMITED BY '='
                 INTO MAP-RAW(MAP-COUNT) MAP-CANON(MAP-COUNT)
               END-UNSTRING
             END-IF
           END-PERFORM
           CLOSE MAP-FILE
           OPEN INPUT NAME-FILE
           IF NAME-STAT NOT = '00' MOVE 12 TO RETURN-CODE GOBACK END-IF
           MOVE 0 TO NAME-DONE
           PERFORM UNTIL NAME-DONE = 1
             READ NAME-FILE
             IF NAME-STAT = '10'
               MOVE 1 TO NAME-DONE
             ELSE
               IF NAME-STAT NOT = '00'
                 MOVE 12 TO RETURN-CODE GOBACK
               END-IF
               UNSTRING NAME-LINE DELIMITED BY ','
                 INTO IN-ID IN-NAME IN-STATUS
               END-UNSTRING
               INSPECT IN-NAME REPLACING ALL '_' BY SPACE
               SET MAP-IX TO 1
               SEARCH MAP-ENTRY
                 AT END MOVE 'UNMAPPED' TO CANON
                 WHEN MAP-RAW(MAP-IX) = IN-STATUS
                   MOVE MAP-CANON(MAP-IX) TO CANON
               END-SEARCH
               INITIALIZE OUT-REC
               MOVE IN-ID TO OUT-ID
               MOVE IN-NAME TO OUT-NAME
               MOVE CANON TO OUT-STATUS
               MOVE SPACES TO LINE-BUF
               MOVE 1 TO PTR
               STRING 'NORM|' DELIMITED BY SIZE
                      OUT-ID DELIMITED BY SIZE
                      '|' DELIMITED BY SIZE
                      FUNCTION TRIM(OUT-NAME) DELIMITED BY SIZE
                      '|' DELIMITED BY SIZE
                      FUNCTION TRIM(OUT-STATUS) DELIMITED BY SIZE
                 INTO LINE-BUF WITH POINTER PTR
               END-STRING
               DISPLAY FUNCTION TRIM(LINE-BUF)
             END-IF
           END-PERFORM
           CLOSE NAME-FILE
           MOVE 0 TO RETURN-CODE
           GOBACK.
