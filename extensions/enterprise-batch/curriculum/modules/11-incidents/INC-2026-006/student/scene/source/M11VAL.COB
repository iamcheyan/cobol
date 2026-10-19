       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKVAL.
      *JOB002: 受信したTRANSACTION v1フィードの長さと業
      * 務規則を検証。
      *構造エラー（長さ不正または
      *
      * キー項目が非数値）はRC8で全実行を中止。
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TX-IN ASSIGN TO DYNAMIC IN-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS IN-STAT.
           SELECT ACC-OUT ASSIGN TO DYNAMIC ACC-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS ACC-STAT.
           SELECT REJ-OUT ASSIGN TO DYNAMIC REJ-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS REJ-STAT.
           SELECT CTL-OUT ASSIGN TO DYNAMIC CTL-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS CTL-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD TX-IN.
       01 IN-LINE PIC X(400).
       FD ACC-OUT.
       01 ACC-LINE PIC X(55).
       FD REJ-OUT.
       01 REJ-LINE PIC X(66).
       FD CTL-OUT.
       01 CTL-LINE PIC X(200).
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 ACC-PATH PIC X(4096).
       01 REJ-PATH PIC X(4096).
       01 CTL-PATH PIC X(4096).
       01 IN-STAT PIC XX.
       01 ACC-STAT PIC XX.
       01 REJ-STAT PIC XX.
       01 CTL-STAT PIC XX.
       01 WS-DATE PIC X(8).
       01 WS-REC PIC X(400).
       01 WS-LEN PIC 9(4) COMP.
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-STRUCT PIC X VALUE 'N'.
       01 WS-REASON PIC X(10).
       01 RECV-COUNT PIC 9(9) COMP.
       01 ACC-COUNT PIC 9(9) COMP.
       01 REJ-COUNT PIC 9(9) COMP.
       01 REJ-BADDIR PIC 9(9) COMP.
       01 REJ-BADSTATUS PIC 9(9) COMP.
       01 REJ-BADDATE PIC 9(9) COMP.
       01 REJ-BADZERO PIC 9(9) COMP.
       01 WS-NUM PIC 9(6).
       01 WS-NUMX PIC X(6).
       01 WS-PTR PIC 9(4) COMP.
       01 WS-REJ-REC.
          05 WS-REJ-DATA PIC X(55).
          05 FILLER PIC X.
          05 WS-REJ-CODE PIC X(10).
       PROCEDURE DIVISION.
           ACCEPT IN-PATH FROM ENVIRONMENT 'BANKVAL_IN'
           ACCEPT ACC-PATH FROM ENVIRONMENT 'BANKVAL_ACCEPTED'
           ACCEPT REJ-PATH FROM ENVIRONMENT 'BANKVAL_REJECTED'
           ACCEPT CTL-PATH FROM ENVIRONMENT 'BANKVAL_CONTROL'
           ACCEPT WS-DATE FROM ENVIRONMENT 'BANKVAL_DATE'
           IF IN-PATH = SPACES OR ACC-PATH = SPACES OR
              REJ-PATH = SPACES OR CTL-PATH = SPACES OR
              WS-DATE = SPACES
               DISPLAY 'BANKVAL: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT TX-IN
           IF IN-STAT NOT = '00'
               DISPLAY 'BANKVAL: cannot open input ' IN-STAT
                 UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT ACC-OUT
           OPEN OUTPUT REJ-OUT
           OPEN OUTPUT CTL-OUT
           IF ACC-STAT NOT = '00' OR REJ-STAT NOT = '00' OR
              CTL-STAT NOT = '00'
               DISPLAY 'BANKVAL: cannot open output' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           PERFORM UNTIL WS-EOF = 'Y' OR WS-STRUCT = 'Y'
               READ TX-IN
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE IN-LINE TO WS-REC
                       ADD 1 TO RECV-COUNT
                       PERFORM 2000-PROCESS
               END-READ
           END-PERFORM
           IF WS-STRUCT = 'N'
               PERFORM 3000-CONTROL
           END-IF
           CLOSE TX-IN ACC-OUT REJ-OUT CTL-OUT
           IF WS-STRUCT = 'Y'
               DISPLAY 'BANKVAL: structural error, batch failed'
                 UPON STDERR
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           DISPLAY 'BANKVAL received=' RECV-COUNT
                   ' accepted=' ACC-COUNT
                   ' rejected=' REJ-COUNT
           IF REJ-COUNT > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           GOBACK.
       2000-PROCESS.
           COMPUTE WS-LEN =
               FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
           MOVE 'N' TO WS-REASON
           IF WS-LEN NOT = 55
               DISPLAY 'BANKVAL: record length ' WS-LEN
                       ' is not 55' UPON STDERR
               MOVE 'Y' TO WS-STRUCT
               EXIT PARAGRAPH
           END-IF
           IF WS-REC(1:10) IS NOT NUMERIC OR
              WS-REC(27:8) IS NOT NUMERIC OR
              WS-REC(35:6) IS NOT NUMERIC OR
              WS-REC(42:13) IS NOT NUMERIC
               DISPLAY 'BANKVAL: non-numeric key/amount' UPON STDERR
               MOVE 'Y' TO WS-STRUCT
               EXIT PARAGRAPH
           END-IF
           IF WS-REC(11:16) = SPACES
               DISPLAY 'BANKVAL: blank transaction id' UPON STDERR
               MOVE 'Y' TO WS-STRUCT
               EXIT PARAGRAPH
           END-IF
           IF WS-REC(41:1) NOT = 'C' AND WS-REC(41:1) NOT = 'D'
               MOVE 'BADDIR' TO WS-REASON
           ELSE
               IF WS-REC(55:1) NOT = 'N'
                   MOVE 'BADSTATUS' TO WS-REASON
               ELSE
                   IF WS-REC(27:8) NOT = WS-DATE
                       MOVE 'BADDATE' TO WS-REASON
                   ELSE
                       IF WS-REC(42:13) = '0000000000000'
                           MOVE 'BADZERO' TO WS-REASON
                       END-IF
                   END-IF
               END-IF
           END-IF
           IF WS-REASON = 'N'
               MOVE WS-REC(1:55) TO ACC-LINE
               WRITE ACC-LINE
               ADD 1 TO ACC-COUNT
           ELSE
               MOVE WS-REC(1:55) TO WS-REJ-DATA
               MOVE WS-REASON TO WS-REJ-CODE
               MOVE WS-REJ-REC TO REJ-LINE
               WRITE REJ-LINE
               ADD 1 TO REJ-COUNT
               EVALUATE WS-REASON
                   WHEN 'BADDIR'
                       ADD 1 TO REJ-BADDIR
                   WHEN 'BADSTATUS'
                       ADD 1 TO REJ-BADSTATUS
                   WHEN 'BADDATE'
                       ADD 1 TO REJ-BADDATE
                   WHEN 'BADZERO'
                       ADD 1 TO REJ-BADZERO
                   WHEN OTHER
                       CONTINUE
               END-EVALUATE
           END-IF
           .
       3000-CONTROL.
           MOVE SPACES TO CTL-LINE
           MOVE 1 TO WS-PTR
           STRING 'CONTROL|RECEIVED=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE RECV-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           STRING '|ACCEPTED=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE ACC-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           STRING '|REJECTED=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE REJ-COUNT TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           WRITE CTL-LINE
           MOVE SPACES TO CTL-LINE
           MOVE 1 TO WS-PTR
           STRING 'REJ|BADDIR=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE REJ-BADDIR TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           STRING '|BADSTATUS=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE REJ-BADSTATUS TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           STRING '|BADDATE=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE REJ-BADDATE TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           STRING '|BADZERO=' DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           MOVE REJ-BADZERO TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO CTL-LINE WITH POINTER WS-PTR
           WRITE CTL-LINE
           .
